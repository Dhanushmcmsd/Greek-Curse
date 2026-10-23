extends SceneTree
## Random matches. Prints crashes, ticks, and ticks per second.


const MATCHES := 1000
const TICKS_EACH := 480
const DOUBLE_RUNS := 200
const DOUBLE_TICKS := 120


func _initialize() -> void:
	var fixture = load("res://tests/proto_fixture.gd")
	var crashes := 0
	var ticks := 0
	var started := Time.get_ticks_msec()
	crashes += _doubles(fixture)
	var rng = SimRng.new(7)
	for _match in MATCHES:
		var world = fixture.world_with({}, rng.range_i(1, 1000000))
		for _tick in TICKS_EACH:
			world.step([rng.range_i(0, 2048), rng.range_i(0, 2048)])
			ticks += 1
			if not _ok(world):
				crashes += 1
				break
	var elapsed := maxi(Time.get_ticks_msec() - started, 1)
	var rate := ticks * 1000 / elapsed
	print("CRASHES=%d" % crashes)
	print("MATCHES=%d" % MATCHES)
	print("DOUBLE_RUNS=%d" % DOUBLE_RUNS)
	print("TICKS=%d" % ticks)
	print("MSEC=%d" % elapsed)
	print("TICKS_PER_SEC=%d" % rate)
	quit(0 if crashes == 0 else 1)


func _doubles(fixture) -> int:
	var crashes := 0
	for index in DOUBLE_RUNS:
		var rng = SimRng.new(1000 + index)
		var left = fixture.world_with({}, index + 1)
		var right = fixture.world_with({}, index + 1)
		for _tick in DOUBLE_TICKS:
			var inputs := [rng.range_i(0, 2048), rng.range_i(0, 2048)]
			left.step(inputs)
			right.step(inputs)
			if left.snapshot_hash() != right.snapshot_hash() or not _ok(left):
				crashes += 1
				break
	return crashes


func _ok(world) -> bool:
	for fighter in world.fighters:
		if fighter.health < 0 or fighter.health > world.max_health:
			return false
		if fighter.stamina < 0 or fighter.stamina > fighter.stamina_max:
			return false
		if fighter.meter < 0 or fighter.meter > int(world.combat["meter_max"]):
			return false
		for name in fighter.limbs.integrity.keys():
			var amount := int(fighter.limbs.integrity[name])
			if amount < 0 or amount > fighter.limbs.max_integrity:
				return false
	return true
