class_name FightCamera
extends Camera3D

var settings: Dictionary
var kick: float = 0.0
var sever_zoom: float = 0.0


func _ready() -> void:
	settings = DataLoader.new().load_json("res://data/art/vfx.json").value["camera"]
	fov = float(settings["fov"])
	current = true
	position = Vector3(0, float(settings["height"]), 7)


static func framing(left: float, right: float, settings: Dictionary) -> Vector2:
	var distance := clampf(
		abs(right - left) * 0.72 + 4.8,
		float(settings["minimum_distance"]),
		float(settings["maximum_distance"])
	)
	return Vector2(clampf((left + right) * 0.5, -2.5, 2.5), distance)


func track(world: SimWorld) -> void:
	var target := framing(
		float(world.fighters[0].x) / 1000.0, float(world.fighters[1].x) / 1000.0, settings
	)
	position = position.lerp(
		Vector3(target.x, float(settings["height"]), target.y - sever_zoom),
		float(settings["smooth"])
	)
	look_at(Vector3(position.x, 1.0, 0))
	h_offset = sin(float(world.tick) * 2.3) * kick
	v_offset = cos(float(world.tick) * 1.7) * kick * 0.4
	kick *= 0.82
	sever_zoom *= 0.9


func impact(strength: float, severed: bool = false) -> void:
	var incoming := minf(
		float(settings["shake_max"]), SettingsHooks.scale_amount(strength, "shake_percent")
	)
	if bool(SettingsHooks.get_value("flash_reduction")):
		incoming *= 0.35
	kick = maxf(kick, incoming)
	sever_zoom = maxf(sever_zoom, (0.55 if severed else 0.16) if kick > 0 else 0.0)
