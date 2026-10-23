class_name LimbQuirks
extends RefCounted


static func animate(model: Node3D, time: float) -> void:
	for name in ["PART_beak", "PART_claw_upper", "PART_claw_lower", "PART_sandal_wing"]:
		var part := model.find_child(name, true, false) as Node3D
		if part != null:
			part.rotation.z = sin(time * 4.0) * 0.08
