extends RefCounted
class_name StateHash
## FNV-1a 64-bit over integers stored as 8 little-endian bytes each.
## The offset basis is split so the script does not need a literal above 2^63.


static func hash_ints(values: Array) -> int:
	var hash := _offset()
	for value in values:
		hash = _feed(hash, int(value))
	return hash


static func _offset() -> int:
	return (0xCBF29CE4 << 32) | 0x84222325


static func _feed(hash: int, value: int) -> int:
	var remaining := value
	for _i in 8:
		hash = _mix(hash, remaining & 255)
		remaining = remaining >> 8
	return hash


static func _mix(hash: int, byte: int) -> int:
	var mixed := (hash ^ (byte & 255)) * 1099511628211
	return mixed
