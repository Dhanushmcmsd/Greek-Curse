class_name SettingsHooks
extends RefCounted

static var values: Dictionary = {
	"shake_percent": 100,
	"hitstop_percent": 100,
	"flash_reduction": false,
	"gore": "normal",
	"blood_color": "red",
	"ui_scale_percent": 100,
	"subtitles": true
}


static func get_value(key: String) -> Variant:
	return values.get(key)


static func scale_amount(value: float, key: String) -> float:
	return value * clampf(float(values.get(key, 100)), 0.0, 200.0) / 100.0
