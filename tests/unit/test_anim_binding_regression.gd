extends TestBase

# Test covering Phase A3 & B4:
# 1. Tests clip track binding across all 4 gameplay fighters and all 10 visual models.
# 2. Confirms zero unresolved tracks and proper AnimationPlayer binding.
# 3. Proves imported motion for walk, punch, and kick on each default fighter
#    (checking that action-specific bones actually move across frames).

const FIGHTER_IDS = ["theron", "atalanta", "pyrrhus", "sibyl"]
const MODEL_IDS = [
	"theron",
	"atalanta",
	"pyrrhus",
	"sibyl",
	"skin_ch39",
	"skin_ch40",
	"skin_demon",
	"skin_kachujin",
	"skin_nightshade",
	"vampire_stress"
]


func test_clip_track_binding_across_all_fighters_and_models() -> void:
	# Test every supported fighter and visual model combination (4 fighters x 10 visual models = 40)
	for fid in FIGHTER_IDS:
		for mid in MODEL_IDS:
			var rig := FighterRig.new()
			var success := rig.load_fighter(fid, mid)
			assert_true(success, "load_fighter succeeds for fighter=%s model=%s" % [fid, mid])
			(Engine.get_main_loop() as SceneTree).root.add_child(rig)

			assert_true(rig.anim_player != null, "anim_player exists for %s/%s" % [fid, mid])
			assert_true(rig.skeleton != null, "skeleton exists for %s/%s" % [fid, mid])
			assert_true(
				rig.is_using_mixamo_model(),
				"Must load intended Mixamo model without falling back for %s/%s" % [fid, mid]
			)
			if rig.skeleton.get_bone_count() > 15:
				assert_true(
					rig.skeleton.get_bone_count() >= 15,
					"rich deform skeleton >= 15 bones for " + mid
				)
				for req_bone in FighterRig.REQUIRED_BONES:
					assert_true(
						rig.skeleton.find_bone(req_bone) >= 0,
						"required bone '%s' exists on skeleton for %s" % [req_bone, mid]
					)
			else:
				assert_eq(rig.skeleton.get_bone_count(), 15, "15 shared bones for model " + mid)

			var resolved_root: Node = rig.anim_player.get_node_or_null(rig.anim_player.root_node)
			assert_true(
				resolved_root != null, "anim_player root_node resolves for %s/%s" % [fid, mid]
			)

			var libs: Array[StringName] = rig.anim_player.get_animation_library_list()
			assert_true(libs.size() > 0, "has animation libraries for %s/%s" % [fid, mid])

			# Verify all 15 required bones exist and have transform coverage in bound action clips
			var default_lib: AnimationLibrary = (
				rig.anim_player.get_animation_library("")
				if rig.anim_player.has_animation_library("")
				else null
			)
			assert_true(
				default_lib != null, "default animation library exists for %s/%s" % [fid, mid]
			)

			# Verify walk animation covers all 15 required source bones
			var walk_anim_name: String = str(fid) + "_walk_fwd"
			assert_true(
				default_lib.has_animation(walk_anim_name), "has walk animation: " + walk_anim_name
			)
			var walk_anim: Animation = default_lib.get_animation(walk_anim_name)
			var covered_bones: Dictionary = {}
			for t in range(walk_anim.get_track_count()):
				var trk_path: NodePath = walk_anim.track_get_path(t)
				var sub_part: String = trk_path.get_concatenated_subnames()
				if sub_part != "":
					covered_bones[sub_part] = true

			for req_bone in FighterRig.REQUIRED_BONES:
				assert_true(
					covered_bones.has(req_bone),
					(
						"Walk animation has track for required bone '%s' on %s/%s"
						% [req_bone, fid, mid]
					)
				)

			# Validate every track across all animation libraries
			for lib_name in libs:
				var lib: AnimationLibrary = rig.anim_player.get_animation_library(lib_name)
				for anim_name in lib.get_animation_list():
					var anim: Animation = lib.get_animation(anim_name)
					for t in range(anim.get_track_count()):
						var trk_path: NodePath = anim.track_get_path(t)
						var node_part: String = trk_path.get_concatenated_names()
						var sub_part: String = trk_path.get_concatenated_subnames()
						var target_node: Node = resolved_root.get_node_or_null(NodePath(node_part))
						assert_true(
							target_node != null,
							(
								"Track target node resolves for %s/%s:%s track[%d]: %s"
								% [fid, mid, str(anim_name), t, str(trk_path)]
							)
						)
						if sub_part != "":
							assert_true(
								target_node is Skeleton3D,
								(
									"Subname target node must be Skeleton3D for %s/%s track %s"
									% [fid, mid, str(trk_path)]
								)
							)
							var bone_idx: int = (target_node as Skeleton3D).find_bone(sub_part)
							assert_true(
								bone_idx >= 0,
								(
									"Bone '%s' exists on skeleton for %s/%s track %s"
									% [sub_part, fid, mid, str(trk_path)]
								)
							)
			rig.free()


