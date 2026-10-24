@tool
extends SceneTree

const FIGHTERS = ["theron", "atalanta", "pyrrhus", "sibyl"]
const ACTIONS = [
	"idle",
	"walk",
	"run",
	"jab_of_hermes",
	"cyclops_smash",
	"pegasus_kick",
	"block",
	"stagger",
	"ko"
]


func _init() -> void:
	call_deferred("_generate")


func _generate() -> void:
	var sub_viewport := SubViewport.new()
	sub_viewport.size = Vector2i(400, 400)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sub_viewport)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.1, 2.4)
	camera.current = true
	sub_viewport.add_child(camera)

	var light := DirectionalLight3D.new()
	light.position = Vector3(1, 3, 2)
	light.rotation_degrees = Vector3(-45, 30, 0)
	sub_viewport.add_child(light)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.12, 0.12, 0.15)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.environment = environment
	sub_viewport.add_child(env)

	var dir := DirAccess.open("res://docs/playtest/anim")
	if dir == null:
		DirAccess.make_dir_recursive_absolute("res://docs/playtest/anim")

	for fighter_id in FIGHTERS:
		print("Generating shots for: ", fighter_id)
		var rig := FighterRig.new()
		rig.load_fighter(fighter_id)
		sub_viewport.add_child(rig)
		var driver := PoseDriver.new()
		driver.setup(rig)

		var sheet_image := Image.create(400 * 3, 400 * 3, false, Image.FORMAT_RGBA8)
		sheet_image.fill(Color(0.1, 0.1, 0.12))

		var config := MatchConfig.new()
		config.fighter_ids = [fighter_id, "atalanta"]
		var world := MatchLauncher.make_world(config)
		var fighter := world.fighters[0]

		for action_idx in ACTIONS.size():
			var action_name: String = ACTIONS[action_idx]
			fighter.clear_move()
			fighter.blocking = action_name == "block"
			fighter.state = SimFighter.State.IDLE

			if action_name == "walk":
				fighter.state = SimFighter.State.WALK
			elif action_name == "run":
				fighter.state = SimFighter.State.WALK
				fighter.speed = 40
			elif action_name == "block":
				fighter.state = SimFighter.State.BLOCKSTUN
			elif action_name == "stagger":
				fighter.state = SimFighter.State.STAGGER
			elif action_name == "ko":
				fighter.state = SimFighter.State.KO
			else:
				for m in world.moves:
					if m["id"] == action_name:
						fighter.begin_move(1, m, 1, 1)
						fighter.state = SimFighter.State.ACTIVE
						fighter.state_tick = fighter.startup_ticks
						break

			driver.update(fighter)

			await RenderingServer.frame_post_draw

			var shot := sub_viewport.get_texture().get_image()
			var single_path := "res://docs/playtest/anim/%s_%s.png" % [fighter_id, action_name]
			shot.save_png(ProjectSettings.globalize_path(single_path))

			var col := action_idx % 3
			var row := action_idx / 3
			sheet_image.blit_rect(shot, Rect2i(0, 0, 400, 400), Vector2i(col * 400, row * 400))

		var sheet_path := "res://docs/playtest/anim/contact_sheet_%s.png" % fighter_id
		sheet_image.save_png(ProjectSettings.globalize_path(sheet_path))
		rig.free()

	sub_viewport.free()
	print("ALL_SHEETS_GENERATED_OK")
	quit(0)
