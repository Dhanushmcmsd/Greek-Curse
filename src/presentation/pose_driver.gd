class_name PoseDriver
extends RefCounted
## Pure presentation: cached poses and rigid-skin bounds; never writes simulation.

var data: Dictionary
var rig: FighterRig
var moves: Dictionary = {}
var time: float = 0.0
var phase: String = "idle"
var preview_pose: String = ""
var floor_min: float = 0.0
var reach_mismatch_mm: int = 0
var caption: String = ""
var pack_map: Dictionary = {}
var walk_direction: int = 0
var current_action_name: String = ""
var current_clip_id: String = ""
var _rest: Array[Quaternion] = []
var _bounds: Array = []
var _skin_vertices: Dictionary = {}
var _socket_rest: Dictionary = {}
var _cape: Node3D
var _last_creak: int = -1
var _cape_angle: float = 0.0
var _cape_rest := Transform3D.IDENTITY
var _last_states: Dictionary = {}
var _twitch: Dictionary = {}
var _beam: MeshInstance3D


func setup(target: FighterRig) -> void:
	rig = target
	_beam = MeshInstance3D.new()
	_beam.mesh = BoxMesh.new()
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("9fddff")
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam.material_override = glow
	_beam.top_level = true
	rig.add_child(_beam)
	_beam.hide()
	data = DataLoader.new().load_json("res://data/animation/poses.json").value
	var pm_res = DataLoader.new().load_json("res://data/animation/mixamo_pack_map.json")
	if not pm_res.ok:
		pm_res = DataLoader.new().load_json("res://data/animation/pack_map.json")
	if pm_res.ok and pm_res.value is Dictionary:
		pack_map = pm_res.value
	for file in DirAccess.get_files_at("res://data/moves"):
		if file.ends_with(".json"):
			var row: Dictionary = DataLoader.new().load_json("res://data/moves/" + file).value
			moves[row["id"]] = row
	for index in rig.skeleton.get_bone_count():
		_rest.append(rig.skeleton.get_bone_pose_rotation(index))
	for slot in SimLimbs.LIMB_NAMES:
		_socket_rest[slot] = rig.sockets[slot].transform
		_twitch[slot] = 0
	for mesh in rig.model.find_children("*", "MeshInstance3D", true, false):
		var bone := "spine"
		var name := str(mesh.name)
		if (
			name.begins_with("HEAD")
			or name.begins_with("HELM")
			or name.begins_with("CREST")
			or name.begins_with("WREATH")
			or name.begins_with("BRAID")
			or name.begins_with("VEIL")
			or name.begins_with("EYE")
			or name.begins_with("NOSE")
			or name.begins_with("BEARD")
		):
			bone = "head"
		for slot in SimLimbs.LIMB_NAMES:
			var prefix: String = "ARM" if slot.begins_with("arm") else "LEG"
			var joints: Array = (
				["upper_arm", "forearm", "hand"] if prefix == "ARM" else ["thigh", "shin", "foot"]
			)
			for part in 3:
				if (
					name
					== (
						prefix
						+ "_"
						+ ["UPPER", "LOWER", "END"][part]
						+ "_"
						+ slot.right(1).to_upper()
					)
				):
					bone = joints[part] + "." + slot.right(1)
			var is_limb_meta: bool = (
				mesh.has_meta("limb_group")
				and str(mesh.get_meta("limb_group")) == "LIMB_" + slot.to_upper()
			)
			if name.ends_with("_" + slot.to_upper()) or is_limb_meta:
				bone = ("foot." if prefix == "LEG" else "hand.") + slot.right(1)
		var target_bone_idx := rig.skeleton.find_bone(bone)
		if target_bone_idx == -1:
			target_bone_idx = rig.skeleton.find_bone("spine")
		if target_bone_idx == -1:
			target_bone_idx = 0
		var vertices := PackedVector3Array()
		for surface in mesh.mesh.get_surface_count():
			vertices.append_array(mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
		_bounds.append([mesh, target_bone_idx, vertices])
	_cape = rig.model.find_child("CAPE", true, false) as Node3D
	if _cape != null:
		_cape_rest = _cape.transform


static func attack_phase(tick: int, startup: int, active: int) -> String:
	if tick < startup:
		return "startup"
	if tick < startup + active:
		return "active"
	return "recovery"


func update(fighter: SimFighter, stopped: bool = false) -> void:
	var settings: Dictionary = data["settings"]
	caption = ""
	if not stopped:
		time += 1.0 / 60.0
	rig.sync(fighter)
	rig.rotation = Vector3(0, deg_to_rad(float(settings["facing_degrees"])) * fighter.facing, 0)
	rig.position = Vector3.ZERO
	var pose_name := _select(fighter)
	phase = pose_name
	var clip_active := _drive_clip(fighter, stopped)
	if not clip_active:
		rig.anim_player.stop()
		var style: Dictionary = data["styles"].get(fighter.fighter_id, data["styles"]["theron"])
		var rotations: Dictionary = (
			style["idle"] if pose_name == "idle" else data["poses"][pose_name]["bones"]
		)
		var other: Dictionary = rotations
		var blend := 0.0
		if pose_name.begins_with("walk_"):
			var cycle: float = time * 60.0 / float(style["cycle"]) * data["walk"].size()
			var key: int = int(cycle) % data["walk"].size()
			rotations = data["poses"][data["walk"][key]]["bones"]
			other = data["poses"][data["walk"][(key + 1) % data["walk"].size()]]["bones"]
			blend = fposmod(cycle, 1.0)
		for index in rig.skeleton.get_bone_count():
			var bone := rig.skeleton.get_bone_name(index)
			var source := bone
			if fighter.attack_slot.ends_with("r") and fighter.move_id > 0:
				source = bone.replace(".r", ".TEMP").replace(".l", ".r").replace(".TEMP", ".l")
			var a: Array = rotations.get(source, [0, 0, 0])
			var b: Array = other.get(source, a)
			var angles := Vector3(float(a[0]), float(a[1]), float(a[2])).lerp(
				Vector3(float(b[0]), float(b[1]), float(b[2])), blend
			)
			if fighter.state == SimFighter.State.WALK:
				angles *= float(style["stride"])
			if fighter.state == SimFighter.State.HITSTUN:
				angles *= float(style["recoil"])
			if bone == "spine" and fighter.move_id > 0:
				angles.y = (
					float(style["twist"])
					* (-1.0 if fighter.state == SimFighter.State.STARTUP else 1.0)
				)
			if bone == "spine" and fighter.move_id == 0:
				angles.x += (
					sin(time * float(settings["breath_rate"])) * float(settings["breath_degrees"])
				)
			if (
				fighter.pose == "crawl"
				and fighter.state == SimFighter.State.WALK
				and bone.begins_with("upper_arm")
			):
				angles.x += (
					sin(time * float(settings["quirk_rate"]) + (PI if bone.ends_with("r") else 0.0))
					* float(settings["crawl_swing_degrees"])
				)
			var slot := _slot_for(bone)
			if slot != "":
				var limb: SimLimb = fighter.limbs.parts[slot]
				if limb.state == "severed":
					angles = Vector3.ZERO
				elif limb.state == "cracked":
					angles = Vector3(float(settings["cracked_degrees"]), 0, 0)
				elif fighter.state == SimFighter.State.IDLE:
					if limb.regrown_id == "cyclops_giant_hand":
						angles.x += (
							float(settings["wave_base_degrees"])
							+ (
								sin(time * float(settings["quirk_rate"]))
								* float(settings["wave_degrees"])
							)
						)
					elif limb.regrown_id == "marble_statue_leg":
						angles.x += float(settings["marble_pose_degrees"])
						var period := int(time * 60.0) / int(settings["creak_interval_ticks"])
						if period != _last_creak:
							caption = "STONE CREAK"
							_last_creak = period
			var target := _rest[index] * Quaternion.from_euler(angles * PI / 180.0)
			var smooth := 1.0 if fighter.state == SimFighter.State.ACTIVE else 0.45
			if preview_pose != "" or stopped:
				smooth = 1.0
			rig.skeleton.set_bone_pose_rotation(
				index, rig.skeleton.get_bone_pose_rotation(index).slerp(target, smooth)
			)
	if clip_active:
		if stopped:
			rig.anim_player.seek(rig.anim_player.current_animation_position, true)
		for slot in SimLimbs.LIMB_NAMES:
			if fighter.limbs.parts[slot].state == "cracked":
				var bone := rig.skeleton.find_bone(
					("upper_arm." if slot.begins_with("arm") else "thigh.") + slot.right(1)
				)
				if bone >= 0:
					rig.skeleton.set_bone_pose_rotation(
						bone,
						rig.skeleton.get_bone_pose_rotation(bone) * Quaternion(Vector3.RIGHT, 0.3)
					)
	_root_pose(fighter, settings, clip_active)
	_attachments(fighter, stopped)
	_ground(fighter, settings)
	_projectile(fighter)
	if _cape != null and not stopped:
		_cape_angle = lerpf(
			_cape_angle,
			sin(time * float(settings["quirk_rate"])) * float(settings["quirk_angle"]),
			float(settings["cape_spring"])
		)
		var pivot := Vector3(
			0,
			rig.fighter_height * float(settings["cape_pivot_height_percent"]) / 100.0,
			float(settings["cape_pivot_z_m"])
		)
		var turn := Basis(Vector3.RIGHT, _cape_angle)
		_cape.transform = Transform3D(turn, pivot - turn * pivot) * _cape_rest
	if stopped:
		rig.position.x += sin(time * 60.0) * float(settings["hitstop_shake_m"])


func _select(fighter: SimFighter) -> String:
	if preview_pose != "":
		return preview_pose
	if (
		fighter.move_id > 0
		and (
			fighter.state
			in [SimFighter.State.STARTUP, SimFighter.State.ACTIVE, SimFighter.State.RECOVERY]
		)
	):
		var set_id: String = moves.get(fighter.move_name, {}).get("anim_set", "punch_light")
		var key := attack_phase(fighter.state_tick, fighter.startup_ticks, fighter.active_ticks)
		return data["sets"][set_id][key]
	var selected := "idle"
	match fighter.state:
		SimFighter.State.KO:
			selected = "knockdown"
		SimFighter.State.HITSTUN:
			selected = (
				"hit_heavy"
				if fighter.state_tick > int(data["settings"]["reaction_split_ticks"])
				else "hit_light"
			)
		SimFighter.State.STAGGER:
			selected = "stagger"
		SimFighter.State.DODGE:
			selected = "torso_roll" if fighter.pose == "torso" else "dodge_roll"
		SimFighter.State.GRAB:
			selected = (
				"grab_hold"
				if fighter.state_tick > int(data["settings"]["throw_split_ticks"])
				else "grab_throw"
			)
		SimFighter.State.GRABBED:
			selected = "hit_heavy"
		_:
			if fighter.blocking or fighter.state == SimFighter.State.BLOCKSTUN:
				selected = "block"
			elif fighter.pose in ["crawl", "torso", "hop"]:
				selected = "torso_scuttle" if fighter.pose == "torso" else fighter.pose
			elif fighter.state == SimFighter.State.WALK:
				selected = "walk_a"
	return selected


func _root_pose(fighter: SimFighter, settings: Dictionary, clip_active: bool = false) -> void:
	if not clip_active:
		if fighter.pose == "crawl":
			rig.rotation.x = deg_to_rad(float(settings["crawl_pitch_degrees"]))
		elif fighter.pose == "torso":
			rig.rotation.x = deg_to_rad(float(settings["torso_pitch_degrees"]))
			if fighter.state == SimFighter.State.WALK:
				rig.rotation.x += deg_to_rad(
					(
						sin(time * float(settings["quirk_rate"]))
						* float(settings["torso_sway_degrees"])
					)
				)
			if fighter.move_name == "body_roll":
				rig.rotation.x += (
					deg_to_rad(float(settings["roll_degrees"]))
					* float(fighter.state_tick)
					/ maxf(
						1.0,
						float(fighter.startup_ticks + fighter.active_ticks + fighter.recovery_ticks)
					)
				)
		if fighter.state == SimFighter.State.KO:
			rig.rotation.x = deg_to_rad(float(settings["knockdown_degrees"]))
		elif fighter.state == SimFighter.State.DODGE:
			rig.rotation.x += (
				deg_to_rad(float(settings["dodge_pitch_degrees"]))
				* float(fighter.state_tick)
				/ float(settings["dodge_ticks"])
			)
		elif fighter.state == SimFighter.State.WALK and fighter.pose == "standing":
			rig.rotation.x += deg_to_rad(float(settings["walk_lean_degrees"]))
	if (
		fighter.pose in ["crawl", "torso"]
		or (not clip_active and (fighter.state in [SimFighter.State.KO, SimFighter.State.DODGE]))
	):
		var pivot := Vector3(
			0, rig.fighter_height * float(settings["ground_pivot_height_percent"]) / 100.0, 0
		)
		rig.position.x = -(rig.basis * pivot).x


func _attachments(fighter: SimFighter, stopped: bool) -> void:
	for slot in SimLimbs.LIMB_NAMES:
		var bone := rig.skeleton.find_bone(
			("upper_arm." if slot.begins_with("arm") else "thigh.") + slot.right(1)
		)
		if bone >= 0:
			var deform := (
				rig.skeleton.get_bone_global_pose(bone)
				* rig.skeleton.get_bone_global_rest(bone).affine_inverse()
			)
			rig.sockets[slot].transform = deform * _socket_rest[slot]
		else:
			rig.sockets[slot].transform = _socket_rest[slot]
		var state: String = fighter.limbs.parts[slot].state
		if _last_states.get(slot, "healthy") != "severed" and state == "severed":
			_twitch[slot] = int(data["settings"]["stump_twitch_ticks"])
		_last_states[slot] = state
		if not stopped:
			_twitch[slot] = maxi(0, int(_twitch[slot]) - 1)
		for cap in rig.stump_meshes[slot]:
			cap.rotation.z = (
				(
					deg_to_rad(float(data["settings"]["stump_twitch_degrees"]))
					* sin(float(_twitch[slot]))
				)
				if _twitch[slot] > 0
				else 0.0
			)
		if rig.replacements.has(slot):
			rig.replacements[slot].rotation = Vector3.ZERO
			LimbQuirks.animate(
				rig.replacements[slot],
				time,
				fighter.state == SimFighter.State.ACTIVE,
				data["settings"]
			)


func _ground(fighter: SimFighter, settings: Dictionary) -> void:
	floor_min = INF
	var has_healthy_feet := (
		fighter.limbs.usable("leg_l")
		and fighter.limbs.usable("leg_r")
		and fighter.pose in ["standing", "hop", "walk_a"]
	)
	var spine_bone := rig.skeleton.find_bone("spine")
	for item in _bounds:
		var mesh: MeshInstance3D = item[0]
		if not mesh.is_visible_in_tree():
			continue
		var bone: int = item[1]
		# When standing with intact legs, floor grounding is defined by foot contact;
		# decorative torso/cloak mesh extensions should not pull grounding down below the feet.
		if has_healthy_feet and bone == spine_bone:
			continue
		if mesh.skin != null:
			floor_min = minf(floor_min, _skinned_floor(mesh))
			continue
		var deform := Transform3D.IDENTITY
		if bone >= 0:
			deform = (
				rig.skeleton.get_bone_global_pose(bone)
				* rig.skeleton.get_bone_global_rest(bone).affine_inverse()
			)
		var transform := Transform3D(rig.basis, Vector3.ZERO) * deform * mesh.transform
		for vertex in item[2]:
			floor_min = minf(floor_min, (transform * vertex).y)
	for replacement in rig.replacements.values():
		for mesh in replacement.find_children("*", "MeshInstance3D", true, false):
			if mesh.skin != null:
				floor_min = minf(floor_min, _skinned_floor(mesh))
				continue
			var relative: Transform3D = (
				rig.global_transform.affine_inverse() * mesh.global_transform
			)
			var box: AABB = Transform3D(rig.basis, Vector3.ZERO) * relative * mesh.get_aabb()
			floor_min = minf(floor_min, box.position.y)
	if is_finite(floor_min):
		rig.position.y = -floor_min
		floor_min += rig.position.y
	if fighter.pose == "hop" and fighter.state == SimFighter.State.WALK:
		rig.position.y += (
			abs(sin(time * float(settings["quirk_rate"]))) * float(settings["hop_height_m"])
		)
	if fighter.state == SimFighter.State.ACTIVE:
		if fighter.hit_w == 0:
			reach_mismatch_mm = 0
		else:
			var slot := fighter.attack_slot
			var tip_name := ("hand." if slot.begins_with("arm") else "foot.") + slot.right(1)
			if not fighter.limbs.parts.has(slot):
				tip_name = "head"
			var tip := rig.skeleton.find_bone(tip_name)
			var position := rig.transform * rig.skeleton.get_bone_global_pose(tip).origin
			reach_mismatch_mm = absi(
				int(abs(position.x) * 1000.0) - (fighter.hit_x + fighter.hit_w)
			)


func _skinned_floor(mesh: MeshInstance3D) -> float:
	# Use the same weighted skin deformation as the renderer. A whole leg is
	# not rigidly attached to its foot; that approximation caused vertical snaps.
	var key := mesh.mesh.get_instance_id()
	if not _skin_vertices.has(key):
		var surfaces: Array = []
		for surface in mesh.mesh.get_surface_count():
			surfaces.append(mesh.mesh.surface_get_arrays(surface))
		_skin_vertices[key] = surfaces
	var poses: Array[Transform3D] = []
	for bind in mesh.skin.get_bind_count():
		var bone := rig.skeleton.find_bone(mesh.skin.get_bind_name(bind))
		if bone < 0:
			bone = mesh.skin.get_bind_bone(bind)
		poses.append(rig.skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind))
	var relative := rig.global_transform.affine_inverse() * rig.skeleton.global_transform
	var transform := Transform3D(rig.basis, Vector3.ZERO) * relative
	var minimum := INF
	for arrays in _skin_vertices[key]:
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var influences := joints.size() / maxi(1, vertices.size())
		for vertex in vertices.size():
			var deformed := Vector3.ZERO
			for influence in influences:
				var offset: int = vertex * influences + influence
				if weights[offset] > 0.0:
					deformed += (poses[joints[offset]] * vertices[vertex]) * weights[offset]
			minimum = minf(minimum, (transform * deformed).y)
	return minimum