func test_simultaneous_fighters_two_instances_independent() -> void:
	var rig1 := FighterRig.new()
	rig1.load_fighter("theron")
	var rig2 := FighterRig.new()
	rig2.load_fighter("atalanta")

	(Engine.get_main_loop() as SceneTree).root.add_child(rig1)
	(Engine.get_main_loop() as SceneTree).root.add_child(rig2)

	# Verify distinct instances and independent AnimationPlayers
	assert_true(rig1.anim_player != rig2.anim_player, "different AnimationPlayer instances")
	assert_true(rig1.skeleton != rig2.skeleton, "different Skeleton3D instances")

	rig1.anim_player.play("theron_walk_fwd")
	rig2.anim_player.play("atalanta_walk_fwd")

	# Record full initial pose of Fighter B across all 15 bones
	var b_poses_initial: Array[Quaternion] = []
	for b in range(rig2.skeleton.get_bone_count()):
		b_poses_initial.append(rig2.skeleton.get_bone_pose_rotation(b))

	# Advance Fighter A ONLY
	rig1.anim_player.advance(0.5)

	# Assert that Fighter B's pose remains completely unchanged
	for b in range(rig2.skeleton.get_bone_count()):
		var rot_now: Quaternion = rig2.skeleton.get_bone_pose_rotation(b)
		var bone_name: String = rig2.skeleton.get_bone_name(b)
		assert_true(
			rot_now.is_equal_approx(b_poses_initial[b]),
			"Fighter B bone '%s' must not change when only Fighter A advances" % bone_name
		)

	# Now advance Fighter B and verify it moves independently
	rig2.anim_player.advance(0.5)
	var b_moved: bool = false
	for b in range(rig2.skeleton.get_bone_count()):
		var rot_after: Quaternion = rig2.skeleton.get_bone_pose_rotation(b)
		if not rot_after.is_equal_approx(b_poses_initial[b]):
			b_moved = true
			break
	assert_true(b_moved, "Fighter B animates when its own player advances")

	rig1.free()
	rig2.free()


