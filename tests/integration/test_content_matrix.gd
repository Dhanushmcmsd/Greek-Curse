extends TestBase


func test_content_matrix_reduced_or_slow() -> void:
	var full := "slow" in OS.get_cmdline_user_args()
	var count := 0
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		for arena in ["mount_olympus", "athens_colosseum", "tartarus_pits"]:
			for mask in range(16) if full else [0, 3, 12, 15]:
				for replacement in (
					[
						"",
						"rubber_chicken_arm",
						"cyclops_giant_hand",
						"crab_claw_arm",
						"marble_statue_leg",
						"hermes_sandal_leg"
					]
					if full
					else ["", "crab_claw_arm", "hermes_sandal_leg"]
				):
					var config := MatchConfig.new()
					config.fighter_ids = [id, "atalanta"]
					config.arena_id = arena
					var world := MatchLauncher.make_world(config)
					SimBodyState.apply_mask(world.fighters[0], mask)
					if replacement != "":
						var slot := "leg_l" if replacement.ends_with("leg") else "arm_l"
						world.fighters[0].limbs.parts[slot].state = "severed"
						world.fighters[0].limbs.regrow(slot, replacement)
					for tick in 90:
						world.step([2 if tick < 30 else 16, 1 if tick < 30 else 64])
					for fighter in world.fighters:
						assert_true(
							fighter.health >= 0 and fighter.limbs.losses <= 2, "matrix invariant"
						)
					count += 1
	print("CONTENT_MATRIX_OK cases=", count)
