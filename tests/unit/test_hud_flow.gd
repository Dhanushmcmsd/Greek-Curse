extends TestBase


func test_round_flow_and_pause() -> void:
	var flow := RoundFlow.new()
	var world := ProtoFixture.world_with()
	var before := world.hash_state()
	flow.paused = true
	for tick in 100:
		if flow.advance():
			world.step([0, 0])
	assert_eq(world.hash_state(), before, "pause never steps")
	flow.paused = false
	for tick in 100:
		flow.advance()
	assert_eq(flow.phase, "fight", "intro ready fight")
	flow.consume([SimEvent.make(SimEvent.Kind.MATCH_END, 0, 1, 0, 2, 0)])
	for tick in 122:
		flow.advance()
	assert_eq(flow.phase, "results", "results reached")


func test_patterns_are_not_color_only_and_settings_scale() -> void:
	var patterns: Array = []
	for state in ["healthy", "bruised", "cracked", "severed"]:
		var display := BodyDiagram.display_for(state)
		assert_true(not patterns.has(display[1]), "unique pattern")
		patterns.append(display[1])
	SettingsHooks.values["shake_percent"] = -100
	assert_eq(SettingsHooks.scale_amount(10.0, "shake_percent"), 0.0, "negative clamped")
	SettingsHooks.values["shake_percent"] = 50
	assert_eq(SettingsHooks.scale_amount(10.0, "shake_percent"), 5.0, "scale")
	SettingsHooks.values["shake_percent"] = 100


func test_severance_hud_receives_credit() -> void:
	var world := ProtoFixture.world_with()
	ReplayCheck.configure(world, "severance")
	var hud := CombatHud.new()
	for tick in 180:
		var gap := absi(world.fighters[1].x - world.fighters[0].x)
		hud.consume(world.step([SimInput.RIGHT if gap > 450 else SimInput.LIGHT, 0]), world)
		if hud.credit_text.contains("arm_l"):
			break
	assert_true(hud.credit_text.contains("arm_l"), "credit banner driven by events")
	hud.free()


func test_widget_scenes_instantiate() -> void:
	for path in ["hud/combat_hud", "hud/body_diagram", "pause_menu", "results_stub"]:
		var scene := load("res://scenes/ui/%s.tscn" % path) as PackedScene
		var node := scene.instantiate()
		assert_true(node != null, "scene instance")
		node.free()