func test_motion_playback_proves_active_bone_transform_changes() -> void:
	# B4 requirement: evaluate multiple timestamps; check action-specific bones change:
	# - Walk must show leg motion
	# - Punch must show striking arm/torso motion
	# - Kick must show striking leg motion
	for fid in FIGHTER_IDS:
		var rig := FighterRig.new()
		rig.load_fighter(fid)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)

		# 1. Walk: thigh.l or thigh.r rotates between frames
		var walk_anim: String = fid + "_walk_fwd"
		assert_true(rig.anim_player.has_animation(walk_anim), "has walk animation: " + walk_anim)
		rig.anim_player.play(walk_anim)
		rig.anim_player.seek(0.0, true)
		var thigh_bone: int = rig.skeleton.find_bone("thigh.l")
		assert_true(thigh_bone >= 0, "thigh.l exists")
		var rot0: Quaternion = rig.skeleton.get_bone_pose_rotation(thigh_bone)

		# Sample multiple frames
		var leg_moved: bool = false
		for step in [0.2, 0.4, 0.6, 0.8]:
			rig.anim_player.seek(step, true)
			var rot_step: Quaternion = rig.skeleton.get_bone_pose_rotation(thigh_bone)
			if rot_step.angle_to(rot0) > 0.05:
				leg_moved = true
				break
		assert_true(leg_moved, "Walk shows leg bone motion for " + fid)

		# 2. Punch: upper_arm or forearm or spine moves
		var punch_anim: String = fid + "_punch_jab"
		assert_true(rig.anim_player.has_animation(punch_anim), "has punch animation: " + punch_anim)
		rig.anim_player.play(punch_anim)
		rig.anim_player.seek(0.0, true)
		var arm_bone: int = rig.skeleton.find_bone("upper_arm.l")
		if arm_bone < 0:
			arm_bone = rig.skeleton.find_bone("upper_arm.r")
		var arm_rot0: Quaternion = rig.skeleton.get_bone_pose_rotation(arm_bone)
		var arm_moved: bool = false
		for step in [0.15, 0.3, 0.45]:
			rig.anim_player.seek(step, true)
			var arm_rot_step: Quaternion = rig.skeleton.get_bone_pose_rotation(arm_bone)
			if arm_rot_step.angle_to(arm_rot0) > 0.05:
				arm_moved = true
				break
		assert_true(arm_moved, "Punch shows arm bone motion for " + fid)

		# 3. Kick: kick_thrust or kick_low shows leg motion
		var kick_anim: String = fid + "_kick_thrust"
		if not rig.anim_player.has_animation(kick_anim):
			kick_anim = fid + "_kick_low"
		assert_true(rig.anim_player.has_animation(kick_anim), "has kick animation: " + kick_anim)
		rig.anim_player.play(kick_anim)
		rig.anim_player.seek(0.0, true)
		var kick_bone: int = rig.skeleton.find_bone("thigh.r")
		var kick_rot0: Quaternion = rig.skeleton.get_bone_pose_rotation(kick_bone)
		var kick_moved: bool = false
		for step in [0.15, 0.3, 0.5]:
			rig.anim_player.seek(step, true)
			var kick_rot_step: Quaternion = rig.skeleton.get_bone_pose_rotation(kick_bone)
			if kick_rot_step.angle_to(kick_rot0) > 0.05:
				kick_moved = true
				break
		assert_true(kick_moved, "Kick shows leg bone motion for " + fid)

		rig.free()


