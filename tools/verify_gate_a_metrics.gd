extends SceneTree

const PilotPreviewScript := preload("res://src/presentation/pilot_gate_a_preview.gd")

func _init() -> void:
	print("--- Running Gate A Automated Visual Proof & Metric Verification ---")
	var scene_pck := load("res://scenes/debug/pilot_gate_a_preview.tscn") as PackedScene
	if scene_pck == null:
		push_error("Failed to load pilot preview scene")
		quit(1)
		return
		
	var root_node := scene_pck.instantiate()
	root.add_child(root_node)
	var pilot: Node = root_node
	
	DirAccess.make_dir_recursive_absolute("e:/zeus balls/docs/playtest/pilot_gate_a")
	
	var ap: AnimationPlayer = pilot.get("anim_player")
	var skel: Skeleton3D = pilot.get("skeleton")
	
	var neck_idx: int = skel.find_bone("mixamorig_Neck")
	var neck1_idx: int = skel.find_bone("mixamorig_Neck1")
	var head_idx: int = skel.find_bone("mixamorig_Head")
	var l_up_arm: int = skel.find_bone("mixamorig_LeftArm")
	var l_fore_arm: int = skel.find_bone("mixamorig_LeftForeArm")
	var l_hand: int = skel.find_bone("mixamorig_LeftHand")
	var l_thigh: int = skel.find_bone("mixamorig_LeftUpLeg")
	var l_shin: int = skel.find_bone("mixamorig_LeftLeg")
	var l_foot: int = skel.find_bone("mixamorig_LeftFoot")
	var r_foot: int = skel.find_bone("mixamorig_RightFoot")
	
	var actions: Array[String] = ["idle", "walk_fwd", "walk_back", "punch_jab", "kick_thrust"]
	
	var metrics_report := {}
	
	# Reference rest distances (in cm units as imported by Godot: 1.0 unit = 1 cm)
	var rest_neck_to_head_dist: float = skel.get_bone_global_rest(neck_idx).origin.distance_to(skel.get_bone_global_rest(head_idx).origin)
	var rest_arm_length: float = (
		skel.get_bone_global_rest(l_up_arm).origin.distance_to(skel.get_bone_global_rest(l_fore_arm).origin)
		+ skel.get_bone_global_rest(l_fore_arm).origin.distance_to(skel.get_bone_global_rest(l_hand).origin)
	)
	var rest_leg_length: float = (
		skel.get_bone_global_rest(l_thigh).origin.distance_to(skel.get_bone_global_rest(l_shin).origin)
		+ skel.get_bone_global_rest(l_shin).origin.distance_to(skel.get_bone_global_rest(l_foot).origin)
	)
	print("Reference rest distances: Neck-to-Head = %.2f cm, LeftArm = %.2f cm, LeftLeg = %.2f cm" % [
		rest_neck_to_head_dist, rest_arm_length, rest_leg_length
	])
	
	for act in actions:
		pilot.call("play_action", act)
		var anim: Animation = ap.get_animation(act)
		var dur: float = anim.length
		print("\nInspecting Action: %s (Duration: %.2fs)" % [act, dur])
		
		var sample_fractions := [0.0, 0.25, 0.5, 0.75, 1.0]
		var frame_samples: Array = []
		
		for frac in sample_fractions:
			var t: float = frac * dur
			ap.seek(t, true)
			
			# Sample joint world positions
			var neck_pos: Vector3 = skel.get_bone_global_pose(neck_idx).origin
			var head_pos: Vector3 = skel.get_bone_global_pose(head_idx).origin
			var neck_head_dist: float = neck_pos.distance_to(head_pos)
			
			var up_arm_pos: Vector3 = skel.get_bone_global_pose(l_up_arm).origin
			var fore_arm_pos: Vector3 = skel.get_bone_global_pose(l_fore_arm).origin
			var hand_pos: Vector3 = skel.get_bone_global_pose(l_hand).origin
			var arm_len: float = up_arm_pos.distance_to(fore_arm_pos) + fore_arm_pos.distance_to(hand_pos)
			
			var thigh_pos: Vector3 = skel.get_bone_global_pose(l_thigh).origin
			var shin_pos: Vector3 = skel.get_bone_global_pose(l_shin).origin
			var l_foot_pos: Vector3 = skel.get_bone_global_pose(l_foot).origin
			var r_foot_pos: Vector3 = skel.get_bone_global_pose(r_foot).origin
			var leg_len: float = thigh_pos.distance_to(shin_pos) + shin_pos.distance_to(l_foot_pos)
			
			frame_samples.append({
				"timestamp": t,
				"fraction": frac,
				"neck_head_dist_cm": neck_head_dist,
				"arm_len_cm": arm_len,
				"leg_len_cm": leg_len,
				"hand_pos": [hand_pos.x, hand_pos.y, hand_pos.z],
				"l_foot_pos": [l_foot_pos.x, l_foot_pos.y, l_foot_pos.z],
				"r_foot_pos": [r_foot_pos.x, r_foot_pos.y, r_foot_pos.z]
			})
			
			# Verify neck-head distance is rigid/continuous (cannot stretch by more than 1 cm under animation)
			var neck_diff := absf(neck_head_dist - rest_neck_to_head_dist)
			if neck_diff > 1.0:
				push_error("FAIL: Neck-Head displacement detected at %s frac %.2f: diff=%.2f cm" % [act, frac, neck_diff])
				quit(2)
				return
				
			# Verify limb bone chains preserve continuity
			var arm_diff := absf(arm_len - rest_arm_length)
			if arm_diff > 1.0:
				push_error("FAIL: Arm joint tearing detected at %s frac %.2f: diff=%.2f cm" % [act, frac, arm_diff])
				quit(2)
				return
				
			var leg_diff := absf(leg_len - rest_leg_length)
			if leg_diff > 1.0:
				push_error("FAIL: Leg joint tearing detected at %s frac %.2f: diff=%.2f cm" % [act, frac, leg_diff])
				quit(2)
				return
				
		metrics_report[act] = frame_samples
		print("  Sampled 5 frames. Neck-Head continuity verified across all frames (dist=%.2f cm, delta=%.4f cm)" % [
			frame_samples[0]["neck_head_dist_cm"],
			absf(frame_samples[0]["neck_head_dist_cm"] - rest_neck_to_head_dist)
		])
		print("  Arm continuity: %.2f cm (rest: %.2f cm) | Leg continuity: %.2f cm (rest: %.2f cm)" % [
			frame_samples[0]["arm_len_cm"], rest_arm_length, frame_samples[0]["leg_len_cm"], rest_leg_length
		])
		
	var report_file := FileAccess.open("res://docs/playtest/pilot_gate_a/metrics_report.json", FileAccess.WRITE)
	if report_file != null:
		report_file.store_string(JSON.stringify(metrics_report, "\t"))
		report_file.close()
		
	print("\nGATE_A_VERIFICATION_PASS: All 5 core actions verified with 100% anatomical joint continuity.")
	quit(0)
