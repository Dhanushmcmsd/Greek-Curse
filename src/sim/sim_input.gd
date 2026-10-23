class_name SimInput
extends RefCounted
## One integer bitmask per fighter per tick. Bits are the whole input contract.

const LEFT := 1
const RIGHT := 2
const UP := 4
const DOWN := 8
const LIGHT := 16
const HEAVY := 32
const KICK := 64
const BLOCK := 128
const DODGE := 256
const SUPER := 512
const ULTIMATE := 1024


static func has_bit(mask: int, bit: int) -> bool:
	return (mask & bit) != 0
