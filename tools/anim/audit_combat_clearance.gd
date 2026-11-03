extends SceneTree

var Constraints

func _initialize() -> void:
	call_deferred("run")

func clearance(s: Skeleton3D) -> float:
	var pelvis := s.get_bone_global_pose(s.find_bone("root")).origin
	var head := s.get_bone_global_pose(s.find_bone("head")).origin
	var left := s.get_bone_global_pose(s.find_bone("upper_arm.l")).origin
	var right := s.get_bone_global_pose(s.find_bone("upper_arm.r")).origin
	var radius := clampf(left.distance_to(right) * 0.36, 0.12, 0.23)
	var result := INF
	for side in ["l", "r"]:
		var e := s.get_bone_global_pose(s.find_bone("forearm." + side)).origin
		var h := s.get_bone_global_pose(s.find_bone("hand." + side)).origin
		for t in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var p := e.lerp(h, t)
			result = minf(result, p.distance_to(Constraints.closest(p, pelvis, pelvis.lerp(head, 0.78))) - radius - 0.055)
	return result

func run() -> void:
	Constraints = load("res://src/presentation/combat_pose_constraints.gd")
	for id in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		var fighter = load("res://src/presentation/match_launcher.gd").make_world(config).fighters[0]
		var rig = load("res://src/presentation/fighter_rig.gd").new()
		root.add_child(rig)
		rig.load_fighter(id)
		var worst_before := 0.0
		var worst_after := 0.0
		var count := 0
		var leg_gap := INF
		for name in rig.anim_player.get_animation_list():
			if not (str(name).begins_with(id + "_move_") or str(name).begins_with(id + "_hit") or str(name).contains("reaction_gut")):
				continue
			var animation: Animation = rig.anim_player.get_animation(name)
			rig.anim_player.play(name)
			for sample in 16:
				rig.anim_player.seek(animation.length * float(sample) / 15.0, true)
				rig.skeleton.force_update_all_bone_transforms()
				worst_before = minf(worst_before, clearance(rig.skeleton))
				Constraints.apply(rig, fighter)
				var s: Skeleton3D = rig.skeleton
				var la := s.get_bone_global_pose(s.find_bone("shin.l")).origin
				var lb := s.get_bone_global_pose(s.find_bone("foot.l")).origin
				var ra := s.get_bone_global_pose(s.find_bone("shin.r")).origin
				var rb := s.get_bone_global_pose(s.find_bone("foot.r")).origin
				for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
					var p := la.lerp(lb, fraction)
					leg_gap = minf(leg_gap, p.distance_to(Constraints.closest(p, ra, rb)))
				var after := clearance(rig.skeleton)
				if after < worst_after:
					worst_after = after
					print("WORST ", id, " ", name, " sample=", sample, " clearance=", after)
				count += 1
		print("CLEARANCE ", id, " poses=", count, " before=", worst_before, " after=", worst_after, " shin_gap=", leg_gap)
		rig.free()
	quit()


