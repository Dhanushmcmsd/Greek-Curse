class_name OneLegMotion
extends RefCounted
## Side-aware additive animation, evaluated on the same tick as the strike clip.

var stage := ""
var _idle: Dictionary = {}


func apply(rig: FighterRig, fighter: SimFighter, time: float) -> Dictionary:
	var result := {"active": false, "pitch": 0.0, "lift": 0.0}
	stage = ""
	var left := fighter.limbs.usable("leg_l")
	var right := fighter.limbs.usable("leg_r")
	if left == right or fighter.state in [SimFighter.State.KO, SimFighter.State.GRABBED]:
		return result
	var side := "l" if left else "r"
	var missing := "r" if left else "l"
	result.active = true
	# An attached but broken leg folds away instead of bearing weight.
	if fighter.limbs.parts["leg_" + missing].state != "severed":
		_offset(rig, "thigh." + missing, Vector3(0.65, 0, 0))
		_offset(rig, "shin." + missing, Vector3(-1.4, 0, 0))
	var attacking := (
		fighter.move_id > 0
		and (
			fighter.state
			in [SimFighter.State.STARTUP, SimFighter.State.ACTIVE, SimFighter.State.RECOVERY]
		)
	)
	if attacking and fighter.attack_slot == "leg_" + side:
		stage = "kick"
		if fighter.state != SimFighter.State.RECOVERY:
			result.lift = (
				0.12
				* sin(
					(
						clampf(
							(
								float(fighter.state_tick)
								/ maxf(1, fighter.startup_ticks + fighter.active_ticks)
							),
							0,
							1
						)
						* PI
						* 0.5
					)
				)
			)
			return result
		var age := fighter.state_tick - fighter.startup_ticks - fighter.active_ticks
		var t := clampf(float(age) / maxf(1, fighter.recovery_ticks - 1), 0, 1)
		# Contact -> hip landing -> knee under torso -> rise on the same foot.
		var fall := smoothstep(0.0, 0.38, t) * (1.0 - smoothstep(0.55, 1.0, t))
		stage = "fall" if t < 0.55 else "rise"
		_blend_to_balance(rig, fighter.fighter_id, smoothstep(0.55, 1.0, t))
		result.pitch = -1.15 * fall
		result.lift = 0.12 * (1.0 - smoothstep(0.0, 0.38, t))
		_offset(rig, "thigh." + side, Vector3(0.9 * fall, 0, 0))
		_offset(rig, "shin." + side, Vector3(-1.45 * fall, 0, 0))
		_offset(rig, "spine", Vector3(0.4 * fall, 0, 0))
		for arm in ["l", "r"]:
			if fighter.limbs.usable("arm_" + arm):
				_offset(rig, "upper_arm." + arm, Vector3(-0.65 * fall, 0, 0))
		return result
	if attacking or fighter.state not in [SimFighter.State.IDLE, SimFighter.State.WALK]:
		return result
	stage = "hop" if fighter.state == SimFighter.State.WALK else "balance"
	var cycle := fposmod(time * 2.4, 1.0)
	var airborne := sin(PI * clampf((cycle - 0.22) / 0.78, 0, 1))
	var crouch := sin(PI * clampf(cycle / 0.22, 0, 1)) * 0.25
	if fighter.state != SimFighter.State.WALK:
		airborne = 0.0
		crouch = 0.04
	_offset(rig, "thigh." + side, Vector3(crouch + airborne * 0.15, 0, 0))
	_offset(rig, "shin." + side, Vector3(-crouch * 2.0 - airborne * 0.3, 0, 0))
	_offset(rig, "spine", Vector3(0, 0, 0.08 if left else -0.08))
	result.lift = airborne * 0.09
	return result


func _offset(rig: FighterRig, name: String, angles: Vector3) -> void:
	var bone := FighterRig.resolve_bone(rig.skeleton, name)
	if bone >= 0:
		rig.skeleton.set_bone_pose_rotation(
			bone, rig.skeleton.get_bone_pose_rotation(bone) * Quaternion.from_euler(angles)
		)


func _blend_to_balance(rig: FighterRig, fighter_id: String, weight: float) -> void:
	if weight <= 0.0:
		return
	if _idle.is_empty():
		var animation := rig.anim_player.get_animation(fighter_id + "_idle")
		if animation == null:
			return
		for track in animation.get_track_count():
			if animation.track_get_type(track) != Animation.TYPE_ROTATION_3D:
				continue
			var name := animation.track_get_path(track).get_concatenated_subnames()
			var bone := rig.skeleton.find_bone(name)
			if bone >= 0:
				_idle[bone] = animation.rotation_track_interpolate(track, 0.0)
	for bone in _idle:
		rig.skeleton.set_bone_pose_rotation(
			bone, rig.skeleton.get_bone_pose_rotation(bone).slerp(_idle[bone], weight)
		)
