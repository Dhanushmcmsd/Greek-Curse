class_name FlowAutoplay
extends RefCounted


static func run(host: MenuHost, career_mode: bool) -> void:
	if not "--user-profile" in OS.get_cmdline_user_args():
		_fail(host, "Autoplay requires an isolated --user-profile directory.")
		return
	while Router.state in ["age_gate", "content_warning"]:
		if Router.state == "age_gate":
			Settings.set_value("age_gate_accepted", true)
			Router.transition("content_warning")
		else:
			Settings.set_value("content_warning_seen", true)
			Router.transition("main_menu")
	await host.get_tree().process_frame
	if career_mode:
		Router.transition("career_hub")
		if not Router.career.data.get("fighter", {}).is_empty():
			Router.career.retire()
		Router.transition("fighter_create")
		var error := Router.career.create("theron", "Autoplay Hero", "default", "2026-10-24")
		if error != "":
			_fail(host, error)
			return
		Router.transition("career_hub")
		Router.prepare_career()
	else:
		Router.setup_mode("practice")
		Router.transition("match_banner")
	Router.config.controllers = ["ai_hard", "ai_easy"]
	Router.transition("match")
	await host.get_tree().process_frame
	var battle := host.battle
	battle.set_physics_process(false)
	for tick in 40000:
		if battle.world.phase == 1:
			break
		battle._consume(battle.world.step(battle._read_inputs()))
	if battle.world.phase != 1:
		_fail(host, "Match did not finish")
		return
	var summary := battle.result_summary()
	if career_mode:
		# Explicit fixture win/sever for testing offers and trade, not player progress.
		summary["won"] = true
		summary["limbs"]["arm_l"]["state"] = "severed"
		summary["limbs"]["arm_l"]["integrity"] = 0
	Router.finish(summary)
	Router.result_continue()
	if career_mode:
		var fighter: Dictionary = Router.career.data["fighter"]
		var ability: String = fighter["offers_state"][0]
		Router.career.pick_offer(ability)
		Router.transition("career_hub")
		Router.transition("obol")
		var options := ObolTrade.options(
			fighter,
			"arm_l",
			ability,
			Router.career.limbs,
			int(Router.career.data["rng_seed_counter"])
		)
		if (
			options.is_empty()
			or not ObolTrade.accept(
				fighter,
				"arm_l",
				ability,
				options[0],
				Router.career.limbs,
				147,
				int(Router.career.data["rng_seed_counter"])
			)
		):
			_fail(host, "Trade failed")
			return
		Router.career.save.save_data(Router.career.data)
		var before := Router.career.data.duplicate(true)
		Router.career.data = Router.career.save.load_data()
		if Router.career.data != before:
			_fail(host, "Reload mismatch")
			return
		Router.transition("career_hub")
	var file := FileAccess.open(
		Settings.path.get_base_dir().path_join("smoke_result.json"), FileAccess.WRITE
	)
	file.store_string(
		JSON.stringify(
			{
				"ok": true,
				"career": career_mode,
				"ticks": battle.world.tick if is_instance_valid(battle) else 0,
				"state": Router.state
			}
		)
	)
	file.close()
	print("FLOW_SMOKE_OK career=", career_mode)
	Audio.shutdown()
	await host.get_tree().create_timer(0.15).timeout
	await host.get_tree().process_frame
	host.get_tree().quit.call_deferred(0)


static func _fail(host: MenuHost, message: String) -> void:
	push_error(message)
	host.get_tree().quit(1)
