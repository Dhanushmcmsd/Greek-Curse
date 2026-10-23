extends Node
## Project log. Autoload name: Log.
## Levels, a category, a timestamp, a ring buffer, and a file under user://logs.
## ERROR lines increment error_count for the test runner.

enum Level { DEBUG, INFO, WARN, ERROR }

const RING_MAX := 200

var error_count: int = 0
var _ring: Array[String] = []
var _sink: FileAccess


func _ready() -> void:
	var absolute := ProjectSettings.globalize_path("user://logs")
	DirAccess.make_dir_recursive_absolute(absolute)
	_sink = FileAccess.open("user://logs/severed.log", FileAccess.READ_WRITE)
	if _sink == null:
		_sink = FileAccess.open("user://logs/severed.log", FileAccess.WRITE)
	elif _sink.get_length() > 0:
		_sink.seek_end()


func debug(category: String, message: String) -> void:
	write(Level.DEBUG, category, message)


func info(category: String, message: String) -> void:
	write(Level.INFO, category, message)


func warn(category: String, message: String) -> void:
	write(Level.WARN, category, message)


func error(category: String, message: String) -> void:
	write(Level.ERROR, category, message)


func write(level: Level, category: String, message: String) -> void:
	var level_name := str(Level.keys()[level])
	var line := "%s [%s] %s: %s" % [Time.get_datetime_string_from_system(), level_name, category, message]
	_ring.append(line)
	if _ring.size() > RING_MAX:
		_ring.pop_front()
	if level == Level.ERROR:
		error_count += 1
	if _sink != null:
		_sink.store_line(line)
		_sink.flush()
	print(line)


func get_ring() -> Array[String]:
	return _ring.duplicate()
