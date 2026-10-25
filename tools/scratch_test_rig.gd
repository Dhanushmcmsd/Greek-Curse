extends SceneTree

func _init():
	var log_script = load("res://src/core/log.gd")
	if not root.has_node("Log"):
		var l = Node.new()
		l.name = "Log"
		l.set_script(log_script)
		root.add_child(l)

	var rig = FighterRig.new()
	rig.load_fighter("theron")
	root.add_child(rig)
	
	print("THERON RIG LOADED:")
	print(" - rig.model:", rig.model)
	print(" - rig.skeleton:", rig.skeleton)
	if rig.skeleton:
		print(" - rig.skeleton bone count:", rig.skeleton.get_bone_count())
		var head_idx = rig.skeleton.find_bone("head")
		print(" - head bone index:", head_idx, " name:", rig.skeleton.get_bone_name(head_idx) if head_idx >= 0 else "NONE")
		print(" - head rest pos:", rig.skeleton.get_bone_rest(head_idx).origin if head_idx >= 0 else "NONE")
		print(" - head pose pos:", rig.skeleton.get_bone_pose_position(head_idx) if head_idx >= 0 else "NONE")
		print(" - head pose rot:", rig.skeleton.get_bone_pose_rotation(head_idx) if head_idx >= 0 else "NONE")
		print(" - head pose scale:", rig.skeleton.get_bone_pose_scale(head_idx) if head_idx >= 0 else "NONE")
	
	if rig.model:
		var head_mesh = rig.model.find_child("HEAD", true, false) as MeshInstance3D
		print(" - HEAD mesh found:", head_mesh)
		if head_mesh:
			print("   visible:", head_mesh.visible)
			print("   skeleton path:", head_mesh.skeleton)
			print("   skin:", head_mesh.skin)
			if head_mesh.skin:
				print("   skin bind_count:", head_mesh.skin.get_bind_count())
				for b in head_mesh.skin.get_bind_count():
					print("     bind ", b, " name:", head_mesh.skin.get_bind_name(b), " bone:", head_mesh.skin.get_bind_bone(b), " pose:", head_mesh.skin.get_bind_pose(b))
			print("   mesh surface count:", head_mesh.mesh.get_surface_count() if head_mesh.mesh else 0)
			if head_mesh.mesh:
				print("   mesh aabb:", head_mesh.mesh.get_aabb())
				for s in head_mesh.mesh.get_surface_count():
					print("   mat surface ", s, ":", head_mesh.get_active_material(s))
			
	quit(0)

