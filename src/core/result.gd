class_name Result
extends RefCounted
## Success or failure without throwing. error is empty when ok is true.

var ok: bool = false
var value: Variant = null
var error: String = ""


static func success(payload: Variant) -> Result:
	var result := Result.new()
	result.ok = true
	result.value = payload
	return result


static func failure(message: String) -> Result:
	var result := Result.new()
	result.ok = false
	result.error = message
	return result
