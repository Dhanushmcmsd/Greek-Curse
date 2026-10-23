class_name SimWorld
extends RefCounted
## Fixed-tick lane match. step() is the only way this object changes.

const PHASE_FIGHTING := 0
const PHASE_MATCH_OVER := 1

var tick: int = 0
var round_tick: int = 0
var round_index: int = 1
var phase: int = PHASE_FIGHTING
var wins: Array[int] = [0, 0]
var draw_uses: int = 0
var max_health: int = 300
var round_ticks: int = 5400
var rounds_to_win: int = 2
var draw_replays: int = 1
var arena_min_x: int = -4500
var arena_max_x: int = 4500
var floor_y: int = 0
var spawn_x: Array[int] = [-900, 900]
var fighters: Array[SimFighter] = []
var moves: Array[Dictionary] = []
var rng: SimRng = SimRng.new(1)


static func from_data(
	rules: Dictionary,
	curves: Dictionary,
	fighter_rows: Array,
	move_rows: Array,
	seed_value: int = 1
) -> SimWorld:
	var world := SimWorld.new()
	world.rng = SimRng.new(seed_value)
	world.max_health = int(rules["max_health"])
	world.round_ticks = int(rules["round_ticks"])
	world.rounds_to_win = int(rules["rounds_to_win"])
	world.draw_replays = int(rules["draw_replays"])
	world.arena_min_x = int(rules["arena_min_x"])
	world.arena_max_x = int(rules["arena_max_x"])
	world.floor_y = int(rules["floor_y"])
	world.spawn_x = [int(rules["spawn_x"][0]), int(rules["spawn_x"][1])]
	var speeds: Array = curves["speed_mm_per_tick"]
	var powers: Array = curves["power_percent"]
	world.moves = []
	for row in move_rows:
		world.moves.append(row)
	world.fighters = []
	for index in fighter_rows.size():
		world.fighters.append(
			world._make_fighter(fighter_rows[index], speeds, powers, int(rules["stamina"]), index)
		)
	return world


func _make_fighter(
	row: Dictionary, speeds: Array, powers: Array, stamina_value: int, index: int
) -> SimFighter:
	var fighter := SimFighter.new()
	fighter.fighter_id = str(row["id"])
	fighter.display_name = str(row["display_name"])
	fighter.reach = int(row["reach"])
	fighter.limb_toughness = int(row["limb_toughness"])
	fighter.height_mm = int(row["height_mm"])
	fighter.body_width_mm = int(row["body_width_mm"])
	fighter.walk_speed = int(speeds[int(row["speed"])])
	fighter.power_percent = int(powers[int(row["power"])])
	fighter.health = max_health
	fighter.stamina = stamina_value
	fighter.y = floor_y
	fighter.x = spawn_x[index]
	fighter.facing = 1 if index == 0 else -1
	return fighter


func step(inputs: Array) -> Array:
	var events: Array = []
	if phase != PHASE_FIGHTING:
		return events
	tick += 1
	round_tick += 1
	var masks: Array[int] = [_mask_at(inputs, 0), _mask_at(inputs, 1)]
	for index in fighters.size():
		_advance_fighter(fighters[index], masks[index])
	_face()
	_separate()
	_resolve_hits(events)
	_separate()
	_finish_round(events)
	return events


func hash_state() -> int:
	var values: Array = [
		tick, round_tick, phase, round_index, wins[0], wins[1], draw_uses, rng.get_state()
	]
	for fighter in fighters:
		(
			values
			. append_array(
				[
					fighter.x,
					fighter.y,
					fighter.facing,
					fighter.state,
					fighter.state_tick,
					fighter.move_age,
					fighter.health,
					fighter.move_id,
					1 if fighter.has_hit else 0,
					fighter.stamina,
					1 if fighter.blocking else 0,
				]
			)
		)
	return StateHash.hash_ints(values)


func _mask_at(inputs: Array, index: int) -> int:
	if index >= inputs.size():
		return 0
	return int(inputs[index])


