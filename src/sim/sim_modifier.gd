class_name SimModifier
extends RefCounted
## Tick-based reusable modifiers. Half-open lifetime includes hit-stop.

var id: String = ""
var expires_tick: int = 0
var damage_percent: int = 100
var speed_percent: int = 100


static func percent_for(fighter: SimFighter, tick: int, speed: bool = false) -> int:
	var percent := 100
	for modifier in fighter.modifiers:
		if tick < modifier.expires_tick:
			percent = Fx.percent(
				percent, modifier.speed_percent if speed else modifier.damage_percent
			)
	return percent


static func fury(fighter: SimFighter, tick: int, rules: Dictionary) -> void:
	var found: SimModifier
	for modifier in fighter.modifiers:
		if modifier.id == "desperate_fury":
			found = modifier
	if found == null:
		found = SimModifier.new()
		found.id = "desperate_fury"
		fighter.modifiers.append(found)
	found.expires_tick = tick + int(rules["fury_ticks"])
	found.damage_percent = int(rules["fury_damage_percent"])
	found.speed_percent = int(rules["fury_speed_percent"])
