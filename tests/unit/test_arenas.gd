extends TestBase


func _world(id: String, enabled: bool = true) -> SimWorld:
	var config := MatchConfig.new()
	config.arena_id = id
	config.rules["hazards"] = enabled
	return MatchLauncher.make_world(config)


func test_telegraph_precedes_damage_and_hits_once() -> void:
	var world := _world("mount_olympus")
	world.hazard_offset = 1
	world.hazard_zone = 0
	world.fighters[0].x = -3500
	for tick in 90:
		world.step([0, 0])
	assert_eq(world.fighters[0].health, 300, "full ninety tick warning")
	world.step([0, 0])
	assert_eq(world.fighters[0].health, 275, "lightning damage")
	for tick in 29:
		world.step([0, 0])
	assert_eq(world.fighters[0].health, 275, "one hit per eruption")
	assert_eq(world.fighters[1].health, 300, "safe zone immunity")


func test_hazard_seed_determinism_and_off_switch() -> void:
	for id in ["mount_olympus", "athens_colosseum", "tartarus_pits"]:
		var a := _world(id)
		var b := _world(id)
		var off := _world(id, false)
		for world in [a, b, off]:
			world.fighters[0].x = -3500
		for tick in 1000:
			a.step([0, 0])
			b.step([0, 0])
			var events := off.step([0, 0])
			assert_eq(events.size(), 0, "disabled hazard emits nothing")
		assert_eq(a.hash_state(), b.hash_state(), id + " deterministic")
		assert_eq(off.fighters[0].health, 300, "disabled damage")


func test_camera_clamps_and_gore_caps() -> void:
	var settings: Dictionary = DataLoader.new().load_json("res://data/art/vfx.json").value["camera"]
	var frame := FightCamera.framing(-100, 100, settings)
	assert_eq(frame.y, float(settings["maximum_distance"]), "camera max distance")
	assert_eq(FightCamera.framing(10, 11, settings).x, 2.5, "camera clamp")
	var gore := GoreManager.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(gore)
	for i in 640:
		gore.splat(Vector3.ZERO, false)
		gore.splat(Vector3.ZERO, true)
	assert_eq(gore.floor_splats.size(), int(gore.config["floor_cap"]), "floor budget")
	assert_eq(gore.wall_splats.size(), int(gore.config["wall_cap"]), "wall budget")
	SettingsHooks.values["gore"] = "off"
	gore.splat(Vector3.ZERO, false)
	assert_eq(gore.floor_splats.size(), int(gore.config["floor_cap"]), "off adds no blood")
	SettingsHooks.values["gore"] = "normal"
	gore.free()


func test_hazard_presentation_states() -> void:
	var builder := ArenaBuilder.new()
	builder.arena_id = "mount_olympus"
	(Engine.get_main_loop() as SceneTree).root.add_child(builder)

	var world := _world("mount_olympus")
	world.hazard_offset = 100
	world.hazard_zone = 0

	# 1. Before hazard: all markers and active columns hidden
	world.tick = 50
	builder.sync(world)
	for marker in builder.markers:
		assert_false(marker.visible, "marker hidden before hazard offset")
		var col: MeshInstance3D = marker.get_meta("active_column", null) as MeshInstance3D
		if col != null:
			assert_false(col.visible, "active column hidden before hazard offset")

	# 2. Telegraph phase (tick = 100 to 189): floor marker visible, column hidden,
	# marker scale.y == 1.0 (flat disk)
	world.tick = 120
	builder.sync(world)
	var active_marker := builder.markers[0]
	assert_true(active_marker.visible, "telegraph disk visible during warning")
	assert_eq(active_marker.scale.y, 1.0, "telegraph disk remains flat (scale.y == 1.0)")
	var active_col: MeshInstance3D = active_marker.get_meta("active_column", null) as MeshInstance3D
	assert_true(active_col != null, "active column node exists")
	assert_false(active_col.visible, "active column hidden during telegraph phase")

	# 3. Active eruption phase (tick = 190 to 219): floor marker visible, column translucent
	world.tick = 195
	builder.sync(world)
	assert_true(active_marker.visible, "floor marker remains visible during eruption")
	assert_eq(active_marker.scale.y, 1.0, "floor marker does not scale into opaque wall")
	assert_true(active_col.visible, "active energy column visible during active phase")
	var mat := active_col.material_override as StandardMaterial3D
	assert_true(mat != null, "column has standard material")
	assert_true(
		mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA,
		"column material is alpha transparent"
	)
	assert_true(mat.albedo_color.a <= 0.25, "column is subtle/translucent (alpha <= 0.25)")

	# 4. Flash reduction accessibility mode
	SettingsHooks.values["flash_reduction"] = true
	builder.sync(world)
	assert_true(mat.albedo_color.a <= 0.15, "flash reduction lowers column opacity")
	SettingsHooks.values["flash_reduction"] = false

	# 5. Cycle end / reset: hidden
	world.tick = 230
	builder.sync(world)
	assert_false(active_marker.visible, "marker hidden after active eruption concludes")
	assert_false(active_col.visible, "column hidden after active eruption concludes")

	builder.get_parent().remove_child(builder)
	builder.free()
