class_name DebugOverlay
extends Node3D
## F1 draws hitboxes and prints the tick, state names, and state hash.

var visible_boxes: bool = false
var _label: Label
var _boxes: Array[MeshInstance3D] = []


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(40.0, 120.0)
	_label.size = Vector2(1100.0, 320.0)
	_label.visible = false
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	layer.add_child(_label)
	for _i in 16:
		var mesh := MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(1.0, 0.2, 0.2, 0.35)
		mesh.material_override = material
		mesh.visible = false
		add_child(mesh)
		_boxes.append(mesh)


func set_enabled(enabled: bool) -> void:
	visible_boxes = enabled
	_label.visible = enabled
	if not enabled:
		for mesh in _boxes:
			mesh.visible = false


func refresh(world: SimWorld) -> void:
	if not visible_boxes:
		return
	var lines: PackedStringArray = []
	lines.append("tick %d  hash %d" % [world.tick, world.hash_state()])
	var boxes: Array = []
	for fighter in world.fighters:
		(
			lines
			. append(
				(
					"%s %s x=%d sta=%d meter=%d combo=%d stop=%d"
					% [
						fighter.display_name,
						fighter.state_name(),
						fighter.x,
						fighter.stamina,
						fighter.meter,
						fighter.chain.combo_hits,
						world.hitstop_remaining,
					]
				)
			)
		)
		for limb_box in fighter.limbs.world_boxes(
			fighter.x, fighter.y, fighter.body_width_mm, fighter.height_mm, fighter.pose
		):
			boxes.append(limb_box["rect"])
		if fighter.state == SimFighter.State.ACTIVE:
			boxes.append(fighter.hitbox())
	_label.text = "\n".join(lines)
	for index in _boxes.size():
		var mesh := _boxes[index]
		if index >= boxes.size():
			mesh.visible = false
			continue
		var box: Array = boxes[index]
		var width := float(box[2]) / 1000.0
		var height := float(box[3]) / 1000.0
		var shape := mesh.mesh as BoxMesh
		shape.size = Vector3(width, height, 0.05)
		mesh.position = Vector3(
			float(box[0]) / 1000.0 + width * 0.5, float(box[1]) / 1000.0 + height * 0.5, 0.2
		)
		mesh.visible = true
