class_name FighterRig
extends Node3D
## Generated modular mesh adapter. All changes are presentation-only.

var model: Node3D
var groups: Dictionary = {}
var stumps: Dictionary = {}
var sockets: Dictionary = {}
var limb_meshes: Dictionary = {}
var stump_meshes: Dictionary = {}
var skeleton: Skeleton3D
var _states: Dictionary = {}


func load_fighter(id: String) -> bool:
	var path := "res://assets/generated/models/fighter_%s.glb" % id
	if not ResourceLoader.exists(path):
		push_error("Missing fighter model: " + path)
		return false
	model = (load(path) as PackedScene).instantiate()
	add_child(model)
	ModelLoader.prepare_materials(model)
	skeleton = model.find_child("Skeleton3D", true, false) as Skeleton3D
	for slot in SimLimbs.LIMB_NAMES:
		var suffix := slot.to_upper()
		groups[slot] = model.find_child("LIMB_" + suffix, true, false)
		stumps[slot] = model.find_child("STUMP_" + suffix, true, false)
		sockets[slot] = model.find_child("SOCKET_" + suffix, true, false)
		if groups[slot] == null or stumps[slot] == null or sockets[slot] == null:
			push_error("Incomplete modular rig: " + id + " " + slot)
			return false
		limb_meshes[slot] = []
		stump_meshes[slot] = []
		var type: String = suffix.substr(0, 3)
		var side: String = suffix.right(1)
		for part in ["UPPER", "LOWER", "END"]:
			var mesh := model.find_child(type + "_" + part + "_" + side, true, false)
			if mesh != null:
				limb_meshes[slot].append(mesh)
		for part in ["CUT_", "BONE_"]:
			var mesh := model.find_child(part + type + side, true, false)
			if mesh != null:
				stump_meshes[slot].append(mesh)
		show_stump(slot, false)
	return true


func set_limb_visible(slot: String, shown: bool) -> void:
	groups[slot].visible = shown
	for mesh in limb_meshes[slot]:
		mesh.visible = shown


func show_stump(slot: String, shown: bool) -> void:
	stumps[slot].visible = shown
	for mesh in stump_meshes[slot]:
		mesh.visible = shown


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
		if _states.get(slot, "") != state:
			for mesh in limb_meshes[slot]:
				_tint(mesh, Color(0.45, 0.2, 0.35) if state == "bruised" else Color.WHITE)
			_states[slot] = state


func pose_limb(slot: String, angle: float) -> void:
	if skeleton == null:
		return
	var bone_name := ("upper_arm." if slot.begins_with("arm") else "thigh.") + slot.right(1)
	var index := skeleton.find_bone(bone_name)
	if index >= 0:
		skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.RIGHT, angle))


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
