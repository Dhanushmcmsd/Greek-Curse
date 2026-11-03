class_name StateHash
extends RefCounted
## FNV-1a 64-bit over integers stored as 8 little-endian bytes each.
## The offset basis is split so the script does not need a literal above 2^63.


static func hash_ints(values: Array) -> int:
	var hash_value := _offset()
	for value in values:
		hash_value = _feed(hash_value, int(value))
	return hash_value


static func hash_string(value: String) -> int:
	var hash_value := _offset()
	for byte in value.to_utf8_buffer():
		hash_value = _mix(hash_value, byte)
	return hash_value


static func _offset() -> int:
	return (0xCBF29CE4 << 32) | 0x84222325


static func _feed(hash_value: int, value: int) -> int:
	var remaining := value
	for _i in 8:
		hash_value = _mix(hash_value, remaining & 255)
		remaining = remaining >> 8
	return hash_value


static func _mix(hash_value: int, byte: int) -> int:
	var mixed := (hash_value ^ (byte & 255)) * 1099511628211
	return mixed