static func _slot_for(bone: String) -> String:
	if bone.begins_with("upper_arm") or bone.begins_with("forearm") or bone.begins_with("hand"):
		return "arm_" + bone.right(1)
	if bone.begins_with("thigh") or bone.begins_with("shin") or bone.begins_with("foot"):
		return "leg_" + bone.right(1)
	return ""


func _projectile(fighter: SimFighter) -> void:
	_beam.visible = fighter.state == SimFighter.State.ACTIVE and fighter.hit_w > 2000
	if not _beam.visible:
		return
	var origin := rig.global_position - rig.position
	var length := float(fighter.hit_w) / 1000.0
	(_beam.mesh as BoxMesh).size = Vector3(length, 0.06, 0.06)
	_beam.global_position = (
		origin
		+ Vector3(
			(float(fighter.hit_x) / 1000.0 + length * .5) * fighter.facing,
			float(fighter.hit_y + fighter.hit_h / 2) / 1000.0,
			0
		)
	)
	var endpoint := _beam.global_position.x + length * .5 * fighter.facing
	reach_mismatch_mm = absi(
		int(absf(endpoint - origin.x) * 1000.0) - (fighter.hit_x + fighter.hit_w)
	)


func _drive_clip(fighter: SimFighter, stopped: bool) -> bool:
	if rig.anim_player == null or not pack_map.has("fighters"):
		return false
	if not pack_map["fighters"].has(fighter.fighter_id):
		return false
	if fighter.pose in ["crawl", "torso"] or preview_pose != "":
		return false

	var f_map: Dictionary = pack_map["fighters"][fighter.fighter_id]
	var actions: Dictionary = f_map.get("actions", {})
	var act_key := ""
	var is_attack := false

	if (
		fighter.move_id > 0
		and (
			fighter.state
			in [SimFighter.State.STARTUP, SimFighter.State.ACTIVE, SimFighter.State.RECOVERY]
		)
	):
		is_attack = true
		act_key = _action_for_move(fighter.move_name, moves.get(fighter.move_name, {}))
	elif fighter.blocking or fighter.state == SimFighter.State.BLOCKSTUN:
		act_key = "block"
	elif fighter.state == SimFighter.State.WALK:
		var speed_val: int = fighter.walk_speed if "walk_speed" in fighter else 20
		if walk_direction != 0 and walk_direction != fighter.facing and actions.has("walk_back"):
			act_key = "walk_back"
		elif speed_val > 30 and actions.has("run"):
			act_key = "run"
		else:
			act_key = "walk_fwd"
	elif fighter.state == SimFighter.State.IDLE:
		act_key = "idle"
	elif fighter.state in [SimFighter.State.HITSTUN, SimFighter.State.STAGGER]:
		act_key = "stagger"
	elif fighter.state == SimFighter.State.KO:
		act_key = "knockdown"
	elif fighter.blocking or fighter.state == SimFighter.State.BLOCKSTUN:
		act_key = "block"
	elif fighter.state == SimFighter.State.DODGE:
		act_key = "dodge"
	elif fighter.state == SimFighter.State.GRAB:
		act_key = "grab"

	if act_key == "" or not actions.has(act_key):
		current_action_name = ""
		current_clip_id = ""
		return false

	var clip_name: String = fighter.fighter_id + "_" + act_key
	if not rig.anim_player.has_animation(clip_name):
		current_action_name = ""
		current_clip_id = ""
		return false

	current_action_name = act_key
	current_clip_id = str(actions[act_key].get("clip", ""))

	if is_attack:
		var total_ticks := maxi(
			1, fighter.startup_ticks + fighter.active_ticks + fighter.recovery_ticks
		)
		var startup_ratio := float(fighter.startup_ticks) / float(total_ticks)
		var current_ratio := float(fighter.state_tick) / float(total_ticks)
		var contact_phase := float(actions[act_key].get("contact_phase", 0.4))
		var warp_t := 0.0
		if current_ratio <= startup_ratio:
			warp_t = (current_ratio / maxf(0.001, startup_ratio)) * contact_phase
		else:
			var span := maxf(0.001, 1.0 - startup_ratio)
			warp_t = (
				contact_phase + ((current_ratio - startup_ratio) / span) * (1.0 - contact_phase)
			)
		var anim_len := rig.anim_player.get_animation(clip_name).length
		rig.anim_player.speed_scale = 1.0
		rig.anim_player.play(clip_name)
		rig.anim_player.seek(clampf(warp_t, 0.0, 1.0) * anim_len, true)
	elif act_key in ["walk_fwd", "walk_back", "run"]:
		if rig.anim_player.current_animation != clip_name:
			rig.anim_player.play(clip_name, 0.1)
		var configured_scale: float = float(actions[act_key].get("speed_scale", 1.0))
		rig.anim_player.speed_scale = (
			configured_scale * float(fighter.walk_speed if "walk_speed" in fighter else 20) / 20.0
		)
		if not stopped:
			rig.anim_player.advance(1.0 / 60.0)
	else:
		if rig.anim_player.current_animation != clip_name:
			rig.anim_player.play(clip_name, 0.1)
		rig.anim_player.speed_scale = float(actions[act_key].get("speed_scale", 1.0))
		if not stopped:
			rig.anim_player.advance(1.0 / 60.0)

	return true


