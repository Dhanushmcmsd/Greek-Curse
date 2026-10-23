class_name InputBindings
extends RefCounted

var bindings: Dictionary = {}


func reset_defaults() -> void:
	var result := DataLoader.new().load_json("res://data/ui/default_bindings.json")
	if result.ok:
		bindings = result.value.duplicate(true)


func rebind(action: String, event: Dictionary) -> String:
	if not bindings.has(action):
		return "Unknown action"
	for existing in bindings:
		if existing != action and bindings[existing] == event:
			return "Conflicts with " + existing
	bindings[action] = event.duplicate(true)
	return ""


func export_bindings() -> Dictionary:
	return bindings.duplicate(true)


func import_bindings(rows: Dictionary) -> String:
	var candidate := {}
	for action in rows:
		if not rows[action] is Dictionary or not rows[action].has("key"):
			return "Invalid binding " + str(action)
		candidate[action] = rows[action].duplicate(true)
	bindings = candidate
	return ""


func install() -> void:
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var row: Dictionary = bindings[action]
		if str(row.get("key", "")) != "":
			var event := InputEventKey.new()
			event.physical_keycode = OS.find_keycode_from_string(str(row["key"]))
			InputMap.action_add_event(action, event)
		if int(row.get("button", -1)) >= 0:
			var event := InputEventJoypadButton.new()
			event.button_index = int(row["button"])
			event.device = int(row["device"])
			InputMap.action_add_event(action, event)
