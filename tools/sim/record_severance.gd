extends SceneTree


func _initialize() -> void:
	var fixture = load("res://tests/proto_fixture.gd")
	var checker = load("res://src/presentation/replay_check.gd")
	var world = fixture.world_with()
	checker.configure(world, "severance")
	var inputs: Array = []
	var hashes: Array = []
	var order: Array = []
	for i in 150:
		var row := [SimInput.LIGHT, 0]
		inputs.append(row)
		for event in world.step(row):
			if event.kind >= SimEvent.Kind.LIMB_STATE_CHANGED:
				var entry := {"kind": SimEvent.Kind.keys()[event.kind], "payload": event.payload}
				order.append(entry)
				print(entry)
		if world.tick % 30 == 0:
			hashes.append(str(world.hash_state()))
	var file := FileAccess.open("res://tests/golden/severance_01.replay.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"seed": 1, "scenario": "severance", "inputs": inputs,
		"hashes_every": 30, "hashes": hashes, "final_hash": str(world.hash_state()), "events": order}))
	quit(0 if world.amputations.size() == 1 else 1)
