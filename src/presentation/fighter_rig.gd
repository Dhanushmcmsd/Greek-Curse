class_name FighterRig
extends Node3D
## Generated modular mesh adapter. All changes are presentation-only.

var model: Node3D
var groups: Dictionary = {}
var stumps: Dictionary = {}
var sockets: Dictionary = {}


func load_fighter(id: String) -> bool:
	var path := "res://assets/generated/models/fighter_%s.glb" % id
	if not ResourceLoader.exists(path):
		push_error("Missing fighter model: " + path)
		return false
	model = (load(path) as PackedScene).instantiate()
	add_child(model)
	for slot in SimLimbs.LIMB_NAMES:
		var suffix := slot.to_upper()
		groups[slot] = model.find_child("LIMB_" + suffix, true, false)
		stumps[slot] = model.find_child("STUMP_" + suffix, true, false)
		sockets[slot] = model.find_child("SOCKET_" + suffix, true, false)
		if groups[slot] == null or stumps[slot] == null or sockets[slot] == null:
			push_error("Incomplete modular rig: " + id + " " + slot)
			return false
		stumps[slot].visible = false
	return true


func set_limb_visible(slot: String, shown: bool) -> void:
	groups[slot].visible = shown


func show_stump(slot: String, shown: bool) -> void:
	stumps[slot].visible = shown


func attach_to_socket(slot: String, node: Node3D) -> void:
	sockets[slot].add_child(node)


func get_socket_transform(slot: String) -> Transform3D:
	return sockets[slot].global_transform


func sync(fighter: SimFighter) -> void:
	for slot in SimLimbs.LIMB_NAMES:
		var state: String = fighter.limbs.parts[slot].state
		set_limb_visible(slot, state != "severed")
		show_stump(slot, state == "severed")
		groups[slot].rotation.z = 0.3 if state == "cracked" else 0.0
		_tint(groups[slot], Color(0.45, 0.2, 0.35) if state == "bruised" else Color.WHITE)


func _tint(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if color == Color.WHITE:
			mesh.material_overlay = null
		else:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(color, 0.45)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.material_overlay = mat
	for child in node.get_children():
		_tint(child, color)