func _advance_fighter(fighter: SimFighter, mask: int) -> void:
	fighter.blocking = (
		SimInput.has_bit(mask, SimInput.BLOCK) and fighter.state != SimFighter.State.KO
	)
	if fighter.state == SimFighter.State.KO:
		return
	if fighter.state == SimFighter.State.HITSTUN:
		fighter.state_tick -= 1
		if fighter.state_tick <= 0:
			fighter.state = SimFighter.State.IDLE
			fighter.state_tick = 0
		return
	if _busy(fighter):
		_age_move(fighter)
		fighter.x += fighter.facing * fighter.attack_hop
		return
	_walk(fighter, mask)
	_try_start_move(fighter, mask)
	if _busy(fighter):
		fighter.x += fighter.facing * fighter.attack_hop


func _busy(fighter: SimFighter) -> bool:
	return (
		fighter.state == SimFighter.State.STARTUP
		or fighter.state == SimFighter.State.ACTIVE
		or fighter.state == SimFighter.State.RECOVERY
	)


func _age_move(fighter: SimFighter) -> void:
	var startup := fighter.startup_ticks
	var active_end := startup + fighter.active_ticks
	var total := active_end + fighter.recovery_ticks
	if fighter.move_age < startup:
		fighter.state = SimFighter.State.STARTUP
	elif fighter.move_age < active_end:
		fighter.state = SimFighter.State.ACTIVE
	elif fighter.move_age < total:
		fighter.state = SimFighter.State.RECOVERY
	else:
		fighter.state = SimFighter.State.IDLE
		fighter.clear_move()
		return
	fighter.state_tick = fighter.move_age
	fighter.move_age += 1


func _walk(fighter: SimFighter, mask: int) -> void:
	var direction := 0
	if SimInput.has_bit(mask, SimInput.LEFT):
		direction -= 1
	if SimInput.has_bit(mask, SimInput.RIGHT):
		direction += 1
	if direction == 0:
		fighter.state = SimFighter.State.IDLE
		return
	fighter.state = SimFighter.State.WALK
	fighter.x += direction * fighter.walk_speed


func _try_start_move(fighter: SimFighter, mask: int) -> void:
	var index := 0
	if SimInput.has_bit(mask, SimInput.LIGHT):
		index = 1
	elif SimInput.has_bit(mask, SimInput.HEAVY):
		index = 2
	elif SimInput.has_bit(mask, SimInput.KICK):
		index = 3
	if index == 0 or index > moves.size():
		return
	var move: Dictionary = moves[index - 1]
	var scaled := Fx.percent(int(move["damage"]), fighter.power_percent)
	fighter.begin_move(index, move, scaled)
	_age_move(fighter)


func _face() -> void:
	var left := fighters[0]
	var right := fighters[1]
	if left.x < right.x:
		left.facing = 1
		right.facing = -1
	elif left.x > right.x:
		left.facing = -1
		right.facing = 1


func _separate() -> void:
	_push_apart()
	_clamp_all()
	var left := fighters[0]
	var right := fighters[1]
	if left.x > right.x:
		left = fighters[1]
		right = fighters[0]
	var min_dist := left.half_width() + right.half_width()
	if right.x - left.x >= min_dist:
		return
	if left.x <= _low(left):
		right.x = left.x + min_dist
	else:
		left.x = right.x - min_dist
	_clamp_all()


func _push_apart() -> void:
	var left := fighters[0]
	var right := fighters[1]
	if left.x > right.x:
		left = fighters[1]
		right = fighters[0]
	var min_dist := left.half_width() + right.half_width()
	var gap := right.x - left.x
	if gap >= min_dist:
		return
	var overlap := min_dist - gap
	var share := overlap / 2
	left.x -= share
	right.x += overlap - share


func _clamp_all() -> void:
	for fighter in fighters:
		fighter.x = Fx.clamp_i(fighter.x, _low(fighter), _high(fighter))
		fighter.y = floor_y


