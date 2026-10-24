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


func setup(body_color: Color, height_mm: int, width_mm: int, id: String = "") -> void:
	_rest_color = body_color
	if id != "":
		rig = FighterRig.new()
		add_child(rig)
		if rig.load_fighter(id):
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
	driver.update(fighter, frozen or visual_stop > 0)
	if visual_stop > 0:
		visual_stop -= 1


func _sever_effect(slot: String) -> void:
	if not is_inside_tree():
		return
	var source: Node3D = rig.groups[slot]
	var manager := get_tree().get_first_node_in_group("gore_manager") as GoreManager
	if manager == null:
		return
	var pieces: Array = rig.limb_meshes[slot]
	var replacement := rig.replacements.has(slot)
	if replacement:
		pieces = rig.replacements[slot].find_children("*", "MeshInstance3D", true, false)
	for index in pieces.size():
		var original: MeshInstance3D = pieces[index]
		var pose := original.global_transform
		if not replacement:
			var joints: Array = (
				["upper_arm", "forearm", "hand"]
				if slot.begins_with("arm")
				else ["thigh", "shin", "foot"]
			)
			var bone := rig.skeleton.find_bone(joints[index] + "." + slot.right(1))
			var deform := (
				rig.skeleton.get_bone_global_pose(bone)
				* rig.skeleton.get_bone_global_rest(bone).affine_inverse()
			)
			pose = rig.global_transform * deform * original.transform
		manager.debris(original, pose, rig.basis.z.x)
	manager.burst(source.global_position, false, true)
