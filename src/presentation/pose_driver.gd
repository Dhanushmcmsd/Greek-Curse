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
## Reactive combat state
var last_hit_zone: String = ""
var last_attacker_move: String = ""
var last_hit_tick: int = -1
var block_impact_tick: int = 0
var sever_reaction_tick: int = 0
var sever_slowmo_tick: int = 0
var combo_count: int = 0
var combo_shake: float = 0.0
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
var _one_leg: OneLegMotion
var _beam: MeshInstance3D


func setup(target: FighterRig) -> void:
	rig = target
	_one_leg = OneLegMotion.new()
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
		if name.begins_with("WOUND_"):
			continue
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
			elif bone == "spine" and fighter.state == SimFighter.State.HITSTUN:
				# Light hits play flinch blend with torso twist
				angles.y += (
					14.0
					* (1.0 if last_hit_zone.ends_with("r") else -1.0)
					* exp(-float(fighter.state_tick) * 0.25)
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
		if (
			stopped
			and (
				fighter.state
				not in [
					SimFighter.State.STARTUP, SimFighter.State.ACTIVE, SimFighter.State.RECOVERY
				]
			)
		):
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
				if fighter.pose == "crawl" and slot.begins_with("leg"):
					var knee := rig.skeleton.find_bone("shin." + slot.right(1))
					if knee >= 0:
						rig.skeleton.set_bone_pose_rotation(
							knee,
							(
								rig.skeleton.get_bone_pose_rotation(knee)
								* Quaternion(Vector3.RIGHT, -1.3)
							)
						)
	# Visibility belongs to limb state, even if a legacy clip writes mesh properties.
	rig.sync(fighter)
	var one_leg := _one_leg.apply(rig, fighter, time)
	_root_pose(fighter, settings, clip_active)
	if one_leg.active:
		rig.rotation.x += float(one_leg.pitch)
	_attachments(fighter, stopped)
	_ground(fighter, settings)
	if one_leg.active:
		rig.position.y += float(one_leg.lift)
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
	tick_reactive(stopped)
	if stopped:
		var shake_amount := float(settings["hitstop_shake_m"]) + combo_shake
		rig.position.x += sin(time * 60.0) * shake_amount
		rig.position.z += cos(time * 45.0) * shake_amount * 0.5


func _select(fighter: SimFighter) -> String:
	if preview_pose != "":
		return preview_pose
	# Sever reaction overrides everything for dramatic effect
	if sever_reaction_tick > 0:
		return "sever_reaction"
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
			if fighter.state_tick > 20:
				selected = "idle"
			else:
				selected = "knockdown"
		SimFighter.State.HITSTUN:
			# Dynamic Reactions:
			# - Heavy hits (e.g. thunder_elbow_strike): Trigger reaction_gut_crumple or wall bounce
			# - Light hits: Flinch blend with torso twist
			if (
				last_attacker_move == "thunder_elbow_strike"
				or last_attacker_move == "phantom_ambush"
			):
				if (
					moves.get(last_attacker_move, {}).get("wall_bounce", false)
					and (fighter.x <= -3800 or fighter.x >= 3800 or absi(fighter.x) > 3600)
				):
					selected = "reaction_wall_splat_bounce"
				else:
					selected = "reaction_gut_crumple"
			elif last_hit_zone == "head":
				selected = "hit_head_snap"
			elif last_hit_zone == "torso":
				selected = "hit_gut" if fighter.state_tick < 8 else "reaction_gut_crumple"
			elif fighter.state_tick > int(data["settings"]["reaction_split_ticks"]):
				selected = "hit_heavy"
			else:
				selected = "hit_light"
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
				# Block impact animation that transitions back to block
				if block_impact_tick > 0:
					selected = "block_impact"
				else:
					selected = "block"
			elif fighter.pose in ["crawl", "torso", "hop"]:
				selected = "torso_scuttle" if fighter.pose == "torso" else fighter.pose
			elif fighter.state == SimFighter.State.WALK:
				selected = "walk_a"
	return selected


## Called by fighter_view when a hit/block event arrives
func on_hit(zone: String, blocked: bool, combo_hits: int, move_name: String = "") -> void:
	last_hit_zone = zone
	last_attacker_move = move_name
	if blocked:
		block_impact_tick = int(data["settings"].get("block_impact_ticks", 8))
	combo_count = combo_hits
	var settings: Dictionary = data["settings"]
	combo_shake = clampf(
		(
			float(settings.get("combo_shake_base", 0.006))
			+ float(settings.get("combo_shake_per_hit", 0.003)) * combo_hits
		),
		0.0,
		float(settings.get("combo_shake_max", 0.025))
	)


## Called by fighter_view when a limb is severed
func on_sever() -> void:
	var settings: Dictionary = data["settings"]
	sever_reaction_tick = int(settings.get("sever_reaction_ticks", 45))
	sever_slowmo_tick = int(settings.get("sever_slowmo_ticks", 30))


## Called each frame to tick down reactive timers
func tick_reactive(stopped: bool) -> void:
	if stopped:
		return
	if block_impact_tick > 0:
		block_impact_tick -= 1
	if sever_reaction_tick > 0:
		sever_reaction_tick -= 1
	if sever_slowmo_tick > 0:
		sever_slowmo_tick -= 1
	combo_shake *= 0.92


func _root_pose(fighter: SimFighter, settings: Dictionary, clip_active: bool = false) -> void:
	if clip_active and fighter.pose == "crawl":
		var head := rig.skeleton.find_bone("head")
		var pelvis := rig.skeleton.find_bone("root")
		var torso := (
			rig.skeleton.get_bone_global_pose(head).origin
			- rig.skeleton.get_bone_global_pose(pelvis).origin
		)
		rig.rotation.x = clampf(
			atan2(torso.y, absf(torso.z)) - deg_to_rad(12.0), 0.0, deg_to_rad(80.0)
		)
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
			if str(cap.name).begins_with("WOUND_"):
				continue
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


func _ground(fighter: SimFighter, _settings: Dictionary) -> void:
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
	if fighter.state == SimFighter.State.ACTIVE:
		if fighter.hit_w == 0:
			reach_mismatch_mm = 0
		else:
			var slot := fighter.attack_slot
			var tip_name := ("hand." if slot.begins_with("arm") else "foot.") + slot.right(1)
			if not fighter.limbs.parts.has(slot):
				tip_name = "head"
			var tip := rig.skeleton.find_bone(tip_name)
			var position := (
				(
					rig.transform
					* rig.global_transform.affine_inverse()
					* rig.skeleton.global_transform
				)
				* rig.skeleton.get_bone_global_pose(tip).origin
			)
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
	if fighter.pose == "torso" or preview_pose != "":
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
		act_key = "move_" + fighter.move_name
		if not actions.has(act_key):
			act_key = _action_for_move(fighter.move_name, moves.get(fighter.move_name, {}))
	elif (
		fighter.pose == "crawl" and fighter.state in [SimFighter.State.IDLE, SimFighter.State.WALK]
	):
		act_key = "crawl"
	elif fighter.pose == "hop" and fighter.state in [SimFighter.State.IDLE, SimFighter.State.WALK]:
		act_key = "idle"
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
		if fighter.state == SimFighter.State.HITSTUN:
			act_key = (
				"reaction_wall_splat_bounce"
				if fighter.wall_bounced
				else (
					"reaction_gut_crumple"
					if (
						last_attacker_move
						in ["thunder_elbow_strike", "phantom_ambush", "divine_uppercut"]
					)
					else "hit_head_snap" if last_hit_zone == "head" else "hit_light"
				)
			)
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
		# Multi-strike clips use explicit contact anchors rather than one stretched hit.
		var anchors: Array = actions[act_key].get("contact_phases", [])
		if anchors.size() == fighter.attack_hit_count and anchors.size() > 1:
			var age := float(fighter.state_tick)
			var previous_tick := 0.0
			var previous_phase := 0.0
			for hit_index in anchors.size() + 1:
				var next_tick := float(total_ticks)
				var next_phase := 1.0
				if hit_index < anchors.size():
					next_tick = float(
						fighter.startup_ticks + hit_index * fighter.attack_hit_interval
					)
					next_phase = float(anchors[hit_index])
				if age <= next_tick:
					warp_t = lerpf(
						previous_phase,
						next_phase,
						clampf(
							(age - previous_tick) / maxf(1.0, next_tick - previous_tick), 0.0, 1.0
						)
					)
					break
				previous_tick = next_tick
				previous_phase = next_phase
		var anim_len := rig.anim_player.get_animation(clip_name).length
		rig.anim_player.speed_scale = 1.0
		rig.anim_player.play(clip_name)
		var start := float(actions[act_key].get("start_seconds", 0.0))
		var end := float(actions[act_key].get("end_seconds", anim_len))
		rig.anim_player.seek(lerpf(start, end, clampf(warp_t, 0.0, 1.0)), true)
		var source_side := str(actions[act_key].get("strike_side", fighter.attack_slot.right(1)))
		if (
			source_side != fighter.attack_slot.right(1)
			and fighter.limbs.parts.has(fighter.attack_slot)
		):
			_mirror_attack_pose()
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
		if not stopped and (act_key != "crawl" or fighter.state == SimFighter.State.WALK):
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


func _mirror_attack_pose() -> void:
	var skeleton := rig.skeleton
	skeleton.force_update_all_bone_transforms()
	var reflection := Basis.from_scale(Vector3(-1, 1, 1))
	var goals: Array[Basis] = []
	for bone in skeleton.get_bone_count():
		var name := skeleton.get_bone_name(bone)
		var opposite := name.replace(".l", ".TEMP").replace(".r", ".l").replace(".TEMP", ".r")
		opposite = opposite.replace("Left", "TEMP").replace("Right", "Left").replace(
			"TEMP", "Right"
		)
		var source := skeleton.find_bone(opposite)
		if source < 0:
			source = bone
		var motion := (
			skeleton.get_bone_global_pose(source).basis.orthonormalized()
			* skeleton.get_bone_global_rest(source).basis.orthonormalized().inverse()
		)
		goals.append(
			(
				reflection
				* motion
				* reflection
				* skeleton.get_bone_global_rest(bone).basis.orthonormalized()
			)
		)
	for bone in skeleton.get_bone_count():
		var parent := skeleton.get_bone_parent(bone)
		var local := goals[bone] if parent < 0 else goals[parent].inverse() * goals[bone]
		skeleton.set_bone_pose_rotation(bone, local.get_rotation_quaternion())
