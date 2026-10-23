extends SceneTree
## Checks every golden replay. Prints REPLAY_OK or the first mismatch.


func _initialize() -> void:
	var checker = load("res://src/presentation/replay_check.gd")
	var dir := DirAccess.open("res://tests/golden")
	if dir == null:
		print("REPLAY_FAIL no golden directory")
		quit(1)
		return
	var failed := 0
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.ends_with(".replay.json"):
			var error: String = checker.verify("res://tests/golden/%s" % name)
			if error == "":
				print("REPLAY_OK %s" % name)
			else:
				failed += 1
				print("REPLAY_FAIL %s %s" % [name, error])
		name = dir.get_next()
	dir.list_dir_end()
	quit(0 if failed == 0 else 1)
