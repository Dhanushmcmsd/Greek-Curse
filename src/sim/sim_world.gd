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
var combat: Dictionary = {}
var limb_rules: Dictionary = {}
var body_rules: Dictionary = {}
var amputations: Array = []
var hitstop_remaining: int = 0
var rng: SimRng = SimRng.new(1)


static func from_data(
	rules: Dictionary,
	curves: Dictionary,
	fighter_rows: Array,
	move_rows: Array,
	combat_row: Dictionary,
	seed_value: int = 1,
	limb_row: Dictionary = {}
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
	world.combat = combat_row
	world.limb_rules = limb_row
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
	fighter.stamina_max = stamina_value
	fighter.limbs.setup(row, limb_rules, fighter.limb_toughness)
	fighter.limbs.rules = limb_rules
	fighter.limbs.modifiers = fighter.modifiers
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
	var window := int(combat["input_buffer_ticks"])
	for index in fighters.size():
		fighters[index].buffer.push(masks[index], tick, window)
	if hitstop_remaining > 0:
		hitstop_remaining -= 1
		_finish_round(events)
		return events
	for index in fighters.size():
		SimMovement.advance(self, fighters[index], masks[index])
		SimRegrown.after_movement(self, fighters[index], events)
	_face()
	_separate()
	SimCombat.resolve(self, events)
	_separate()
	_face()
	for fighter in fighters:
		SimStamina.regen(fighter, combat)
	_finish_round(events)
	return events


func hash_state() -> int:
	return snapshot_hash()


func snapshot_hash() -> int:
	var values: Array = [
		tick,
		round_tick,
		phase,
		round_index,
		wins[0],
		wins[1],
		draw_uses,
		rng.get_state(),
		hitstop_remaining,
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
					fighter.meter,
					fighter.pose_id(),
					fighter.cooldown_ticks,
					fighter.armor_hits,
					fighter.hits_done,
				]
			)
		)
		values.append_array(fighter.limbs.hash_values())
		values.append_array(fighter.chain.hash_values())
		values.append_array(fighter.buffer.hash_values())
		values.append(StateHash.hash_string(fighter.attack_slot))
		values.append(StateHash.hash_string(fighter.attack_category))
		values.append(int(fighter.landed_hit))
		values.append(fighter.modifiers.size())
		for modifier in fighter.modifiers:
			values.append_array(
				[
					StateHash.hash_string(modifier.id),
					modifier.expires_tick,
					modifier.damage_percent,
					modifier.speed_percent
				]
			)
	for record in amputations:
		values.append_array(
			[
				StateHash.hash_string(record["limb"]),
				record["attacker"],
				record["victim"],
				record["tick"],
				record["chain_hits"]
			]
		)
	return StateHash.hash_ints(values)


func setup(match_config: Dictionary) -> void:
	var initial: Array = match_config.get("initial_limb_states", [])
	for index in mini(initial.size(), fighters.size()):
		fighters[index].limbs.restore_state(initial[index])


func export_limb_state() -> Array:
	var result: Array = []
	for fighter in fighters:
		result.append(fighter.limbs.export_state())
	return result


func reset_for_match(mode: String) -> void:
	tick = 0
	round_index = 1
	phase = PHASE_FIGHTING
	wins = [0, 0]
	draw_uses = 0
	amputations = []
	for fighter in fighters:
		fighter.modifiers.clear()
		var rows := fighter.limbs.export_state() if mode == "career" else {}
		if mode != "career":
			for zone in SimLimbs.LIMB_NAMES:
				rows[zone] = {"integrity": fighter.limbs.max_integrity}
		fighter.limbs.restore_state(rows)
		fighter.meter = 0
	_reset_bodies()


func _mask_at(inputs: Array, index: int) -> int:
	if index >= inputs.size():
		return 0
	return int(inputs[index])


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


func _low(fighter: SimFighter) -> int:
	return arena_min_x + fighter.half_width()


func _high(fighter: SimFighter) -> int:
	return arena_max_x - fighter.half_width()


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
		fighter.stamina = fighter.stamina_max
		fighter.y = floor_y
		fighter.pose = "standing"
		fighter.cooldown_ticks = 0
		fighter.chain = ChainRecord.new()
		fighter.buffer = SimInputBuffer.new()
		fighter.state = SimFighter.State.IDLE
		fighter.state_tick = 0
		fighter.blocking = false
		fighter.facing = 1 if index == 0 else -1
		fighter.clear_move()
	hitstop_remaining = 0
