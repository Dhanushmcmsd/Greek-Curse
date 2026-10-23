extends SceneTree
## Discovers tests/**/test_*.gd and runs every func test_*().
## Usage: godot --headless --path . --script res://tests/run_all.gd -- --suite <name>


func _initialize() -> void:
	call_deferred("_execute")


func _execute() -> void:
	var code := _run()
	quit(code)


func _run() -> int:
	var log_node := root.get_node_or_null("Log")
	if log_node == null:
		print("FAIL  Log autoload is missing")
		_write_results(
			{
				"passed": 0,
				"failed": 1,
				"skipped": 0,
				"summary": "Log autoload is missing",
				"tests": [{"name": "Log", "status": "failed", "message": "autoload missing"}],
			}
		)
		return 1
	var suite := _suite_filter()
	var files := _discover("res://tests")
	files.sort()
	var results: Array[Dictionary] = []
	var passed := 0
	var failed := 0
	var skipped := 0
	for path in files:
		var file_name := path.get_file().get_basename()
		if suite != "" and suite != file_name and not path.contains(suite):
			skipped += 1
			results.append({"name": path, "status": "skipped", "message": "suite filter"})
			print("SKIP  %s" % path)
			continue
		var script := load(path) as Script
		if script == null:
			failed += 1
			results.append({"name": path, "status": "failed", "message": "script did not load"})
			print("FAIL  %s  script did not load" % path)
			continue
		var inst: Object = script.new()
		if inst == null or not inst.has_method("assert_eq"):
			failed += 1
			results.append(
				{"name": path, "status": "failed", "message": "script is not a TestBase"}
			)
			print("FAIL  %s  not a TestBase" % path)
			continue
		var names: Array[String] = []
		for info in script.get_script_method_list():
			var method_name := str(info["name"])
			if method_name.begins_with("test_"):
				names.append(method_name)
		names.sort()
		for method_name in names:
			var test_name := "%s.%s" % [file_name, method_name]
			inst.failures.clear()
			inst.call(method_name)
			if inst.failures.is_empty():
				passed += 1
				results.append({"name": test_name, "status": "passed", "message": ""})
				print("PASS  %s" % test_name)
			else:
				failed += 1
				var message := "; ".join(inst.failures)
				results.append({"name": test_name, "status": "failed", "message": message})
				print("FAIL  %s  %s" % [test_name, message])
	var summary := "Summary: %d passed, %d failed, %d skipped" % [passed, failed, skipped]
	print(summary)
	_write_results(
		{
			"passed": passed,
			"failed": failed,
			"skipped": skipped,
			"summary": summary,
			"tests": results,
		}
	)
	return 1 if failed > 0 else 0


func _suite_filter() -> String:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if str(args[i]) == "--suite" and i + 1 < args.size():
			return str(args[i + 1])
	return ""


func _discover(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			found.append(dir_path.path_join(file_name))
	for sub in DirAccess.get_directories_at(dir_path):
		if sub.begins_with("."):
			continue
		found.append_array(_discover(dir_path.path_join(sub)))
	return found


func _write_results(payload: Dictionary) -> void:
	var absolute := ProjectSettings.globalize_path("res://build")
	DirAccess.make_dir_recursive_absolute(absolute)
	var handle := FileAccess.open("res://build/test_results.json", FileAccess.WRITE)
	if handle == null:
		push_error("Could not write build/test_results.json")
		return
	handle.store_string(JSON.stringify(payload, "  "))
	handle.close()
