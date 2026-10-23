extends TestBase


func test_valid_smoke_file_converts_integer_fields() -> void:
	var loader := DataLoader.new()
	var result := loader.load_json("res://data/smoke.json")
	assert_true(result.ok, result.error)
	assert_eq(result.value["name"], "severed-smoke", "name")
	assert_eq(result.value["ticks"], 60, "ticks")
	assert_eq(typeof(result.value["ticks"]), TYPE_INT, "ticks type")


func test_second_load_uses_the_cache() -> void:
	var loader := DataLoader.new()
	var first := loader.load_json("res://data/smoke.json")
	var second := loader.load_json("res://data/smoke.json")
	assert_true(first.ok and second.ok, "both ok")
	assert_eq(second.value["ticks"], first.value["ticks"], "cached ticks")


func test_missing_file_returns_error_and_logs() -> void:
	var before := Log.error_count
	var result := DataLoader.new().load_json("res://data/missing_file.json")
	assert_false(result.ok, "missing is not ok")
	assert_true(result.error.contains("res://data/missing_file.json"), result.error)
	assert_eq(Log.error_count, before + 1, "ERROR logged")


func test_malformed_json_does_not_crash() -> void:
	var before := Log.error_count
	var result := DataLoader.new().load_json("res://tests/assets/malformed.json")
	assert_false(result.ok, "malformed is not ok")
	assert_true(result.error.contains("malformed JSON"), result.error)
	assert_eq(Log.error_count, before + 1, "ERROR logged")


func test_schema_violation_names_the_field() -> void:
	var before := Log.error_count
	var result := DataLoader.new().load_json(
		"res://tests/assets/sample_bad.json", "res://tests/assets/sample.schema.json"
	)
	assert_false(result.ok, "schema failure")
	assert_true(result.error.contains("/name") or result.error.contains("/ticks"), result.error)
	assert_eq(Log.error_count, before + 1, "ERROR logged")
