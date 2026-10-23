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
var _rest: Array[Quaternion] = []
var _bounds: Array = []
var _socket_rest: Dictionary = {}
var _cape: Node3D
var _last_creak: int = -1
var _cape_angle: float = 0.0
var _cape_rest := Transform3D.IDENTITY
var _last_states: Dictionary = {}
var _twitch: Dictionary = {}


func setup(target: FighterRig) -> void:
	rig = target
	data = DataLoader.new().load_json("res://data/animation/poses.json").value
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
		var vertices := PackedVector3Array()
		for surface in mesh.mesh.get_surface_count():
			vertices.append_array(mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
		_bounds.append([mesh, rig.skeleton.find_bone(bone), vertices])
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
	var rotations: Dictionary = data["poses"][pose_name]["bones"]
	var other: Dictionary = rotations
	var blend := 0.0
	if pose_name.begins_with("walk_"):
		var cycle: float = time * 60.0 / float(settings["cycle_ticks"]) * data["walk"].size()
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
		rig.skeleton.set_bone_pose_rotation(
			index, _rest[index] * Quaternion.from_euler(angles * PI / 180.0)
		)
	_root_pose(fighter, settings)
	_attachments(fighter, stopped)
	_ground(fighter, settings)
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


func _root_pose(fighter: SimFighter, settings: Dictionary) -> void:
	if fighter.pose == "crawl":
		rig.rotation.x = deg_to_rad(float(settings["crawl_pitch_degrees"]))
	elif fighter.pose == "torso":
		rig.rotation.x = deg_to_rad(float(settings["torso_pitch_degrees"]))
		if fighter.state == SimFighter.State.WALK:
			rig.rotation.x += deg_to_rad(
				sin(time * float(settings["quirk_rate"])) * float(settings["torso_sway_degrees"])
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
		or fighter.state in [SimFighter.State.KO, SimFighter.State.DODGE]
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
		var deform := (
			rig.skeleton.get_bone_global_pose(bone)
			* rig.skeleton.get_bone_global_rest(bone).affine_inverse()
		)
		rig.sockets[slot].transform = deform * _socket_rest[slot]
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
	for item in _bounds:
		var mesh: MeshInstance3D = item[0]
		if not mesh.is_visible_in_tree():
			continue
		var bone: int = item[1]
		var deform := (
			rig.skeleton.get_bone_global_pose(bone)
			* rig.skeleton.get_bone_global_rest(bone).affine_inverse()
		)
		var transform := Transform3D(rig.basis, Vector3.ZERO) * deform * mesh.transform
		for vertex in item[2]:
			floor_min = minf(floor_min, (transform * vertex).y)
	for replacement in rig.replacements.values():
		for mesh in replacement.find_children("*", "MeshInstance3D", true, false):
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
		var slot := fighter.attack_slot
		var tip_name := ("hand." if slot.begins_with("arm") else "foot.") + slot.right(1)
		if not fighter.limbs.parts.has(slot):
			tip_name = "head"
		var tip := rig.skeleton.find_bone(tip_name)
		var position := rig.transform * rig.skeleton.get_bone_global_pose(tip).origin
		reach_mismatch_mm = absi(int(abs(position.x) * 1000.0) - (fighter.hit_x + fighter.hit_w))


static func _slot_for(bone: String) -> String:
	if bone.begins_with("upper_arm") or bone.begins_with("forearm") or bone.begins_with("hand"):
		return "arm_" + bone.right(1)
	if bone.begins_with("thigh") or bone.begins_with("shin") or bone.begins_with("foot"):
		return "leg_" + bone.right(1)
	return ""
