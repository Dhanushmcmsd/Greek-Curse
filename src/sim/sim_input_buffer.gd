class_name SimInputBuffer
extends RefCounted
## Rising attack and dodge edges, kept for the data-driven buffer window.

var previous: int = 0
var bits: Array[int] = []
var ticks: Array[int] = []
var directions: Array[int] = []


func push(mask: int, tick: int, window: int) -> void:
	var rose := mask & ~previous
	previous = mask
	var kept_bits: Array[int] = []
	var kept_ticks: Array[int] = []
	var kept_directions: Array[int] = []
	for index in bits.size():
		if tick - ticks[index] <= window:
			kept_bits.append(bits[index])
			kept_ticks.append(ticks[index])
			kept_directions.append(directions[index])
	for bit in SimInput.ATTACK_BITS + [SimInput.DODGE]:
		if (rose & bit) != 0:
			kept_bits.append(bit)
			kept_ticks.append(tick)
			kept_directions.append(mask & (SimInput.LEFT | SimInput.RIGHT | SimInput.DOWN))
	bits = kept_bits
	ticks = kept_ticks
	directions = kept_directions


func has_edge(bit: int, tick: int, window: int) -> bool:
	for index in bits.size():
		if bits[index] == bit and tick - ticks[index] <= window:
			return true
	return false


func consume(bit: int) -> void:
	var kept_bits: Array[int] = []
	var kept_ticks: Array[int] = []
	var kept_directions: Array[int] = []
	for index in bits.size():
		if bits[index] != bit:
			kept_bits.append(bits[index])
			kept_ticks.append(ticks[index])
			kept_directions.append(directions[index])
	bits = kept_bits
	ticks = kept_ticks
	directions = kept_directions


func hash_values() -> Array:
	var values: Array = [previous]
	for index in bits.size():
		values.append(bits[index])
		values.append(ticks[index])
		values.append(directions[index])
	return values


func direction_for(bit: int) -> int:
	for index in bits.size():
		if bits[index] == bit:
			return directions[index]
	return 0