func _low(fighter: SimFighter) -> int:
	return arena_min_x + fighter.half_width()


func _high(fighter: SimFighter) -> int:
	return arena_max_x - fighter.half_width()


func _resolve_hits(events: Array) -> void:
	for attacker_index in fighters.size():
		var attacker := fighters[attacker_index]
		if attacker.state != SimFighter.State.ACTIVE or attacker.has_hit:
			continue
		var defender_index := 1 - attacker_index
		var defender := fighters[defender_index]
		if defender.state == SimFighter.State.KO:
			continue
		if not _boxes_overlap(attacker.hitbox(), defender.hurtbox()):
			continue
		attacker.has_hit = true
		defender.health -= attacker.attack_damage
		if defender.health < 0:
			defender.health = 0
		var sign := 1 if defender.x >= attacker.x else -1
		defender.x += sign * attacker.attack_knockback
		defender.clear_move()
		defender.state = SimFighter.State.HITSTUN
		defender.state_tick = attacker.attack_hitstun
		events.append(
			SimEvent.make(
				SimEvent.Kind.HIT,
				attacker_index,
				defender_index,
				attacker.attack_damage,
				round_index,
				-1
			)
		)
		if defender.health <= 0:
			defender.state = SimFighter.State.KO
			defender.state_tick = 0
			events.append(
				SimEvent.make(
					SimEvent.Kind.KO, defender_index, attacker_index, 0, round_index, attacker_index
				)
			)


func _boxes_overlap(a: Array, b: Array) -> bool:
	if int(a[0]) + int(a[2]) <= int(b[0]):
		return false
	if int(b[0]) + int(b[2]) <= int(a[0]):
		return false
	if int(a[1]) + int(a[3]) <= int(b[1]):
		return false
	if int(b[1]) + int(b[3]) <= int(a[1]):
		return false
	return true


func _finish_round(events: Array) -> void:
	if phase != PHASE_FIGHTING:
		return
	var dead := 0
	var survivor := -1
	for index in fighters.size():
		if fighters[index].health <= 0:
			dead += 1
		else:
			survivor = index
	if dead > 0:
		var winner := -1 if dead >= 2 or survivor < 0 else survivor
		_close_round(events, winner)
		return
	if round_tick < round_ticks:
		return
	var winner_on_time := -1
	if fighters[0].health > fighters[1].health:
		winner_on_time = 0
	elif fighters[1].health > fighters[0].health:
		winner_on_time = 1
	_close_round(events, winner_on_time)


func _close_round(events: Array, winner: int) -> void:
	events.append(SimEvent.make(SimEvent.Kind.ROUND_END, -1, -1, 0, round_index, winner))
	if winner < 0:
		if draw_uses < draw_replays:
			draw_uses += 1
			_reset_bodies()
			events.append(SimEvent.make(SimEvent.Kind.ROUND_START, -1, -1, 0, round_index, -1))
			return
		# The first unused draw is replayed. The next tied timeout takes one
		# range_i(0, 2) from the match RNG and that fighter wins the round.
		winner = rng.range_i(0, 2)
		draw_uses = 0
	else:
		draw_uses = 0
	wins[winner] += 1
	if wins[winner] >= rounds_to_win:
		phase = PHASE_MATCH_OVER
		events.append(SimEvent.make(SimEvent.Kind.MATCH_END, winner, -1, 0, round_index, winner))
		return
	round_index += 1
	_reset_bodies()
	events.append(SimEvent.make(SimEvent.Kind.ROUND_START, -1, -1, 0, round_index, winner))


func _reset_bodies() -> void:
	round_tick = 0
	for index in fighters.size():
		var fighter := fighters[index]
		fighter.x = spawn_x[index]
		fighter.y = floor_y
		fighter.health = max_health
		fighter.state = SimFighter.State.IDLE
		fighter.state_tick = 0
		fighter.blocking = false
		fighter.facing = 1 if index == 0 else -1
		fighter.clear_move()
