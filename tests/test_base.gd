extends RefCounted
class_name TestBase
## Assertion helpers for the headless runner. assert_near is for presentation checks only.

var failures: Array[String] = []


func assert_true(value: bool, label: String = "") -> void:
	if not value:
		failures.append(_label(label, "expected true"))


func assert_false(value: bool, label: String = "") -> void:
	if value:
		failures.append(_label(label, "expected false"))


func assert_eq(actual: Variant, expected: Variant, label: String = "") -> void:
	if actual != expected:
		failures.append(_label(label, "expected '%s' but was '%s'" % [str(expected), str(actual)]))


func assert_near(actual: float, expected: float, epsilon: float, label: String = "") -> void:
	if absf(actual - expected) > epsilon:
		failures.append(_label(label, "expected %s ± %s but was %s" % [str(expected), str(epsilon), str(actual)]))


func assert_raises_error_logged(callback: Callable, label: String = "") -> void:
	var before := Log.error_count
	callback.call()
	if Log.error_count <= before:
		failures.append(_label(label, "expected Log.error_count to increase"))


func _label(label: String, detail: String) -> String:
	if label == "":
		return detail
	return "%s: %s" % [label, detail]
