extends SceneTree
## Plays the fixed prototype input log and prints the final state hash.


func _initialize() -> void:
	var code := 1
	var fixture = load("res://tests/proto_fixture.gd")
	var proto = load("res://src/sim/proto_script.gd")
	var world = fixture.world_with()
	var tick := 0
	while world.phase == 0 and tick < 5000:
		world.step(proto.inputs_at(tick))
		tick += 1
	print("FINAL_HASH=%s" % str(world.hash_state()))
	print("WINS=%d,%d" % [world.wins[0], world.wins[1]])
	print("TICKS=%d" % world.tick)
	print("PHASE=%d" % world.phase)
	if world.phase == 1:
		code = 0
	quit(code)
