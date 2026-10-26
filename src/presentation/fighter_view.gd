class_name FighterView
extends Node3D
## Greybox body. It displays a sim fighter and never writes one.

var driver: PoseDriver
var rig: FighterRig
var visual_stop: int = 0
var _body: MeshInstance3D
var _rest_color: Color = Color(0.8, 0.8, 0.8)
var _flash_ticks: int = 0
var _last_states: Dictionary = {}
var _pose_time: float = 0.0
var _prev_x: int = -999999
var _has_prev_x: bool = false
var _recoil: float = 0.0
var _bleed_tick: int = 0
var _trail_point := Vector3.ZERO
var _trailing := false


func setup(
	body_color: Color, height_mm: int, width_mm: int, id: String = "", model_override: String = ""
) -> void:
	_rest_color = body_color
	if id != "":
		rig = FighterRig.new()
		add_child(rig)
		if rig.load_fighter(id, model_override):
			driver = PoseDriver.new()
			driver.setup(rig)
			return
		rig.queue_free()
		rig = null
	_body = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	var height_m := float(height_mm) / 1000.0
	var radius_m := float(width_mm) / 2000.0
	capsule.height = height_m
	capsule.radius = radius_m
	_body.mesh = capsule
	_body.position.y = height_m * 0.5
	_apply_color(_rest_color)
	add_child(_body)


func show_fighter(fighter: SimFighter, frozen: bool = false) -> void:
	position.x = float(fighter.x) / 1000.0
	position.y = float(fighter.y) / 1000.0
	position.z = 0.0
	if rig != null:
		_update_model(fighter, frozen)
		return
	if _flash_ticks > 0:
		_flash_ticks -= 1
		_apply_color(Color(1.0, 0.95, 0.85))
	elif fighter.blocking:
		_apply_color(Color(0.45, 0.65, 0.9))
	else:
		_apply_color(_rest_color)
	if fighter.state == SimFighter.State.STAGGER:
		_apply_color(Color(0.55, 0.2, 0.2))
	if fighter.state == SimFighter.State.KO:
		_apply_color(Color(0.35, 0.35, 0.35))


func flash() -> void:
	_flash_ticks = 0 if bool(SettingsHooks.get_value("flash_reduction")) else 8


func spark(blocked: bool) -> void:
	if not is_inside_tree() or bool(SettingsHooks.get_value("flash_reduction")):
		return
	var burst := CPUParticles3D.new()
	burst.amount = 6
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.lifetime = 0.2
	burst.initial_velocity_min = 0.8
	burst.initial_velocity_max = 1.5
	burst.spread = 90
	var mesh := SphereMesh.new()
	mesh.radius = 0.025
	mesh.height = 0.05
	burst.mesh = mesh
	burst.color = Color(0.4, 0.7, 1.0) if blocked else Color(1.0, 0.8, 0.3)
	add_child(burst)
	burst.position.y = 1.1
	burst.emitting = true
	get_tree().create_timer(0.3).timeout.connect(burst.queue_free)


func _apply_color(body_color: Color) -> void:
	if _body == null:
		return
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = body_color
	_body.material_override = material


func _update_model(fighter: SimFighter, frozen: bool = false) -> void:
	for slot in SimLimbs.LIMB_NAMES:
		var state: String = fighter.limbs.parts[slot].state
		if state == "severed" and _last_states.get(slot, "healthy") != "severed":
			_sever_effect(slot)
		_last_states[slot] = state
	if _has_prev_x:
		var dx := fighter.x - _prev_x
		if dx != 0:
			driver.walk_direction = 1 if dx > 0 else -1
		elif fighter.state != SimFighter.State.WALK:
			driver.walk_direction = 0
	_prev_x = fighter.x
	_has_prev_x = true
	driver.update(fighter, frozen or visual_stop > 0)
	rig.rotation.z -= _recoil
	if not frozen:
		_recoil *= 0.78
		_bleed_tick += 1
		if _bleed_tick % 30 == 0 and is_inside_tree():
			var manager := get_tree().get_first_node_in_group("gore_manager") as GoreManager
			if manager != null:
				for slot in SimLimbs.LIMB_NAMES:
					if fighter.limbs.parts[slot].state == "severed":
						manager.ooze(rig.sockets[slot].global_position)
	if not frozen and visual_stop == 0 and is_inside_tree():
		var active := (
			fighter.state == SimFighter.State.ACTIVE and fighter.limbs.usable(fighter.attack_slot)
		)
		var point := impact_point(fighter.attack_slot)
		if active and _trailing:
			var manager := get_tree().get_first_node_in_group("gore_manager") as GoreManager
			if manager != null:
				manager.trail(_trail_point, point)
		_trail_point = point
		_trailing = active
	if visual_stop > 0:
		visual_stop -= 1


func _sever_effect(slot: String) -> void:
	if not is_inside_tree():
		return
	var manager := get_tree().get_first_node_in_group("gore_manager") as GoreManager
	if manager == null:
		return
	var pieces: Array = rig.limb_meshes[slot]
	var replacement := rig.replacements.has(slot)
	if replacement:
		pieces = rig.replacements[slot].find_children("*", "MeshInstance3D", true, false)
	for index in pieces.size():
		var original: MeshInstance3D = pieces[index]
		if str(original.name).begins_with("SEAM_"):
			continue
		var pose := original.global_transform
		if not replacement:
			var joints: Array = (
				["upper_arm", "forearm", "hand"]
				if slot.begins_with("arm")
				else ["thigh", "shin", "foot"]
			)
			var joint_name: String = joints[mini(index, joints.size() - 1)] + "." + slot.right(1)
			var bone := rig.skeleton.find_bone(joint_name)
			if bone >= 0:
				var deform := (
					rig.skeleton.get_bone_global_pose(bone)
					* rig.skeleton.get_bone_global_rest(bone).affine_inverse()
				)
				pose = rig.global_transform * deform * original.transform
			elif rig.sockets.has(slot):
				pose = rig.sockets[slot].global_transform
		manager.debris(original, pose, rig.basis.z.x)
	manager.burst(rig.sockets[slot].global_position, false, true)


func recoil(direction: float, blocked: bool) -> void:
	_recoil = direction * (0.035 if blocked else 0.09)


func impact_point(zone: String) -> Vector3:
	if rig == null or rig.skeleton == null:
		return global_position + Vector3(0, 1.2, 0)
	var joint := "spine"
	if zone == "head":
		joint = "head"
	elif zone.begins_with("arm"):
		joint = "forearm." + zone.right(1)
	elif zone.begins_with("leg"):
		joint = "shin." + zone.right(1)
	var bone := FighterRig.resolve_bone(rig.skeleton, joint)
	if bone < 0:
		return global_position + Vector3(0, 1.2, 0)
	return (
		rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(bone).origin
		+ Vector3(0, 0, 0.25)
	)
