extends TestBase

const MODELS = [
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


func test_all_models_keep_joint_offsets_and_healthy_animation() -> void:
	for model_id in MODELS:
		var rig := FighterRig.new()
		assert_true(rig.load_fighter("theron", model_id), model_id)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		assert_eq(
			rig.anim_player.callback_mode_process,
			AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL,
			"one animation clock"
		)
		for slot in SimLimbs.LIMB_NAMES:
			var bounds := AABB()
			for mesh in rig.limb_meshes[slot]:
				bounds = bounds.merge(mesh.get_aabb()) if bounds.has_volume() else mesh.get_aabb()
			var extent: float = bounds.size.x if slot.begins_with("arm") else bounds.size.y
			assert_true(
				extent > 0.3, "natural limb partition includes proximal joints: " + model_id + slot
			)
		for action in ["idle", "walk_fwd", "punch_jab", "kick_thrust"]:
			var clip: String = "theron_" + action
			rig.anim_player.play(clip)
			for fraction in [0.0, 0.4, 0.8]:
				rig.anim_player.seek(rig.anim_player.get_animation(clip).length * fraction, true)
				for bone in rig.skeleton.get_bone_count():
					var rest := rig.skeleton.get_bone_rest(bone).origin
					assert_true(
						rig.skeleton.get_bone_pose_position(bone).distance_to(rest) < 0.0001,
						"preserve actual joint offsets: %s/%s" % [model_id, action]
					)
				var arm := rig.skeleton.find_bone("upper_arm.l")
				var before := rig.skeleton.get_bone_pose_rotation(arm)
				rig.sync(ProtoFixture.world_with().fighters[0])
				assert_true(
					before.is_equal_approx(rig.skeleton.get_bone_pose_rotation(arm)),
					"sync must not reset healthy animated limbs"
				)
		rig.free()


func test_all_40_replacements_have_real_deform_weights() -> void:
	for model_id in MODELS:
		var rig := FighterRig.new()
		rig.load_fighter("theron", model_id)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		for slot in SimLimbs.LIMB_NAMES:
			assert_true(
				rig.attach_regrown(
					slot, "rubber_chicken_arm" if slot.begins_with("arm") else "hermes_sandal_leg"
				),
				model_id + slot
			)
			for mesh in rig.replacements[slot].find_children("*", "MeshInstance3D", true, false):
				assert_eq(
					mesh.get_node(mesh.skeleton), rig.skeleton, "renderer uses fighter skeleton"
				)
				# Seam shells preserve native shoulder weights; validate their binding above.
				if str(mesh.name).begins_with("SEAM_"):
					continue
				var limb_weight := 0.0
				for surface in mesh.mesh.get_surface_count():
					var arrays: Array = mesh.mesh.surface_get_arrays(surface)
					var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
					var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
					for i in weights.size():
						if weights[i] > 0.0:
							var bone: String = mesh.skin.get_bind_name(joints[i])
							if (
								bone.begins_with("upper_arm")
								or bone.begins_with("forearm")
								or bone.begins_with("thigh")
								or bone.begins_with("shin")
							):
								limb_weight += weights[i]
				assert_true(
					limb_weight > 100.0,
					"limb must bend on real joints, not a neutral/root bone: " + model_id + slot
				)
		rig.free()


func test_pilot_bind_rest_space_matches_metre_limb() -> void:
	var pilot := (
		(load("res://build/pilot_gate_a/arissa_partitioned.glb") as PackedScene).instantiate()
	)
	(Engine.get_main_loop() as SceneTree).root.add_child(pilot)
	var target := pilot.find_child("Skeleton3D", true, false) as Skeleton3D
	for slot in ["arm_l", "leg_l"]:
		var asset := (
			(load("res://assets/limbs_elemental/elemental_atalanta_%s.glb" % slot) as PackedScene)
			. instantiate()
		)
		(Engine.get_main_loop() as SceneTree).root.add_child(asset)
		var source := asset.find_child("Skeleton3D", true, false) as Skeleton3D
		var mesh := asset.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var original := mesh.skin
		assert_true(FighterRig.adapt_mesh_skin_to_skeleton(mesh, target), "pilot adapts " + slot)
		for bind in original.get_bind_count():
			var src := source.find_bone(original.get_bind_name(bind))
			var dst := target.find_bone(mesh.skin.get_bind_name(bind))
			var before := (
				source.global_transform
				* source.get_bone_global_rest(src)
				* original.get_bind_pose(bind)
			)
			var after := (
				target.global_transform
				* target.get_bone_global_rest(dst)
				* mesh.skin.get_bind_pose(bind)
			)
			assert_true(
				before.origin.distance_to(after.origin) < 0.03, "pilot attachment origin in metres"
			)
			assert_true(
				before.basis.x.distance_to(after.basis.x) < 0.03, "pilot attachment scale in metres"
			)
		asset.free()
	pilot.free()


func test_hitstop_freezes_clip_and_block_selects_block() -> void:
	var rig := FighterRig.new()
	rig.load_fighter("theron")
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	var driver := PoseDriver.new()
	driver.setup(rig)
	var fighter := ProtoFixture.world_with().fighters[0]
	driver.update(fighter)
	var time := rig.anim_player.current_animation_position
	for tick in 5:
		driver.update(fighter, true)
	assert_near(rig.anim_player.current_animation_position, time, 0.00001, "hitstop freezes clip")
	fighter.blocking = true
	driver.update(fighter)
	assert_eq(driver.current_action_name, "block", "blocking idle uses block animation")
	rig.free()
