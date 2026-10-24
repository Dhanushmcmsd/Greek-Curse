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
	for fid in FIGHTER_IDS:
		var rig := FighterRig.new()
		var success := rig.load_fighter(fid)
		assert_true(success, "load_fighter succeeds for " + fid)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)

		assert_true(rig.anim_player != null, "anim_player exists for " + fid)
		assert_true(rig.skeleton != null, "skeleton exists for " + fid)

		var resolved_root: Node = rig.anim_player.get_node_or_null(rig.anim_player.root_node)
		assert_true(resolved_root != null, "anim_player root_node resolves for " + fid)

		# Check all animations in all libraries
		var libs: Array[StringName] = rig.anim_player.get_animation_library_list()
		assert_true(libs.size() > 0, "has animation libraries for " + fid)

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
							"Track target node resolves for %s:%s track[%d]: %s"
							% [fid, str(anim_name), t, str(trk_path)]
						)
					)
					if sub_part != "":
						assert_true(
							target_node is Skeleton3D,
							(
								"Subname target node must be Skeleton3D for %s track %s"
								% [fid, str(trk_path)]
							)
						)
						var bone_idx: int = (target_node as Skeleton3D).find_bone(sub_part)
						assert_true(
							bone_idx >= 0,
							(
								"Bone '%s' exists on skeleton for %s track %s"
								% [sub_part, fid, str(trk_path)]
							)
						)
		rig.free()

	# Also verify for all visual models overridden on Theron
	for mid in MODEL_IDS:
		var rig := FighterRig.new()
		var success := rig.load_fighter("theron", mid)
		assert_true(success, "load_fighter succeeds with model " + mid)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)

		assert_true(rig.skeleton != null, "skeleton exists for model " + mid)
		assert_eq(rig.skeleton.get_bone_count(), 15, "15 shared bones for model " + mid)

		var resolved_root: Node = rig.anim_player.get_node_or_null(rig.anim_player.root_node)
		var libs: Array[StringName] = rig.anim_player.get_animation_library_list()
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
						target_node != null, "Model " + mid + " resolves node for " + str(trk_path)
					)
					if sub_part != "":
						var bone_idx: int = (target_node as Skeleton3D).find_bone(sub_part)
						assert_true(bone_idx >= 0, "Model " + mid + " resolves bone " + sub_part)
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

	# Both can play and evaluate without colliding
	rig1.anim_player.play("theron_walk_fwd")
	rig2.anim_player.play("atalanta_walk_fwd")
	rig1.anim_player.advance(0.1)
	rig2.anim_player.advance(0.2)

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
