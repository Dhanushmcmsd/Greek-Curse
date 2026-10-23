extends TestBase


func test_toggle_and_binding_roundtrip() -> void:
	var input := PlayerInput.new()
	input.toggle_block = true
	assert_eq(input.transform(128), 128, "toggle on")
	assert_eq(input.transform(128), 128, "hold does not toggle")
	assert_eq(input.transform(0), 128, "release holds")
	assert_eq(input.transform(128), 0, "next edge toggles off")
	var bindings := InputBindings.new()
	bindings.reset_defaults()
	assert_true(bindings.rebind("p1_light", bindings.bindings["p1_heavy"]) != "", "conflict")
	assert_eq(bindings.rebind("p1_light", {"key": "Q", "button": -1, "device": 0}), "", "rebind")
	var restored := InputBindings.new()
	assert_eq(restored.import_bindings(bindings.export_bindings()), "", "import")
	assert_eq(restored.export_bindings(), bindings.export_bindings(), "round trip")


func test_buffer_preserves_direction_at_press() -> void:
	var buffer := SimInputBuffer.new()
	buffer.push(SimInput.RIGHT | SimInput.LIGHT, 1, 6)
	buffer.push(0, 2, 6)
	assert_eq(buffer.direction_for(SimInput.LIGHT), SimInput.RIGHT, "direction captured")
	assert_true(buffer.has_edge(SimInput.LIGHT, 7, 6), "last valid tick")
	buffer.push(0, 8, 6)
	assert_true(not buffer.has_edge(SimInput.LIGHT, 8, 6), "expired")


func test_recording_replays_identically() -> void:
	var world := ProtoFixture.world_with()
	var recorder := InputRecorder.new()
	for tick in 120:
		var masks := ProtoScript.inputs_at(tick)
		world.step(masks)
		recorder.record(world, masks)
	assert_eq(recorder.save_to("res://build/input_roundtrip.json", world), OK, "saved")
	assert_eq(ReplayCheck.verify("res://build/input_roundtrip.json"), "", "replayed")
