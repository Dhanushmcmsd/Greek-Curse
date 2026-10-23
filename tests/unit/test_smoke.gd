extends TestBase
## Proves the log autoload, the runner, and the 60 Hz project setting.


func test_log_info_does_not_count_as_error() -> void:
	var before := Log.error_count
	Log.info("smoke", "info line")
	assert_eq(Log.error_count, before, "info leaves error_count unchanged")


func test_log_error_increments_counter() -> void:
	var before := Log.error_count
	Log.error("smoke", "expected error")
	assert_eq(Log.error_count, before + 1, "error_count")
	assert_true(Log.get_ring().size() > 0, "ring buffer received the line")


func test_logged_error_is_visible_to_helper() -> void:
	assert_raises_error_logged(
		func() -> void: Log.error("smoke", "helper error"), "helper sees ERROR"
	)


func test_physics_ticks_per_second_is_60() -> void:
	var ticks := int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	assert_eq(ticks, 60, "physics ticks")
