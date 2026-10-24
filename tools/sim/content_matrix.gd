extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var launcher = load("res://src/presentation/match_launcher.gd")
	var count := 0
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		for arena in ["mount_olympus", "athens_colosseum", "tartarus_pits"]:
			var config := MatchConfig.new()
			config.fighter_ids = [id, "atalanta"]
			config.arena_id = arena
			for mask in 16:
				for replacement in [
					"",
					"rubber_chicken_arm",
					"cyclops_giant_hand",
					"crab_claw_arm",
					"marble_statue_leg",
					"hermes_sandal_leg"
				]:
					var world = launcher.make_world(config)
					SimBodyState.apply_mask(world.fighters[0], mask)
					if replacement != "":
						var slot := "leg_l" if replacement.ends_with("leg") else "arm_l"
						world.fighters[0].limbs.parts[slot].state = "severed"
						world.fighters[0].limbs.regrow(slot, replacement)
					for tick in 90:
						world.step([2 if tick < 30 else 16, 1 if tick < 30 else 64])
						for fighter in world.fighters:
							if fighter.health < 0 or fighter.limbs.losses > 2:
								quit(1)
								return
					count += 1
	print("CONTENT_MATRIX_OK cases=", count)
	quit(0)
