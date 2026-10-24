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
	assert_eq(frame.y, 11.0, "camera max distance")
	assert_eq(FightCamera.framing(10, 11, settings).x, 2.5, "camera clamp")
	var gore := GoreManager.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(gore)
	for i in 640:
		gore.splat(Vector3.ZERO, false)
		gore.splat(Vector3.ZERO, true)
	assert_eq(gore.floor_splats.size(), 64, "floor budget")
	assert_eq(gore.wall_splats.size(), 32, "wall budget")
	SettingsHooks.values["gore"] = "off"
	gore.splat(Vector3.ZERO, false)
	assert_eq(gore.floor_splats.size(), 64, "off adds no blood")
	SettingsHooks.values["gore"] = "normal"
	gore.free()