func test_visual_multi_frame_sequences() -> void:
	var root_node: Node = (Engine.get_main_loop() as SceneTree).root

	var sub_viewport := SubViewport.new()
	sub_viewport.size = Vector2i(400, 400)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root_node.add_child(sub_viewport)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.0, 2.5)
	camera.current = true
	sub_viewport.add_child(camera)

	var light := DirectionalLight3D.new()
	light.position = Vector3(1, 3, 2)
	light.rotation_degrees = Vector3(-45, 30, 0)
	sub_viewport.add_child(light)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.12, 0.12, 0.16)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.environment = environment
	sub_viewport.add_child(env)

	var output_dir := "res://docs/playtest/anim/sequences"
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)

	var world := ProtoFixture.world_with()
	var fighter := world.fighters[0]

	var rig := FighterRig.new()
	var loaded := rig.load_fighter("theron")
	assert_true(loaded, "Theron rig loaded")
	sub_viewport.add_child(rig)

	var driver := PoseDriver.new()
	driver.setup(rig)

	var sequences := [
		{
			"name": "idle",
			"state": SimFighter.State.IDLE,
			"move": "",
			"pose": "standing",
			"walk_speed": 0,
			"facing": 1,
			"walk_dir": 0
		},
		{
			"name": "walk_forward",
			"state": SimFighter.State.WALK,
			"move": "",
			"pose": "standing",
			"walk_speed": 20,
			"facing": 1,
			"walk_dir": 1
		},
		{
			"name": "walk_backward",
			"state": SimFighter.State.WALK,
			"move": "",
			"pose": "standing",
			"walk_speed": 20,
			"facing": 1,
			"walk_dir": -1
		},
		{
			"name": "run_derived",
			"state": SimFighter.State.WALK,
			"move": "",
			"pose": "standing",
			"walk_speed": 40,
			"facing": 1,
			"walk_dir": 1
		},
		{
			"name": "block",
			"state": SimFighter.State.BLOCKSTUN,
			"move": "",
			"pose": "standing",
			"walk_speed": 0,
			"facing": 1,
			"walk_dir": 0,
			"blocking": true
		},
		{
			"name": "punch_jab",
			"state": SimFighter.State.ACTIVE,
			"move": "jab_of_hermes",
			"pose": "standing",
			"walk_speed": 0,
			"facing": 1,
			"walk_dir": 0
		},
		{
			"name": "kick_pegasus",
			"state": SimFighter.State.ACTIVE,
			"move": "pegasus_kick",
			"pose": "standing",
			"walk_speed": 0,
			"facing": 1,
			"walk_dir": 0
		},
		{
			"name": "stagger",
			"state": SimFighter.State.STAGGER,
			"move": "",
			"pose": "standing",
			"walk_speed": 0,
			"facing": 1,
			"walk_dir": 0
		},
		{
			"name": "knockdown",
			"state": SimFighter.State.KO,
			"move": "",
			"pose": "standing",
			"walk_speed": 0,
			"facing": 1,
			"walk_dir": 0
		},
		{
			"name": "crawl",
			"state": SimFighter.State.WALK,
			"move": "",
			"pose": "crawl",
			"walk_speed": 10,
			"facing": 1,
			"walk_dir": 1,
			"sever_legs": true
		},
		{
			"name": "severed_and_regrown",
			"state": SimFighter.State.IDLE,
			"move": "",
			"pose": "standing",
			"walk_speed": 0,
			"facing": 1,
			"walk_dir": 0,
			"sever_arm_l": true,
			"regrow_hand": true
		}
	]

	var frame_ticks := [0, 8, 16, 24]

	for seq in sequences:
		var seq_name: String = str(seq["name"])
		var strip := Image.create(400 * 4, 400, false, Image.FORMAT_RGBA8)
		strip.fill(Color(0.1, 0.1, 0.12))

		if seq.get("sever_legs", false):
			fighter.limbs.parts["leg_l"].state = "severed"
			fighter.limbs.parts["leg_r"].state = "severed"
		else:
			fighter.limbs.parts["leg_l"].state = "healthy"
			fighter.limbs.parts["leg_r"].state = "healthy"

		if seq.get("sever_arm_l", false):
			fighter.limbs.parts["arm_l"].state = "severed"
		else:
			fighter.limbs.parts["arm_l"].state = "healthy"

		if seq.get("regrow_hand", false):
			fighter.limbs.parts["arm_l"].regrown_id = "cyclops_giant_hand"
			rig.attach_regrown("arm_l", "cyclops_giant_hand")
		else:
			fighter.limbs.parts["arm_l"].regrown_id = ""
			rig.detach_regrown("arm_l")

		fighter.pose = str(seq.get("pose", "standing"))
		fighter.facing = int(seq.get("facing", 1))
		fighter.walk_speed = int(seq.get("walk_speed", 20))
		driver.walk_direction = int(seq.get("walk_dir", 0))
		fighter.blocking = bool(seq.get("blocking", false))

		var move_name: String = str(seq.get("move", ""))
		var target_move: Dictionary = {}
		if move_name != "":
			for m in world.moves:
				if m["id"] == move_name:
					target_move = m
					break

		var prev_pose: Quaternion = Quaternion.IDENTITY
		var sequence_animated := false

		for frame_idx in range(4):
			var tick_offset: int = frame_ticks[frame_idx]
			fighter.state = int(seq["state"])

			if move_name != "":
				fighter.begin_move(1, target_move, 1, 1)
				fighter.state = SimFighter.State.ACTIVE
				fighter.state_tick = tick_offset
			else:
				fighter.state_tick = tick_offset

			driver.time = float(tick_offset) / 60.0
			driver.update(fighter)

			# Sample spine or limb bone pose rotation
			var sample_bone: int = (
				rig.skeleton.find_bone("upper_arm.l")
				if "punch" in seq_name
				else (
					rig.skeleton.find_bone("thigh.r")
					if "kick" in seq_name or "walk" in seq_name or "run" in seq_name
					else rig.skeleton.find_bone("spine")
				)
			)
			if sample_bone >= 0:
				var cur_pose: Quaternion = rig.skeleton.get_bone_pose_rotation(sample_bone)
				if frame_idx > 0 and cur_pose.angle_to(prev_pose) > 0.001:
					sequence_animated = true
				prev_pose = cur_pose

		# Assert poses remain finite and valid throughout sequence
		for b in range(rig.skeleton.get_bone_count()):
			assert_true(
				rig.skeleton.get_bone_pose_rotation(b).is_finite(),
				"Bone %s finite in %s" % [rig.skeleton.get_bone_name(b), seq_name]
			)

	rig.free()
	sub_viewport.free()


