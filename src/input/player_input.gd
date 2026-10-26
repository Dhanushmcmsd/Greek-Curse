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
	"kick_right": SimInput.KICK_RIGHT,
	"body": SimInput.BODY,
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


func sample(player: int, source: String = "all") -> int:
	toggle_block = bool(SettingsHooks.get_value("toggle_block"))
	var mask := 0
	for action in BITS:
		var name := "p%d_%s" % [player + 1, action]
		if not InputMap.has_action(name):
			continue
		for event in InputMap.action_get_events(name):
			if (
				source != "pad"
				and event is InputEventKey
				and Input.is_physical_key_pressed(event.physical_keycode)
			):
				mask |= int(BITS[action])
			if (
				source != "keyboard"
				and event is InputEventJoypadButton
				and Input.is_joy_button_pressed(player, event.button_index)
			):
				mask |= int(BITS[action])
	if source != "keyboard":
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
