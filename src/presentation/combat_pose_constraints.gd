extends RefCounted
## Presentation-only capsule clearance. Rotate chains; never translate skin joints.

static func closest(point: Vector3, a: Vector3, b: Vector3) -> Vector3:
	var axis := b - a
	return a + axis * clampf((point - a).dot(axis) / maxf(axis.length_squared(), 0.000001), 0.0, 1.0)


static func apply(rig: FighterRig, fighter: SimFighter) -> void:
	if fighter.pose not in ["standing", "crouch", "hop"] or fighter.state == SimFighter.State.KO:
		return
	var s := rig.skeleton
	s.force_update_all_bone_transforms()
	var pelvis := s.get_bone_global_pose(s.find_bone("root")).origin
	var head := s.get_bone_global_pose(s.find_bone("head")).origin
	var chest := pelvis.lerp(head, 0.78)
	var left := s.get_bone_global_pose(s.find_bone("upper_arm.l")).origin
	var right := s.get_bone_global_pose(s.find_bone("upper_arm.r")).origin
	var radius := clampf(left.distance_to(right) * 0.36, 0.12, 0.23)
	for pass_index in 3:
		for side in ["l", "r"]:
			if not fighter.limbs.usable("arm_" + side):
				continue
			var upper := s.find_bone("upper_arm." + side)
			var elbow := s.find_bone("forearm." + side)
			var hand := s.find_bone("hand." + side)
			var e := s.get_bone_global_pose(elbow).origin
			var h := s.get_bone_global_pose(hand).origin
			var correction := Vector3.ZERO
			# Include the forearm interior, not just the wrist.
			for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
				var point := e.lerp(h, fraction)
				var center := closest(point, pelvis, chest)
				var delta := point - center
				var clearance := radius + 0.055
				if delta.length() < clearance:
					var away := delta.normalized() if delta.length() > 0.001 else Vector3.FORWARD
					var push := away * (clearance - delta.length())
					if push.length() > correction.length():
						correction = push
			if correction.length_squared() > 0.000001:
				solve(s, upper, elbow, hand, h + correction, e + correction * 2.0)
		# Separate opposing forearms/hands while leaving the attacking arm intact.
		if fighter.limbs.usable("arm_l") and fighter.limbs.usable("arm_r"):
			separate(s, "forearm", "hand", "upper_arm", "r" if fighter.attack_slot == "arm_l" else "l", 0.13)
		# A bent knee or planted shin must not pass through the opposite shin.
		if fighter.limbs.usable("leg_l") and fighter.limbs.usable("leg_r"):
			separate(s, "shin", "foot", "thigh", "r" if fighter.attack_slot == "leg_l" else "l", 0.12)
	# An extreme cross-body source pose can make the projected wrist unreachable.
	# Recover that arm to an exterior guard rather than leave the forearm in the chest.
	for side in ["l", "r"]:
		if not fighter.limbs.usable("arm_" + side):
			continue
		var upper := s.find_bone("upper_arm." + side)
		var elbow := s.find_bone("forearm." + side)
		var hand := s.find_bone("hand." + side)
		var e := s.get_bone_global_pose(elbow).origin
		var h := s.get_bone_global_pose(hand).origin
		var penetration := false
		for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var point := e.lerp(h, fraction)
			if point.distance_to(closest(point, pelvis, chest)) < radius + 0.05:
				penetration = true
		if penetration:
			var shoulder := s.get_bone_global_pose(upper).origin
			var sign_x := signf(s.get_bone_global_rest(upper).origin.x)
			var best := -INF
			var best_upper := s.get_bone_pose_rotation(upper)
			var best_lower := s.get_bone_pose_rotation(elbow)
			for lateral in [0.08, 0.2, 0.35, 0.5]:
				var goal := shoulder + Vector3(sign_x * lateral, -0.10, 0.28)
				solve(s, upper, elbow, hand, goal, shoulder + Vector3(sign_x * 0.4, -0.2, -0.1))
				e = s.get_bone_global_pose(elbow).origin
				h = s.get_bone_global_pose(hand).origin
				var score := INF
				for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
					var point := e.lerp(h, fraction)
					score = minf(score, point.distance_to(closest(point, pelvis, chest)) - radius - 0.055)
				if score > best:
					best = score
					best_upper = s.get_bone_pose_rotation(upper)
					best_lower = s.get_bone_pose_rotation(elbow)
				if score >= -0.005:
					break
			s.set_bone_pose_rotation(upper, best_upper)
			s.set_bone_pose_rotation(elbow, best_lower)
			s.force_update_all_bone_transforms()
			if best < -0.005:
				var outward := (shoulder - closest(shoulder, pelvis, chest)).normalized()
				var arm_length := shoulder.distance_to(e) + e.distance_to(h)
				solve(s, upper, elbow, hand, shoulder + outward * arm_length * 0.92, shoulder + outward * 0.4 + Vector3(0, -0.2, 0))


