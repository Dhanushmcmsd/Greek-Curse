class_name LimbFinish
extends RefCounted


static func wound(skeleton: Skeleton3D, slot: String) -> MeshInstance3D:
	var bone := FighterRig.resolve_bone(
		skeleton, ("upper_arm." if slot.begins_with("arm") else "thigh.") + slot.right(1)
	)
	var next := FighterRig.resolve_bone(
		skeleton, ("forearm." if slot.begins_with("arm") else "shin.") + slot.right(1)
	)
	if bone < 0 or next < 0:
		return null
	var attachment := BoneAttachment3D.new()
	attachment.bone_idx = bone
	skeleton.add_child(attachment)
	var delta := (
		skeleton.get_bone_global_rest(bone).affine_inverse()
		* skeleton.get_bone_global_rest(next).origin
	)
	var length := delta.length()
	var mesh := MeshInstance3D.new()
	mesh.name = "WOUND_" + slot
	var cap := SphereMesh.new()
	cap.radius = length * (0.23 if slot.begins_with("arm") else 0.32)
	cap.height = cap.radius * 2.0
	cap.radial_segments = 24
	cap.rings = 12
	mesh.mesh = cap
	attachment.add_child(mesh)
	var direction := delta.normalized()
	mesh.quaternion = Quaternion(Vector3.UP, direction)
	mesh.scale.y = 0.08
	mesh.position = -direction * length * 0.015
	var material := ShaderMaterial.new()
	material.shader = load("res://src/presentation/wound.gdshader")
	var color: Color = (
		{"red": Color("a91830"), "green": Color("54b52b"), "golden": Color("edba44")}
		. get(SettingsHooks.get_value("blood_color"), Color("a91830"))
	)
	material.set_shader_parameter(
		"flesh", Color("555963") if SettingsHooks.get_value("gore") == "off" else color
	)
	mesh.material_override = material
	mesh.hide()
	return mesh


static func bridge(container: Node3D, originals: Array, skeleton: Skeleton3D, slot: String) -> void:
	var bone := FighterRig.resolve_bone(
		skeleton, ("upper_arm." if slot.begins_with("arm") else "thigh.") + slot.right(1)
	)
	var next := FighterRig.resolve_bone(
		skeleton, ("forearm." if slot.begins_with("arm") else "shin.") + slot.right(1)
	)
	if bone < 0 or next < 0:
		return
	var start := skeleton.get_bone_global_rest(bone).origin
	var delta := skeleton.get_bone_global_rest(next).origin - start
	for original in originals:
		if original.skin == null:
			continue
		var mesh := MeshInstance3D.new()
		mesh.name = "SEAM_" + str(original.name)
		var feathered := ArrayMesh.new()
		for surface in original.mesh.get_surface_count():
			var arrays: Array = original.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var colors := PackedColorArray()
			for vertex in vertices:
				var along := (vertex - start).dot(delta.normalized()) / (delta.length() * 0.55)
				colors.append(Color(clampf(along, 0.0, 1.0), 0, 0, 1))
			for channel in range(Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM3 + 1):
				arrays[channel] = null
			arrays[Mesh.ARRAY_COLOR] = colors
			feathered.add_surface_from_arrays(
				original.mesh.surface_get_primitive_type(surface), arrays
			)
		mesh.mesh = feathered
		mesh.skin = original.skin
		mesh.transform = original.transform
		container.add_child(mesh)
		mesh.skeleton = NodePath("../..")
		for surface in mesh.mesh.get_surface_count():
			var mat := ShaderMaterial.new()
			mat.shader = load("res://src/presentation/seam.gdshader")
			mat.set_shader_parameter("joint", start)
			mat.set_shader_parameter("axis", delta.normalized())
			mat.set_shader_parameter("reach", delta.length() * 0.55)
			var original_mat := original.get_active_material(surface) as StandardMaterial3D
			if original_mat != null:
				mat.set_shader_parameter("base_color", original_mat.albedo_color)
				if original_mat.albedo_texture != null:
					mat.set_shader_parameter("skin_texture", original_mat.albedo_texture)
					mat.set_shader_parameter("textured", true)
			mesh.set_surface_override_material(surface, mat)


static func posed_mesh(original: MeshInstance3D) -> ArrayMesh:
	var skeleton := original.get_node_or_null(original.skeleton) as Skeleton3D
	if original.skin == null or skeleton == null:
		return null
	var transforms: Array[Transform3D] = []
	for bind in original.skin.get_bind_count():
		var bone := original.skin.get_bind_bone(bind)
		if not original.skin.get_bind_name(bind).is_empty():
			bone = skeleton.find_bone(original.skin.get_bind_name(bind))
		if bone < 0:
			return null
		transforms.append(skeleton.get_bone_global_pose(bone) * original.skin.get_bind_pose(bind))
	var result := ArrayMesh.new()
	for surface in original.mesh.get_surface_count():
		var arrays: Array = original.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var count := weights.size() / vertices.size()
		for index in vertices.size():
			var point := Vector3.ZERO
			var normal := Vector3.ZERO
			for influence in count:
				var offset := index * count + influence
				var transform := transforms[bones[offset]]
				point += (transform * vertices[index]) * weights[offset]
				if not normals.is_empty():
					normal += (transform.basis * normals[index]) * weights[offset]
			vertices[index] = point
			if not normals.is_empty():
				normals[index] = normal.normalized()
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		for channel in range(Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM3 + 1):
			arrays[channel] = null
		arrays[Mesh.ARRAY_TANGENT] = null
		arrays[Mesh.ARRAY_BONES] = null
		arrays[Mesh.ARRAY_WEIGHTS] = null
		result.add_surface_from_arrays(original.mesh.surface_get_primitive_type(surface), arrays)
	return result
