class_name GameTheme
extends RefCounted

const BORDER = preload("res://assets/ui/kenney_fantasy/PNG/Default/Border/panel-border-008.png")
const ORNATE = preload("res://assets/ui/kenney_fantasy/PNG/Default/Border/panel-border-007.png")
const GOLD := Color("c6ad7c")
const IVORY := Color("eee6d5")

static func frame(color: Color = GOLD, ornate: bool = false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = ORNATE if ornate else BORDER
	style.modulate_color = color
	style.draw_center = false
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 12)
		style.set_content_margin(side, 18 if side in [SIDE_LEFT, SIDE_RIGHT] else 10)
	return style

static func heading_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	return font

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = int(SettingsHooks.scale_amount(18, "ui_scale_percent"))
	for type in ["Button", "OptionButton", "PanelContainer", "LineEdit", "PopupMenu"]:
		for state in ["normal", "hover", "pressed", "focus", "panel", "disabled"]:
			var color := GOLD if state in ["hover", "focus"] else Color("726c61")
			if state == "pressed":
				color = IVORY
			if state == "disabled":
				color = Color("454745")
			if bool(SettingsHooks.get_value("high_contrast")):
				color = Color.WHITE
			theme.set_stylebox(state, type, frame(color, type == "PanelContainer"))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			theme.set_color(state, type, IVORY)
		theme.set_color("font_disabled_color", type, Color("737772"))
	theme.set_color("font_color", "Label", IVORY)
	# Popup menus need an opaque backing so choices remain readable over fighters.
	var popup := StyleBoxFlat.new()
	popup.bg_color = Color("10161b")
	popup.border_color = GOLD
	popup.set_border_width_all(1)
	popup.content_margin_left = 12
	popup.content_margin_right = 12
	popup.content_margin_top = 8
	popup.content_margin_bottom = 8
	theme.set_stylebox("panel", "PopupMenu", popup)
	return theme
