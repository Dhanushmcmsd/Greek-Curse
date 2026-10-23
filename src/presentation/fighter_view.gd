class_name FighterView
extends Node3D
## Greybox body. It displays a sim fighter and never writes one.

var rig: FighterRig
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


func show_fighter(fighter: SimFighter) -> void:
	position.x = float(fighter.x) / 1000.0
	position.y = float(fighter.y) / 1000.0
	position.z = 0.0
	if rig != null:
		_update_model(fighter)
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
	_flash_ticks = 8


func _apply_color(body_color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = body_color
	_body.material_override = material


func _update_model(fighter: SimFighter) -> void:
	rig.rotation.y = -float(fighter.facing) * 0.95
	rig.position.y = 0.0
	rig.rotation.z = 0.0
	if fighter.pose == "crawl" or fighter.pose == "torso":
		rig.position.y = -float(fighter.height_mm) / 1000.0 * 0.43
		rig.rotation.z = float(fighter.facing) * 0.25
	elif fighter.pose == "hop" and fighter.state == SimFighter.State.WALK:
		rig.position.y = abs(sin(_pose_time * 10.0)) * 0.12
	for slot in SimLimbs.LIMB_NAMES:
		var state: String = fighter.limbs.parts[slot].state
		if state == "severed" and _last_states.get(slot, "healthy") != "severed":
			_sever_effect(slot)
		_last_states[slot] = state
	rig.sync(fighter)
	_pose_time += 1.0 / 60.0
	for slot in SimLimbs.LIMB_NAMES:
		if not fighter.limbs.usable(slot):
			continue
		var limb: Node3D = rig.groups[slot]
		limb.rotation.x = 0.0
		if fighter.state == SimFighter.State.WALK:
			limb.rotation.x = sin(_pose_time * 12.0 + (PI if slot.ends_with("r") else 0.0)) * 0.30
		if slot == fighter.attack_slot and fighter.move_id > 0:
			limb.rotation.x = -1.3 if fighter.state == SimFighter.State.ACTIVE else -0.5
		rig.pose_limb(slot, limb.rotation.x)


func _sever_effect(slot: String) -> void:
	if not is_inside_tree():
		return
	var source: Node3D = rig.groups[slot]
	var chunk := MeshInstance3D.new()
	var shape := CapsuleMesh.new()
	shape.radius = 0.07
	shape.height = 0.5
	chunk.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = _rest_color
	chunk.material_override = material
	get_tree().current_scene.add_child(chunk)
	chunk.global_transform = source.global_transform
	chunk.visible = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(chunk, "position", chunk.position + Vector3(0.8, -0.3, 0.6), 0.7)
	tween.tween_property(chunk, "rotation", Vector3(2.0, 1.5, 0.5), 0.7)
	tween.chain().tween_callback(chunk.queue_free)
	var burst := CPUParticles3D.new()
	burst.amount = 18
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.lifetime = 0.6
	burst.direction = Vector3(0.5, 0.7, 0.3)
	burst.spread = 65.0
	burst.initial_velocity_min = 0.5
	burst.initial_velocity_max = 1.8
	var particle := SphereMesh.new()
	particle.radius = 0.018
	particle.height = 0.036
	burst.mesh = particle
	burst.color = Color(0.65, 0.02, 0.025)
	get_tree().current_scene.add_child(burst)
	burst.global_position = source.global_position
	burst.emitting = true
	get_tree().create_timer(0.8).timeout.connect(burst.queue_free)
