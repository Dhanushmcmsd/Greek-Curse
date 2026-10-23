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
var catalog: Dictionary


func _ready() -> void:
	layer = 15
	var bar := HBoxContainer.new()
	bar.position = Vector2(850, 675)
	add_child(bar)
	var fresh := Button.new()
	fresh.text = "New match"
	fresh.pressed.connect(func(): new_match_requested.emit())
	bar.add_child(fresh)
	var limbs := Button.new()
	limbs.text = "Replacement limbs"
	limbs.pressed.connect(open)
	bar.add_child(limbs)
	chooser = PanelContainer.new()
	chooser.position = Vector2(400, 230)
	chooser.custom_minimum_size = Vector2(480, 370)
	add_child(chooser)
	var box := VBoxContainer.new()
	chooser.add_child(box)
	var title := Label.new()
	title.text = "NEW MATCH — REPLACEMENT LIMB"
	box.add_child(title)
	player = OptionButton.new()
	player.add_item("Player 1")
	player.add_item("Player 2")
	box.add_child(player)
	slot = OptionButton.new()
	for name in SimLimbs.LIMB_NAMES:
		slot.add_item(name)
	box.add_child(slot)
	limb = OptionButton.new()
	box.add_child(limb)
	description = Label.new()
	description.custom_minimum_size = Vector2(460, 140)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var apply := Button.new()
	apply.text = "Start new match with this limb"
	apply.pressed.connect(_apply)
	box.add_child(apply)
	var close := Button.new()
	close.text = "Cancel"
	close.pressed.connect(
		func():
			chooser.hide()
			panel_changed.emit(false)
	)
	box.add_child(close)
	slot.item_selected.connect(_populate)
	limb.item_selected.connect(_describe)
	chooser.hide()


func open() -> void:
	_populate(slot.selected)
	chooser.show()
	panel_changed.emit(true)


func _populate(index: int) -> void:
	limb.clear()
	for id in catalog:
		if SimLimbs.LIMB_NAMES[index].begins_with(str(catalog[id]["slot"])):
			limb.add_item(catalog[id]["display_name"])
			limb.set_item_metadata(limb.item_count - 1, id)
	_describe(0)


func _describe(index: int) -> void:
	description.text = "\n".join(catalog[limb.get_item_metadata(index)]["tooltip_lines"].values())


func _apply() -> void:
	chooser.hide()
	panel_changed.emit(false)
	replacement_requested.emit(
		player.selected, SimLimbs.LIMB_NAMES[slot.selected], limb.get_item_metadata(limb.selected)
	)
