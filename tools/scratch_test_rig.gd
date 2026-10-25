extends SceneTree

func _init():
	var rig = FighterRig.new()
	rig.load_fighter("theron")
	root.add_child(rig)
	
	print("THERON RIG LOADED:")
	print(" - rig.model:", rig.model)
	print(" - rig.skeleton:", rig.skeleton)
	print(" - rig.skeleton bone count:", rig.skeleton.get_bone_count())
	var head_idx = rig.skeleton.find_bone("head")
	print(" - head bone index:", head_idx, " name:", rig.skeleton.get_bone_name(head_idx) if head_idx >= 0 else "NONE")
	print(" - head rest pos:", rig.skeleton.get_bone_rest(head_idx).origin if head_idx >= 0 else "NONE")
	
	var head_mesh = rig.model.find_child("HEAD", true, false) as MeshInstance3D
	print(" - HEAD mesh found:", head_mesh)
	if head_mesh:
		print("   visible:", head_mesh.visible)
		print("   skeleton path:", head_mesh.skeleton)
		print("   skin:", head_mesh.skin)
		print("   mesh surface count:", head_mesh.mesh.get_surface_count())
		for s in head_mesh.mesh.get_surface_count():
			print("   mat surface ", s, ":", head_mesh.get_active_material(s))
			
	quit(0)
