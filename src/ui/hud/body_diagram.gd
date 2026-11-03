class_name BodyDiagram
extends Control

const STATES := {
	"healthy": ["H", "solid"],
	"bruised": ["B", "hatch"],
	"cracked": ["!", "dots"],
	"severed": ["X", "outline"]
}
var limbs: Dictionary = {}
var _textures: Dictionary = {}
var _icons: Dictionary = {}


static func display_for(state: String) -> Array:
	return STATES.get(state, ["?", "outline"])


func _ready() -> void:
	custom_minimum_size = Vector2(200, 125)
	for slot in SimLimbs.LIMB_NAMES:
		_icons[slot] = load("res://assets/ui/icons/%s.svg" % slot)
	for pattern in ["solid", "hatch", "dots", "outline"]:
		var path := "res://assets/ui/pattern_%s.png" % pattern
		if ResourceLoader.exists(path):
			_textures[pattern] = load(path)


func update_limbs(fighter: SimFighter) -> void:
	limbs = fighter.limbs.export_state()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(28, 0, 24, 18), Color(0.8, 0.75, 0.6))
	draw_rect(Rect2(24, 22, 32, 38), Color(0.5, 0.5, 0.55))
	var boxes := [
		Rect2(0, 22, 18, 42), Rect2(62, 22, 18, 42), Rect2(22, 65, 16, 48), Rect2(42, 65, 16, 48)
	]
	for i in 4:
		var slot: String = SimLimbs.LIMB_NAMES[i]
		if not limbs.has(slot):
			continue
		var row: Dictionary = limbs[slot]
		var display := display_for(row["state"])
		if _icons.has(slot):
			draw_texture_rect(_icons[slot], Rect2(82, 4 + i * 24, 18, 18), false)
		var rect: Rect2 = boxes[i]
		draw_rect(rect, Color(0.12, 0.14, 0.18))
		var fill := rect
		fill.size.y *= float(row["integrity"]) / maxf(1.0, float(row["max_integrity"]))
		draw_rect(fill, Color(0.75, 0.58, 0.3))
		if _textures.has(display[1]):
			draw_texture_rect(_textures[display[1]], rect, true)
		draw_rect(rect, Color.WHITE, false, 1)
		draw_string(
			font, rect.position + Vector2(3, 18), display[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15
		)
		draw_string(
			font,
			Vector2(104, 20 + i * 24),
			(
				"%s %s"
				% [
					slot,
					(
						"DETACHED"
						if row["state"] == "severed"
						else "FRACTURE" if row["state"] == "cracked" else str(row["integrity"])
					)
				]
			),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14
		)
