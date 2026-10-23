class_name PlayerInput
extends RefCounted

const BITS := {
	"left": SimInput.LEFT,
	"right": SimInput.RIGHT,
	"up": SimInput.UP,
	"down": SimInput.DOWN,
	"light": SimInput.LIGHT,
	"heavy": SimInput.HEAVY,
	"kick": SimInput.KICK,
	"block": SimInput.BLOCK,
	"dodge": SimInput.DODGE,
	"super": SimInput.SUPER,
	"ultimate": SimInput.ULTIMATE
}

var toggle_block: bool = false
var block_latched: bool = false
var previous: int = 0


func transform(mask: int) -> int:
	if toggle_block:
		if mask & SimInput.BLOCK and not previous & SimInput.BLOCK:
			block_latched = not block_latched
		previous = mask
		mask &= ~SimInput.BLOCK
		if block_latched:
			mask |= SimInput.BLOCK
	return mask


func sample(player: int) -> int:
	var mask := 0
	for action in BITS:
		var name := "p%d_%s" % [player + 1, action]
		if InputMap.has_action(name) and Input.is_action_pressed(name):
			mask |= int(BITS[action])
	var axis := Input.get_joy_axis(player, JOY_AXIS_LEFT_X)
	if axis < -0.5:
		mask |= SimInput.LEFT
	elif axis > 0.5:
		mask |= SimInput.RIGHT
	if Input.get_joy_axis(player, JOY_AXIS_LEFT_Y) > 0.5:
		mask |= SimInput.DOWN
	if Input.get_joy_axis(player, JOY_AXIS_TRIGGER_LEFT) > 0.5:
		mask |= SimInput.SUPER
		if Input.get_joy_axis(player, JOY_AXIS_TRIGGER_RIGHT) > 0.5:
			mask |= SimInput.ULTIMATE
	return transform(mask)
