extends TestBase


func _service() -> CareerService:
	var service := CareerService.new()
	service.setup("user://")
	service.save.path = "user://career_test.json"
	service.data = {}
	assert_eq(service.create("theron", "Test Hero", "default", "2026-10-24"), "", "create")
	return service


func test_save_roundtrip_interruption_backup_and_migration() -> void:
	var service := _service()
	var old := service.data.duplicate(true)
	assert_eq(service.save.load_data(), old, "round trip")
	service.data["fighter"]["win_count"] = 7
	assert_eq(service.save.save_data(service.data, true), ERR_BUSY, "interrupted before commit")
	assert_eq(service.save.load_data(), old, "previous file intact")
	assert_eq(service.save.save_data(service.data), OK, "atomic replace")
	var file := FileAccess.open(service.save.path, FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	assert_eq(service.save.load_data(), old, "backup recovery")
	assert_true(service.save.recovery.contains("Recovered"), "recovery message")
	old["version"] = 1
	assert_eq(service.save.migrate(old)["version"], 2, "migration")


func test_guaranteed_offers_and_trade_invariants() -> void:
	var service := _service()
	for win in [1, 3, 5]:
		var offers := UnlockOffers.choose(service.catalog, Loadout.STARTER, win, 16)
		assert_eq(
			offers,
			UnlockOffers.choose(service.catalog, Loadout.STARTER, win, 16),
			"deterministic offers"
		)
		assert_eq(
			service.catalog[offers[0]]["type"],
			{1: "superpower", 3: "passive", 5: "ultimate"}[win],
			"guaranteed type"
		)
	var fighter: Dictionary = service.data["fighter"]
	fighter["unlocked_abilities"].append("zeus_bolt")
	fighter["loadout"]["superpower"] = ["zeus_bolt"]
	fighter["limbs"]["arm_l"]["state"] = "severed"
	fighter["limbs"]["arm_l"]["integrity"] = 0
	assert_eq(
		ObolTrade.options(fighter, "arm_l", "jab_of_hermes", service.limbs, 1),
		[],
		"starter protected"
	)
	var before := fighter.duplicate(true)
	var options := ObolTrade.options(fighter, "arm_l", "zeus_bolt", service.limbs, 1)
	assert_eq(options.size(), 3, "three fitting arms")
	assert_eq(fighter, before, "decline/read options unchanged")
	assert_true(
		ObolTrade.accept(fighter, "arm_l", "zeus_bolt", options[0], service.limbs, 147, 1),
		"valid trade"
	)
	assert_false("zeus_bolt" in fighter["unlocked_abilities"], "ability leaves pool")
	assert_eq(fighter["loadout"]["superpower"], [], "ability unequipped")
	assert_eq(fighter["limbs"]["arm_l"]["integrity"], 118, "80 percent rounded")


func test_ten_thousand_seeded_progression_events() -> void:
	var service := _service()
	var fighter: Dictionary = service.data["fighter"]
	var rng := SimRng.new(901)
	for index in 10000:
		var offers := UnlockOffers.choose(
			service.catalog, fighter["unlocked_abilities"], index + 1, rng.next_u32()
		)
		if not offers.is_empty():
			var selected: String = offers[rng.range_i(0, offers.size())]
			fighter["unlocked_abilities"].append(selected)
			fighter["traded_abilities"].erase(selected)
		var tradable: Array = fighter["unlocked_abilities"].filter(
			func(id): return id not in Loadout.STARTER
		)
		if not tradable.is_empty():
			var slot: String = SimLimbs.LIMB_NAMES[index % 4]
			fighter["limbs"][slot]["state"] = "severed"
			fighter["limbs"][slot]["integrity"] = 0
			var options := ObolTrade.options(fighter, slot, tradable[0], service.limbs, index + 1)
			assert_true(
				ObolTrade.accept(
					fighter, slot, tradable[0], options[0], service.limbs, 147, index + 1
				),
				"fuzz trade"
			)
		assert_eq(
			Loadout.validate(fighter["loadout"], fighter["unlocked_abilities"], service.catalog),
			"",
			"loadout invariant"
		)
	print("CAREER_FUZZ_OK iterations=10000 seed=901")


func test_structurally_corrupt_save_rejected_before_ui() -> void:
	var service := _service()
	var broken := service.data.duplicate(true)
	broken["fighter"].erase("name")
	assert_true(service.save.validate(broken) != "", "missing identity")
	broken = service.data.duplicate(true)
	broken["fighter"]["limbs"]["arm_l"]["regrown_id"] = "hermes_sandal_leg"
	assert_true(service.save.validate(broken) != "", "incompatible replacement")
	broken = service.data.duplicate(true)
	broken["chronicle"]["matches"].append({})
	assert_true(service.save.validate(broken) != "", "invalid history")
