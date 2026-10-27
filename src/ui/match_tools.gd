class_name MatchTools
extends CanvasLayer

signal new_match_requested
signal replacement_requested(player: int, slot: String, id: String)
signal panel_changed(shown: bool)

var chooser: PanelContainer
var player: OptionButton
var slot: OptionButton
var limb: OptionButton
var description: Label
var model_ids: Array[String] = ["theron", "atalanta"]
var catalog: Dictionary
var bar: HBoxContainer
var cards: HBoxContainer
var _combo_panel: PanelContainer
var _tab_bar: HBoxContainer
var _limb_tab: Button
var _combo_tab: Button


func _ready() -> void:
	call_deferred("_apply_theme")
	for child in get_children():
		if child is Control:
			child.theme = GameTheme.build()
	layer = 15
	bar = HBoxContainer.new()
	bar.position = Vector2(850, 675)
	add_child(bar)
	var fresh := Button.new()
	fresh.text = "New match"
	fresh.pressed.connect(func(): new_match_requested.emit())
	bar.add_child(fresh)
	var limbs_btn := Button.new()
	limbs_btn.text = "Replacement limbs"
	limbs_btn.pressed.connect(open)
	bar.add_child(limbs_btn)
	var combo_btn := Button.new()
	combo_btn.text = "Combo list"
	combo_btn.pressed.connect(open_combos)
	bar.add_child(combo_btn)
	_build_limb_panel()
	_build_combo_panel()


func _build_limb_panel() -> void:
	chooser = PanelContainer.new()
	chooser.position = Vector2.ZERO
	chooser.size = Vector2(1280, 720)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("101722")
	background.content_margin_left = 100
	background.content_margin_right = 100
	background.content_margin_top = 35
	background.content_margin_bottom = 30
	chooser.add_theme_stylebox_override("panel", background)
	add_child(chooser)
	var scroll := ScrollContainer.new()
	chooser.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	var title := Label.new()
	title.text = "THE FORGE  /  REPLACEMENT LIMBS"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("e4bc6b"))
	box.add_child(title)
	var row := HBoxContainer.new()
	box.add_child(row)
	player = OptionButton.new()
	player.add_item("Player 1")
	player.add_item("Player 2")
	player.custom_minimum_size.x = 200
	row.add_child(player)
	slot = OptionButton.new()
	for name in ["Left arm", "Right arm", "Left leg", "Right leg"]:
		slot.add_item(name)
	slot.custom_minimum_size.x = 250
	row.add_child(slot)
	limb = OptionButton.new()
	limb.hide()
	box.add_child(limb)
	cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 20)
	box.add_child(cards)
	description = Label.new()
	description.custom_minimum_size = Vector2(900, 140)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 18)
	box.add_child(description)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	var apply := Button.new()
	apply.text = "Equip and start new match"
	apply.custom_minimum_size = Vector2(440, 52)
	apply.pressed.connect(_apply)
	actions.add_child(apply)
	var close := Button.new()
	close.text = "Back"
	close.custom_minimum_size = Vector2(180, 52)
	close.pressed.connect(close_panel)
	actions.add_child(close)
	player.item_selected.connect(func(_index: int): _populate(slot.selected))
	slot.item_selected.connect(_populate)
	limb.item_selected.connect(_describe)
	chooser.hide()


func _build_combo_panel() -> void:
	_combo_panel = PanelContainer.new()
	_combo_panel.position = Vector2.ZERO
	_combo_panel.size = Vector2(1280, 720)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("0d1520")
	bg.content_margin_left = 80
	bg.content_margin_right = 80
	bg.content_margin_top = 30
	bg.content_margin_bottom = 30
	_combo_panel.add_theme_stylebox_override("panel", bg)
	add_child(_combo_panel)
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	_combo_panel.add_child(outer)
	var header_row := HBoxContainer.new()
	outer.add_child(header_row)
	var title := Label.new()
	title.text = "MOVE LIST  /  COMBOS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("e4bc6b"))
	header_row.add_child(title)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(140, 44)
	close.pressed.connect(close_panel)
	header_row.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for hdr in ["Move", "Category", "Hits", "Damage", "Cancel into"]:
		var h := Label.new()
		h.text = hdr
		h.add_theme_color_override("font_color", Color("88aacc"))
		h.add_theme_font_size_override("font_size", 14)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(h)
	_combo_panel.set_meta("grid", grid)
	_combo_panel.hide()


func populate_combos(move_rows: Array) -> void:
	var grid: GridContainer = _combo_panel.get_meta("grid")
	for child in grid.get_children():
		if child is Label and child.get_meta("data_row", false):
			grid.remove_child(child)
			child.queue_free()
	for row in move_rows:
		var name_lbl := Label.new()
		name_lbl.text = str(row.get("display_name", row.get("id", "?")))
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.set_meta("data_row", true)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cat_lbl := Label.new()
		cat_lbl.text = str(row.get("category", "-"))
		cat_lbl.set_meta("data_row", true)
		var hits_lbl := Label.new()
		hits_lbl.text = str(row.get("hit_count", 1))
		hits_lbl.set_meta("data_row", true)
		hits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var dmg_lbl := Label.new()
		dmg_lbl.text = str(row.get("damage", "-"))
		dmg_lbl.set_meta("data_row", true)
		dmg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var cancel_ids: Array = row.get("cancel_into", [])
		var cancel_lbl := Label.new()
		cancel_lbl.text = ", ".join(cancel_ids) if not cancel_ids.is_empty() else "—"
		cancel_lbl.set_meta("data_row", true)
		cancel_lbl.add_theme_color_override(
			"font_color", Color("66cc88") if not cancel_ids.is_empty() else Color("555555")
		)
		cancel_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cancel_lbl.custom_minimum_size.x = 220
		for lbl in [name_lbl, cat_lbl, hits_lbl, dmg_lbl, cancel_lbl]:
			grid.add_child(lbl)


func open() -> void:
	_populate(slot.selected)
	chooser.show()
	_combo_panel.hide()
	bar.hide()
	panel_changed.emit(true)
	player.grab_focus()


func open_combos() -> void:
	chooser.hide()
	_combo_panel.show()
	bar.hide()
	panel_changed.emit(true)


func close_panel() -> void:
	chooser.hide()
	_combo_panel.hide()
	bar.show()
	panel_changed.emit(false)


func _populate(index: int) -> void:
	limb.clear()
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	for id in catalog:
		if SimLimbs.LIMB_NAMES[index].begins_with(str(catalog[id]["slot"])):
			var item := limb.item_count
			limb.add_item(catalog[id]["display_name"])
			limb.set_item_metadata(item, id)
			var card := LimbCard.new()
			cards.add_child(card)
			card.setup(
				id,
				catalog[id]["display_name"],
				model_ids[player.selected],
				SimLimbs.LIMB_NAMES[index]
			)
			card.pressed.connect(_describe.bind(item))
	_describe(0)


func _describe(index: int) -> void:
	limb.select(index)
	for i in cards.get_child_count():
		cards.get_child(i).modulate = Color.WHITE if i == index else Color(0.6, 0.65, 0.75)
	description.text = (
		"Elemental appearance matches your fighter. Choose a combat perk below.\n"
		+ "\n".join(catalog[limb.get_item_metadata(index)]["tooltip_lines"].values())
	)


func _apply() -> void:
	chooser.hide()
	panel_changed.emit(false)
	replacement_requested.emit(
		player.selected, SimLimbs.LIMB_NAMES[slot.selected], limb.get_item_metadata(limb.selected)
	)


func _apply_theme() -> void:
	for child in get_children():
		if child is Control:
			child.theme = GameTheme.build()
