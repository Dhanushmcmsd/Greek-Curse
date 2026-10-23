class_name FighterView
extends Node3D
## Greybox body. It displays a sim fighter and never writes one.

var _body: MeshInstance3D
var _rest_color: Color = Color(0.8, 0.8, 0.8)
var _flash_ticks: int = 0


func setup(body_color: Color, height_mm: int, width_mm: int) -> void:
	_rest_color = body_color
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
