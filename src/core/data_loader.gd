extends RefCounted
class_name DataLoader
## Loads JSON from res:// and checks the stage 02 schema subset.
## Godot parses every JSON number as a float. Integer schema fields are converted
## to int before the value is returned. Failures are logged and not cached.

var _cache: Dictionary = {}


func load_json(resource_path: String, schema_path: String = "") -> Result:
	if _cache.has(resource_path) and schema_path == "":
		return _cache[resource_path]
	if not FileAccess.file_exists(resource_path):
		return _fail(resource_path, "file not found")
	var text := FileAccess.get_file_as_string(resource_path)
	var parser := JSON.new()
	var parse_error := parser.parse(text)
	if parse_error != OK:
		return _fail(resource_path, "malformed JSON at line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
	var payload: Variant = parser.data
	var resolved_schema := schema_path
	if resolved_schema == "":
		resolved_schema = _inferred_schema(resource_path)
	if resolved_schema != "" and FileAccess.file_exists(resolved_schema):
		var schema_text := FileAccess.get_file_as_string(resolved_schema)
		var schema_parser := JSON.new()
		if schema_parser.parse(schema_text) != OK:
			return _fail(resource_path, "malformed schema %s" % resolved_schema)
		var schema: Dictionary = schema_parser.data
		var errors: Array[String] = []
		var normalized: Variant = _check(payload, schema, "", errors)
		if not errors.is_empty():
			return _fail(resource_path, "; ".join(errors))
		payload = normalized
	var result := Result.success(payload)
	if schema_path == "":
		_cache[resource_path] = result
	return result


func _inferred_schema(resource_path: String) -> String:
	const prefix := "res://data/"
	if not resource_path.begins_with(prefix) or resource_path.contains("/schema/"):
		return ""
	var relative := resource_path.substr(prefix.length())
	var slash := relative.rfind("/")
	var directory := "" if slash == -1 else relative.substr(0, slash + 1)
	var stem := relative.get_file().get_basename()
	return "res://data/schema/%s%s.schema.json" % [directory, stem]


func _fail(resource_path: String, message: String) -> Result:
	var full := "%s: %s" % [resource_path, message]
	Log.error("data", full)
	return Result.failure(full)


func _check(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> Variant:
	var expected := str(schema.get("type", ""))
	if expected != "" and not _type_ok(value, expected):
		errors.append("%s: expected %s" % [path if path != "" else "/", expected])
		return value
	if schema.has("enum"):
		var allowed: Array = schema["enum"]
		if not allowed.has(value):
			errors.append("%s: value is not in enum" % path)
	if (expected == "integer" or expected == "number") and (schema.has("minimum") or schema.has("maximum")):
		var number := float(value)
		if schema.has("minimum") and number < float(schema["minimum"]):
			errors.append("%s: below minimum" % path)
		if schema.has("maximum") and number > float(schema["maximum"]):
			errors.append("%s: above maximum" % path)
	if expected == "integer":
		return int(value)
	if expected == "object":
		var source: Dictionary = value
		var cleaned := {}
		for key in schema.get("required", []):
			if not source.has(key):
				errors.append("%s/%s: missing required property" % [path, str(key)])
		var properties: Dictionary = schema.get("properties", {})
		for key in source.keys():
			if properties.has(key):
				cleaned[key] = _check(source[key], properties[key], "%s/%s" % [path, str(key)], errors)
			else:
				cleaned[key] = source[key]
		return cleaned
	if expected == "array" and schema.has("items"):
		var items: Array = value
		var cleaned_items: Array = []
		for index in items.size():
			cleaned_items.append(_check(items[index], schema["items"], "%s/%d" % [path, index], errors))
		return cleaned_items
	return value


func _type_ok(value: Variant, expected: String) -> bool:
	match expected:
		"object":
			return value is Dictionary
		"array":
			return value is Array
		"string":
			return value is String
		"boolean":
			return value is bool
		"integer":
			return _is_whole_number(value)
		"number":
			return value is int or value is float
		_:
			return true


func _is_whole_number(value: Variant) -> bool:
	if value is bool:
		return false
	if value is int:
		return true
	if value is float:
		return value == float(int(value))
	return false