static func separate(s: Skeleton3D, mid: String, tip: String, base: String, side: String, clearance: float) -> void:
	var other := "r" if side == "l" else "l"
	var a := s.get_bone_global_pose(s.find_bone(mid + "." + side)).origin
	var b := s.get_bone_global_pose(s.find_bone(tip + "." + side)).origin
	var c := s.get_bone_global_pose(s.find_bone(mid + "." + other)).origin
	var d := s.get_bone_global_pose(s.find_bone(tip + "." + other)).origin
	var push := Vector3.ZERO
	for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var p := a.lerp(b, fraction)
		var delta := p - closest(p, c, d)
		if delta.length() < clearance:
			var away := delta.normalized()
			if delta.length() < 0.001:
				away = Vector3.LEFT if side == "l" else Vector3.RIGHT
			var correction := away * (clearance - delta.length())
			if correction.length() > push.length():
				push = correction
	if push.length_squared() > 0.000001:
		solve(s, s.find_bone(base + "." + side), s.find_bone(mid + "." + side), s.find_bone(tip + "." + side), b + push, a + push * 2.0)


static func solve(s: Skeleton3D, upper: int, lower: int, tip: int, goal: Vector3, pole: Vector3) -> void:
	var a := s.get_bone_global_pose(upper).origin
	var b := s.get_bone_global_pose(lower).origin
	var c := s.get_bone_global_pose(tip).origin
	var first := a.distance_to(b)
	var second := b.distance_to(c)
	if minf(first, second) < 0.001:
		return
	var direction := (goal - a).normalized()
	var reach := clampf(a.distance_to(goal), absf(first - second) + 0.001, (first + second) * 0.995)
	var along := (first * first - second * second + reach * reach) / (2.0 * reach)
	var bend := pole - a
	bend = bend - direction * bend.dot(direction)
	if bend.length_squared() < 0.000001:
		bend = direction.cross(Vector3.UP)
	if bend.length_squared() < 0.000001:
		bend = Vector3.RIGHT
	var elbow_goal := a + direction * along + bend.normalized() * sqrt(maxf(0.0, first * first - along * along))
	aim(s, upper, b - a, elbow_goal - a)
	b = s.get_bone_global_pose(lower).origin
	c = s.get_bone_global_pose(tip).origin
	aim(s, lower, c - b, a + direction * reach - b)


static func aim(s: Skeleton3D, bone: int, from: Vector3, to: Vector3) -> void:
	if minf(from.length_squared(), to.length_squared()) < 0.000001:
		return
	var rotation := s.get_bone_global_pose(bone).basis.orthonormalized().get_rotation_quaternion()
	var parent := s.get_bone_parent(bone)
	var parent_rotation := s.get_bone_global_pose(parent).basis.orthonormalized().get_rotation_quaternion()
	s.set_bone_pose_rotation(bone, parent_rotation.inverse() * Quaternion(from.normalized(), to.normalized()) * rotation)
	s.force_update_all_bone_transforms()
