extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	root.size = Vector2i(1280, 720)
	var pilot: Node3D = load("res://scenes/debug/pilot_gate_a_preview.tscn").instantiate()
	root.add_child(pilot)
	pilot.facing_dir = -1.0
	pilot.call("_apply_model_facing")
	pilot.hud_label.hide()
	pilot.cam_front.position = Vector3(0, 1.4, 2.8)
	pilot.cam_front.look_at(Vector3(0, 1.0, 0))
	pilot.cam_front.size = 2.2
	pilot.arm_l_severed = true
	pilot.leg_l_severed = true
	pilot.regrown_arm_attached = true
	pilot.regrown_leg_attached = true
	pilot.call("_update_limb_visibilities")
	for action in ["idle", "kick_thrust", "punch_jab"]:
		pilot.call("play_action", action)
		pilot.anim_player.pause()
		pilot.anim_player.seek(0.35, true)
		for frame in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(
			"res://docs/playtest/combat_presentation/pilot_%s.png" % action
		)
	pilot.call("play_action", "idle")
	pilot.anim_player.pause()
	pilot.anim_player.seek(0.35, true)
	pilot.regrown_arm_attached = false
	pilot.regrown_leg_attached = false
	pilot.call("_update_limb_visibilities")
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(
		"res://docs/playtest/combat_presentation/pilot_wounds.png"
	)
	quit()
