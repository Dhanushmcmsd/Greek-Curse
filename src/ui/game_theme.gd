class_name GameTheme
extends RefCounted


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = int(SettingsHooks.scale_amount(18, "ui_scale_percent"))
	for type in ["Button", "OptionButton", "PanelContainer", "LineEdit"]:
		for state in ["normal", "hover", "pressed", "focus", "panel"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("29313d") if state == "hover" else Color("141b25")
			if bool(SettingsHooks.get_value("high_contrast")):
				style.bg_color = Color.BLACK
			style.border_color = Color("f1cb7b") if state == "focus" else Color("9c7847")
			style.set_border_width_all(3 if state == "focus" else 1)
			style.set_corner_radius_all(4)
			style.content_margin_left = 16
			style.content_margin_right = 16
			style.content_margin_top = 9
			style.content_margin_bottom = 9
			theme.set_stylebox(state, type, style)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			theme.set_color(state, type, Color("f6eedb"))
	return theme