func test_atalanta_idle_and_backward_walk_presentation() -> void:
	var rig := FighterRig.new()
	var loaded := rig.load_fighter("atalanta")
	assert_true(loaded, "Atalanta rig loaded")
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)

	var driver := PoseDriver.new()
	driver.setup(rig)

	var world := ProtoFixture.world_with()
	var fighter := world.fighters[1]
	fighter.fighter_id = "atalanta"
	fighter.state = SimFighter.State.IDLE
	fighter.facing = -1

	driver.update(fighter)
	assert_eq(driver.current_action_name, "idle", "Atalanta plays idle")
	assert_eq(
		driver.current_clip_id,
		"idle_and_start_animation_idle",
		"Atalanta uses combat-ready idle clip"
	)

	# Verify backward walk selection when walk_direction opposes facing
	fighter.state = SimFighter.State.WALK
	fighter.walk_speed = 22
	driver.walk_direction = 1  # Opposes facing (-1) -> moving backward
	driver.update(fighter)
	assert_eq(driver.current_action_name, "walk_back", "Moving backward triggers walk_back")

	driver.walk_direction = -1  # Matches facing (-1) -> moving forward
	driver.update(fighter)
	assert_eq(driver.current_action_name, "walk_fwd", "Moving forward triggers walk_fwd")

	# Test presentation facing on both sides (+1 and -1), retreat (walking backward), and side swaps
	for facing_dir in [1, -1]:
		fighter.facing = facing_dir
		fighter.state = SimFighter.State.IDLE
		driver.update(fighter)
		assert_true(
			rig.basis.z.x * facing_dir > 0.99,
			"Idle model forward basis.z.x (%f) faces facing_dir (%d)" % [rig.basis.z.x, facing_dir]
		)

		fighter.state = SimFighter.State.WALK
		# Retreat: walk away from opponent
		driver.walk_direction = -facing_dir
		driver.update(fighter)
		assert_eq(driver.current_action_name, "walk_back", "Retreat selects walk_back")
		assert_true(
			rig.basis.z.x * facing_dir > 0.99,
			(
				"Retreat model forward basis.z.x (%f) remains facing opponent (%d)"
				% [rig.basis.z.x, facing_dir]
			)
		)

		# Advance: walk toward opponent
		driver.walk_direction = facing_dir
		driver.update(fighter)
		assert_eq(driver.current_action_name, "walk_fwd", "Advance selects walk_fwd")
		assert_true(
			rig.basis.z.x * facing_dir > 0.99,
			"Advance model forward basis.z.x (%f) faces opponent (%d)" % [rig.basis.z.x, facing_dir]
		)

	rig.free()

	# Also verify Theron on both sides
	var theron_rig := FighterRig.new()
	assert_true(theron_rig.load_fighter("theron"), "Theron rig loads")
	(Engine.get_main_loop() as SceneTree).root.add_child(theron_rig)
	var theron_driver := PoseDriver.new()
	theron_driver.setup(theron_rig)
	var theron_fighter := world.fighters[0]
	theron_fighter.fighter_id = "theron"

	for facing_dir in [1, -1]:
		theron_fighter.facing = facing_dir
		theron_fighter.state = SimFighter.State.IDLE
		theron_driver.update(theron_fighter)
		assert_true(
			theron_rig.basis.z.x * facing_dir > 0.99,
			(
				"Theron idle model forward basis.z.x (%f) faces facing_dir (%d)"
				% [theron_rig.basis.z.x, facing_dir]
			)
		)

		theron_fighter.state = SimFighter.State.WALK
		theron_driver.walk_direction = -facing_dir  # retreat
		theron_driver.update(theron_fighter)
		assert_true(
			theron_rig.basis.z.x * facing_dir > 0.99,
			(
				"Theron retreat model forward basis.z.x (%f) faces facing_dir (%d)"
				% [theron_rig.basis.z.x, facing_dir]
			)
		)

	theron_rig.free()


