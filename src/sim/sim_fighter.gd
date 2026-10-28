class_name SimFighter
extends RefCounted
## Integer body on the lane. x and y are millimetres. Depth does not exist here.

enum State {
	IDLE,
	WALK,
	STARTUP,
	ACTIVE,
	RECOVERY,
	HITSTUN,
	KO,
	STAGGER,
	DODGE,
	GRAB,
	GRABBED,
	BLOCKSTUN,
}

const STATE_NAMES: Array[String] = [
	"idle",
	"walk",
	"startup",
	"active",
	"recovery",
	"hitstun",
	"ko",
	"stagger",
	"dodge",
	"grab",
	"grabbed",
	"blockstun",
]
const POSE_IDS := {"standing": 0, "crouch": 1, "hop": 2, "crawl": 3, "torso": 4}

var loadout: Dictionary = {}
var moveset_aliases: Dictionary = {}
var ability_cooldowns: Dictionary = {}
var ability_uses: Dictionary = {}
var invulnerable_until: int = 0
var shield: int = 0
var shield_burst: int = 0
var passive_limb_percent: int = 100
var passive_speed_percent: int = 100
var frenzy_maximum: int = 100
var fighter_id: String = ""
var display_name: String = ""
var x: int = 0
var y: int = 0
var launched: bool = false
var launch_velocity: int = 0
var knockback_velocity: int = 0
var juggle_hits: int = 0
var wall_bounced: bool = false
var facing: int = 1
var walk_speed: int = 0
var power_percent: int = 100
var height_mm: int = 1000
var body_width_mm: int = 400
var reach: int = 1
var reach_percent: int = 100
var knockback_percent: int = 100
var limb_toughness: int = 1
var health: int = 300
var stamina: int = 0
var stamina_max: int = 100
var meter: int = 0
var modifiers: Array[SimModifier] = []
var attack_slot: String = "arm_l"
var attack_category: String = ""
var landed_hit: bool = false
var pose: String = "standing"
var state: int = State.IDLE
var state_tick: int = 0
var move_age: int = 0
var move_id: int = 0
var move_name: String = ""
var has_hit: bool = false
var hits_done: int = 0
var next_hit_age: int = 0
var blocking: bool = false
var armor_hits: int = 0
var cooldown_ticks: int = 0
var attack_rearm_ticks: int = 0
var chain: ChainRecord = ChainRecord.new()
var startup_ticks: int = 0
var active_ticks: int = 0
var recovery_ticks: int = 0
var attack_damage: int = 0
var attack_limb_damage: int = 0
var attack_hitstun: int = 0
var attack_blockstun: int = 0
var attack_knockback: int = 0
var attack_block_push: int = 0
var attack_hop: int = 0
var attack_hitstop_self: int = 0
var attack_hitstop_other: int = 0
var attack_hit_count: int = 1
var attack_hit_interval: int = 0
var attack_launch_y: int = 0
var attack_unblockable: bool = false
var attack_is_grab: bool = false
var attack_wall_bounce: bool = false
var attack_can_cancel: bool = false
var cancel_start: int = 0
var cancel_end: int = 0
var cancel_into: Array[String] = []
var hit_x: int = 0
var hit_y: int = 0
var hit_w: int = 0
var hit_h: int = 0
var limbs: SimLimbs = SimLimbs.new()
var buffer: SimInputBuffer = SimInputBuffer.new()


func half_width() -> int:
	return body_width_mm / 2


func state_name() -> String:
	if state < 0 or state >= STATE_NAMES.size():
		return "unknown"
	return STATE_NAMES[state]


func pose_id() -> int:
	return int(POSE_IDS.get(pose, 0))


func begin_move(index: int, move: Dictionary, scaled_damage: int, scaled_limb: int) -> void:
	landed_hit = false
	state = State.STARTUP
	state_tick = 0
	move_age = 0
	move_id = index
	move_name = str(move["id"])
	has_hit = false
	hits_done = 0
	next_hit_age = 0
	startup_ticks = int(move["startup_ticks"])
	active_ticks = int(move["active_ticks"])
	recovery_ticks = int(move["recovery_ticks"])
	attack_damage = scaled_damage
	attack_limb_damage = scaled_limb
	attack_hitstun = int(move["hitstun_ticks"])
	attack_blockstun = int(move.get("blockstun_ticks", 0))
	attack_knockback = int(move["knockback_mm"])
	attack_block_push = int(move.get("on_block_pushback", 0))
	attack_hop = int(move["hop_mm_per_tick"])
	attack_hitstop_self = int(move.get("hitstop_attacker", 0))
	attack_hitstop_other = int(move.get("hitstop_defender", 0))
	attack_hit_count = int(move.get("hit_count", 1))
	attack_hit_interval = int(move.get("hit_interval", 0))
	attack_launch_y = int(move.get("launch_y", 0))
	attack_unblockable = bool(move.get("unblockable", false))
	attack_is_grab = bool(move.get("is_grab", false))
	attack_wall_bounce = bool(move.get("wall_bounce", false))
	attack_can_cancel = bool(move.get("can_cancel", false))
	cancel_start = int(move.get("cancel_start", 0))
	cancel_end = int(move.get("cancel_end", 0))
	armor_hits = int(move.get("armor_hits", 0))
	cancel_into = []
	for entry in move.get("cancel_into", []):
		cancel_into.append(str(entry))
	var box: Dictionary = move["hitbox"]
	hit_x = int(box["x"])
	hit_y = int(box["y"])
	hit_w = int(box["w"])
	hit_h = int(box["h"])


func clear_move() -> void:
	landed_hit = false
	attack_category = ""
	move_id = 0
	move_name = ""
	move_age = 0
	has_hit = false
	hits_done = 0
	next_hit_age = 0
	armor_hits = 0
	startup_ticks = 0
	active_ticks = 0
	recovery_ticks = 0
	attack_damage = 0
	attack_limb_damage = 0
	attack_hitstun = 0
	attack_blockstun = 0
	attack_knockback = 0
	attack_block_push = 0
	attack_hop = 0
	attack_hitstop_self = 0
	attack_hitstop_other = 0
	attack_hit_count = 1
	attack_hit_interval = 0
	attack_launch_y = 0
	attack_unblockable = false
	attack_is_grab = false
	attack_wall_bounce = false
	attack_can_cancel = false
	cancel_start = 0
	cancel_end = 0
	cancel_into = []


func hurtbox() -> Array:
	return [x - half_width(), y, body_width_mm, height_mm]


func hitbox() -> Array:
	var left := x + hit_x
	if facing < 0:
		left = x - hit_x - hit_w
	return [left, y + hit_y, hit_w, hit_h]


func in_dodge_iframe(iframe_start: int, iframe_end: int) -> bool:
	return state == State.DODGE and state_tick >= iframe_start and state_tick < iframe_end
