class_name LimbQuirks
extends RefCounted


static func animate(
	model: Node3D, time: float, active: bool = false, settings: Dictionary = {}
) -> void:
	var rate := float(settings.get("quirk_rate", 4.0))
	var angle := float(settings.get("quirk_angle", 0.12))
	for name in ["PART_beak", "PART_claw_upper", "PART_claw_lower", "PART_sandal_wing"]:
		var part := model.find_child(name, true, false) as Node3D
		if part != null:
			part.rotation.z = (1.0 if active else sin(time * rate)) * angle
			if name == "PART_beak":
				part.scale.y = 1.0 - float(settings.get("squash", 0.15)) if active else 1.0
