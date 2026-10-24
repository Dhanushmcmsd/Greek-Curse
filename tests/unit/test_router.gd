extends TestBase


func test_transitions_reject_invalid_and_back_returns() -> void:
	var original := Router.state
	var stack := Router.stack.duplicate()
	Router.state = "main_menu"
	assert_false(Router.transition("match"), "must pass setup/banner")
	assert_true(Router.transition("settings"), "settings reachable")
	Router.back()
	assert_eq(Router.state, "main_menu", "back")
	Router.state = original
	Router.stack.assign(stack)
