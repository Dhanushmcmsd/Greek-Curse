class_name HudPrototype
extends CanvasLayer
## Health, timer, round pips, and the round banner. Read-only.

var _left_fill: ColorRect
var _right_fill: ColorRect
var _timer: Label
var _pips: Label
var _banner: Label
var _hint: Label


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	for area in [Rect2(0, 0, 1280, 180), Rect2(0, 632, 1280, 88)]:
		var shade := ColorRect.new()
		shade.position = area.position
		shade.size = area.size
		shade.color = Color(0.035, 0.045, 0.065, 0.85)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(shade)
	_left_fill = _bar(root, 40.0, Color(0.75, 0.28, 0.16))
	_right_fill = _bar(root, 760.0, Color(0.2, 0.48, 0.32))
	_timer = _label(root, 520.0, 36.0, 240.0, "1:30")
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pips = _label(root, 40.0, 78.0, 1200.0, "Rounds")
	_banner = _label(root, 340.0, 180.0, 600.0, "Round 1")
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint = _label(root, 40.0, 640.0, 1200.0, "Press R to restart")


func show_match(world: SimWorld, banner: String) -> void:
	var max_health := maxi(world.max_health, 1)
	_set_bar(_left_fill, world.fighters[0].health, max_health)
	_set_bar(_right_fill, world.fighters[1].health, max_health)
	var seconds := (world.round_ticks - world.round_tick) / 60
	if seconds < 0:
		seconds = 0
	_timer.text = "%d:%02d" % [seconds / 60, seconds % 60]
	_pips.text = (
		"%s  %d   |   %d  %s"
		% [
			world.fighters[0].display_name,
			world.wins[0],
			world.wins[1],
			world.fighters[1].display_name,
		]
	)
	_banner.text = banner


func _set_bar(fill: ColorRect, health: int, max_health: int) -> void:
	var width := 400.0 * float(health) / float(max_health)
	fill.size = Vector2(width, 28.0)


func _bar(root: Control, x: float, color: Color) -> ColorRect:
	var back := ColorRect.new()
	back.position = Vector2(x, 28.0)
	back.size = Vector2(400.0, 28.0)
	back.color = Color(0.1, 0.1, 0.1, 0.8)
	root.add_child(back)
	var fill := ColorRect.new()
	fill.position = Vector2(x, 28.0)
	fill.size = Vector2(400.0, 28.0)
	fill.color = color
	root.add_child(fill)
	return fill


func _label(root: Control, x: float, y: float, width: float, text: String) -> Label:
	var label := Label.new()
	label.position = Vector2(x, y)
	label.size = Vector2(width, 40.0)
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	root.add_child(label)
	return label