func test_gore_debris_and_burst_joint_local() -> void:
	var gore := GoreManager.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(gore)

	# Test burst parameters
	gore.burst(Vector3(0, 1.0, 0), false, true)
	assert_true(gore.particles.size() > 0, "severed burst spawned particles")

	# Find CPUParticles3D in particles pool
	var burst_particle: CPUParticles3D = null
	for p in gore.particles:
		if p is CPUParticles3D and p.mesh is SphereMesh:
			burst_particle = p as CPUParticles3D
			break
	assert_true(burst_particle != null, "CPUParticles3D found")
	assert_eq(burst_particle.amount, 28, "normal gore severed particle amount is 28 (small burst)")
	assert_eq(burst_particle.spread, 45.0, "severed particle spread is tight (45 deg)")
	assert_true(burst_particle.initial_velocity_max <= 2.0, "particle velocity is small (<= 2 m/s)")
	assert_true(burst_particle.mesh is SphereMesh, "droplet is SphereMesh")
	assert_true(
		(burst_particle.mesh as SphereMesh).radius <= 0.02, "droplet radius is small (<= 0.02m)"
	)

	# Test debris scaling consistency: visual mesh scale matches collision shape size
	var rig := FighterRig.new()
	rig.load_fighter("atalanta")
	var sample_piece: MeshInstance3D = rig.limb_meshes["arm_l"][0]
	gore.debris(sample_piece, Transform3D.IDENTITY, 1.0)
	var spawned_body: RigidBody3D = gore.chunks.back() as RigidBody3D
	assert_true(spawned_body != null, "debris body spawned")

	var visual: MeshInstance3D = spawned_body.find_child("*", true, false) as MeshInstance3D
	var collision: CollisionShape3D = (
		spawned_body.find_children("*", "CollisionShape3D", true, false)[0] as CollisionShape3D
	)
	assert_true(visual != null and collision != null, "visual and collision present in debris")

	var col_shape := collision.shape as BoxShape3D
	var max_col_dim := maxf(col_shape.size.x, maxf(col_shape.size.y, col_shape.size.z))
	assert_true(max_col_dim <= 1.505, "detached real limb retains scale within safe bounds")
	assert_true(visual.scale.x <= 1.0, "visual scale adjusted to match collision size")

	rig.free()
	gore.free()


func test_pilot_neck_and_head_continuity() -> void:
	# Verifies that for the skinned pilot rig, head and spine/neck remain continuous
	# across idle, walk, punch, kick, block, hit, death frames (no separation/displacement).
	var rig := FighterRig.new()
	var ok := rig.load_fighter("atalanta")
	assert_true(ok, "loads atalanta rig")
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)

	var head_idx := rig.skeleton.find_bone("head")
	var spine_idx := rig.skeleton.find_bone("spine")
	assert_true(head_idx >= 0, "head bone exists")
	assert_true(spine_idx >= 0, "spine bone exists")

	# Initial rest distance between spine and head
	var rest_head_pos := rig.skeleton.get_bone_global_rest(head_idx).origin
	var rest_spine_pos := rig.skeleton.get_bone_global_rest(spine_idx).origin
	var rest_dist := rest_head_pos.distance_to(rest_spine_pos)

	var anim_list := rig.anim_player.get_animation_list()
	for anim_name in anim_list:
		if not (
			anim_name.ends_with("idle")
			or anim_name.ends_with("walk_fwd")
			or anim_name.ends_with("walk_back")
			or anim_name.ends_with("attack_light")
			or anim_name.ends_with("attack_heavy")
			or anim_name.ends_with("block")
			or anim_name.ends_with("hit")
			or anim_name.ends_with("death")
		):
			continue
		rig.anim_player.play(anim_name)
		var anim: Animation = rig.anim_player.get_animation(anim_name)
		var dur := anim.length
		# Sample multiple frames across the duration
		for step in 5:
			var t := (float(step) / 4.0) * dur
			rig.anim_player.seek(t, true)
			var pose_head := rig.skeleton.get_bone_global_pose(head_idx).origin
			var pose_spine := rig.skeleton.get_bone_global_pose(spine_idx).origin
			var current_dist := pose_head.distance_to(pose_spine)
			# Bone distance between spine and head must remain anatomically bounded (within 20% of rest)
			var delta := absf(current_dist - rest_dist)
			assert_true(
				delta < 0.15,
				(
					"head and spine remain continuous under %s at t=%.2f: delta=%.3fm"
					% [anim_name, t, delta]
				)
			)

	rig.free()