static func _action_for_move(move_name: String, move_data: Dictionary) -> String:
	match move_name:
		"jab_of_hermes":
			return "punch_jab"
		"spartan_cross":
			return "punch_cross"
		"cyclops_smash":
			return "overhead_slam"
		"minotaur_haymaker":
			return "heavy_strike"
		"bronze_knuckle":
			return "hook"
		"gorgon_backfist":
			return "heavy_strike"
		"pegasus_kick":
			return "kick_thrust"
		"sweeping_hydra":
			return "kick_sweep"
		"satyr_dropkick":
			return "kick_stomp"
		"achilles_heel_snap":
			return "kick_low"
		"zeus_bolt":
			return "zeus_bolt"
		"hermes_dash":
			return "hermes_dash"
		"ares_rage":
			return "ares_rage"
		"hephaestus_forge_shield":
			return "forge_shield"
		"zeus_wrath":
			return "zeus_wrath"
		"olympian_barrage":
			return "olympian_barrage"
		"grab":
			return "grab"
		_:
			var cat: String = str(move_data.get("category", ""))
			if cat == "light":
				return "punch_jab"
			if cat == "heavy":
				return "overhead_slam"
			if cat == "kick":
				return "kick_thrust"
			if cat == "superpower":
				return "zeus_bolt"
			if cat == "ultimate":
				return "zeus_wrath"
			return "punch_jab"
