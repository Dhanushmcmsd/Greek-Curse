class_name SimFighter
extends RefCounted
## Integer body on the lane. x and y are millimetres. Depth does not exist here.

enum State { IDLE, WALK, STARTUP, ACTIVE, RECOVERY, HITSTUN, KO }

const STATE_NAMES: Array[String] = [
	"idle", "walk", "startup", "active", "recovery", "hitstun", "ko"
]

var fighter_id: String = ""
var display_name: String = ""
var x: int = 0
var y: int = 0
var facing: int = 1
var walk_speed: int = 0
var power_percent: int = 100
var height_mm: int = 1000
var body_width_mm: int = 400
var reach: int = 1
var limb_toughness: int = 1
var health: int = 300
var stamina: int = 0
var state: int = State.IDLE
var state_tick: int = 0
var move_age: int = 0
var move_id: int = 0
var move_name: String = ""
var has_hit: bool = false
var blocking: bool = false
var startup_ticks: int = 0
var active_ticks: int = 0
var recovery_ticks: int = 0
var hitstun_ticks: int = 0
var attack_damage: int = 0
var attack_hitstun: int = 0
var attack_knockback: int = 0
var attack_hop: int = 0
var hit_x: int = 0
var hit_y: int = 0
var hit_w: int = 0
var hit_h: int = 0


func half_width() -> int:
	return body_width_mm / 2


func state_name() -> String:
	if state < 0 or state >= STATE_NAMES.size():
		return "unknown"
	return STATE_NAMES[state]


func begin_move(index: int, move: Dictionary, scaled_damage: int) -> void:
	state = State.STARTUP
	state_tick = 0
	move_age = 0
	move_id = index
	move_name = str(move["id"])
	has_hit = false
	startup_ticks = int(move["startup_ticks"])
	active_ticks = int(move["active_ticks"])
	recovery_ticks = int(move["recovery_ticks"])
	attack_damage = scaled_damage
	attack_hitstun = int(move["hitstun_ticks"])
	attack_knockback = int(move["knockback_mm"])
	attack_hop = int(move["hop_mm_per_tick"])
	var box: Dictionary = move["hitbox"]
	hit_x = int(box["x"])
	hit_y = int(box["y"])
	hit_w = int(box["w"])
	hit_h = int(box["h"])


func clear_move() -> void:
	move_id = 0
	move_name = ""
	move_age = 0
	has_hit = false
	startup_ticks = 0
	active_ticks = 0
	recovery_ticks = 0
	attack_damage = 0
	attack_hitstun = 0
	attack_knockback = 0
	attack_hop = 0


func hurtbox() -> Array:
	return [x - half_width(), y, body_width_mm, height_mm]


func hitbox() -> Array:
	var left := x + hit_x
	if facing < 0:
		left = x - hit_x - hit_w
	return [left, y + hit_y, hit_w, hit_h]
