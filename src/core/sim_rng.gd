extends RefCounted
class_name SimRng
## xorshift32. State is always masked to 32 bits. Zero is not a valid state and becomes 1.


var _state: int = 1


func _init(seed_value: int = 1) -> void:
	set_state(seed_value)


func set_state(seed_value: int) -> void:
	var masked := seed_value & 0xFFFFFFFF
	_state = 1 if masked == 0 else masked


func get_state() -> int:
	return _state & 0xFFFFFFFF


func next_u32() -> int:
	var x := _state & 0xFFFFFFFF
	x ^= (x << 13) & 0xFFFFFFFF
	x ^= (x >> 17) & 0xFFFFFFFF
	x ^= (x << 5) & 0xFFFFFFFF
	_state = x & 0xFFFFFFFF
	return _state


## Inclusive low, exclusive high. Returns low when the span is empty.
## Uses modulo, so the distribution has a small bias when the span is not a power of two.
func range_i(low: int, high: int) -> int:
	var span := high - low
	if span <= 0:
		return low
	return low + int(next_u32() % span)


## True with about p percent probability. p <= 0 is always false and p >= 100 is always true.
## Those two cases do not advance the generator.
func chance_percent(percent_chance: int) -> bool:
	if percent_chance <= 0:
		return false
	if percent_chance >= 100:
		return true
	return int(next_u32() % 100) < percent_chance
