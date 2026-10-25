extends SceneTree
## Captures multi-frame high-resolution screenshots of Gate A Pilot for visual proof.

func _init() -> void:
	print("--- Capturing Gate A Multi-frame Screenshots ---")
	var scene_pck := load("res://scenes/debug/pilot_gate_a_preview.tscn") as PackedScene
	var root_node := scene_pck.instantiate()
	root.add_child(root_node)
	var pilot: Node = root_node
	
	DirAccess.make_dir_recursive_absolute("e:/zeus balls/docs/playtest/pilot_gate_a")
	
	var ap: AnimationPlayer = pilot.get("anim_player")
	var actions: Array[String] = ["idle", "walk_fwd", "walk_back", "punch_jab", "kick_thrust"]
	
	# Step through each action and take screenshots at key poses
	for act in actions:
		pilot.call("play_action", act)
		var anim: Animation = ap.get_animation(act)
		var dur: float = anim.length
		
		# Sample start (anticipation), mid (peak contact/stride), and late (recovery)
		var fractions: Array[float] = [0.1, 0.45, 0.85]
		for i in fractions.size():
			var t: float = fractions[i] * dur
			ap.seek(t, true)
			
			var vp := root.get_viewport()
			RenderingServer.force_draw(true)
			var img := vp.get_texture().get_image()
			if img != null:
				var path := "e:/zeus balls/docs/playtest/pilot_gate_a/%s_frame%d.png" % [act, i + 1]
				img.save_png(path)
				print("Saved screenshot: ", path)
				
	print("GATE_A_SCREENSHOTS_DONE")
	quit(0)
