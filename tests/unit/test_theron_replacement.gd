extends TestBase


func test_every_live_theron_action_is_replaced_and_bound() -> void:
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/mixamo_pack_map.json"))
	var manifest: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/theron_boxer_manifest.json"))
	var rig := FighterRig.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	assert_true(rig.load_fighter("theron"), "load replacement rig")
	var actions: Dictionary = mapping.fighters.theron.actions
	assert_eq(actions.size(), manifest.size(), "replacement covers all live actions")
	assert_eq(rig.anim_player.get_animation_list().size(), actions.size(), "no legacy animation library remains loaded")
	for entry in manifest:
		var action := str(entry.action)
		var filename := action.trim_prefix("move_") if action.begins_with("move_") else "action_" + action
		var path := "res://assets/animations/exported/theron/" + filename + ".res"
		assert_true(FileAccess.get_sha256(path) != str(entry.previous_resource_sha256), "new resource: " + action)
		assert_eq(str(actions[action].get("motion_set", "")), "theron_boxer_v2", action)
		assert_true(rig.anim_player.has_animation("theron_" + action), "bound " + action)
		var animation := rig.anim_player.get_animation("theron_" + action)
		assert_true(animation.length > 0.0 and animation.get_track_count() > 0, "animated " + action)
		if action.begins_with("move_"):
			var row: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/" + action.trim_prefix("move_") + ".json"))
			if int(row.get("hit_count", 1)) > 1:
				assert_eq(actions[action].get("contact_phases", []).size(), int(row.hit_count), "contact count " + action)
	rig.free()
