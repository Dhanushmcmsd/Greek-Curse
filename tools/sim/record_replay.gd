extends SceneTree
## Writes the scripted prototype replay. Live play uses MatchController --record=.


func _initialize() -> void:
	var fixture = load("res://tests/proto_fixture.gd")
	var proto = load("res://src/sim/proto_script.gd")
	var world = fixture.world_with()
	var inputs: Array = []
	var hashes: Array = []
	var tick := 0
	while world.phase == 0 and tick < 5000:
		var row: Array = proto.inputs_at(tick)
		inputs.append(row)
		world.step(row)
		tick += 1
		if world.tick % 30 == 0:
			hashes.append(str(world.snapshot_hash()))
	var payload := {
		"seed": 1,
		"fighters": ["theron", "atalanta"],
		"arena": "greybox",
		"hashes_every": 30,
		"final_hash": str(world.snapshot_hash()),
		"wins": [world.wins[0], world.wins[1]],
		"hashes": hashes,
		"inputs": inputs,
	}
	var path := ProjectSettings.globalize_path("res://tests/golden/proto_match_01.replay.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("RECORD_FAIL")
		quit(1)
		return
	file.store_string(JSON.stringify(payload))
	print("RECORDED %s ticks=%d" % [path, world.tick])
	quit(0)
