class_name SimStamina
extends RefCounted
## Pool, spend, regen, and the empty-bar stagger.


static func regen(fighter: SimFighter, combat: Dictionary) -> void:
	if fighter.state == SimFighter.State.KO or fighter.state == SimFighter.State.STAGGER:
		return
	fighter.stamina = mini(
		fighter.stamina_max, fighter.stamina + int(combat["stamina_regen_per_tick"])
	)


static func try_spend(fighter: SimFighter, cost: int, combat: Dictionary) -> bool:
	if cost <= 0:
		return true
	if fighter.stamina < cost:
		fighter.stamina = 0
		begin_stagger(fighter, combat)
		return false
	fighter.stamina -= cost
	return true


static func begin_stagger(fighter: SimFighter, combat: Dictionary) -> void:
	fighter.clear_move()
	fighter.blocking = false
	fighter.state = SimFighter.State.STAGGER
	fighter.state_tick = int(combat["stagger_ticks"])
