class_name Fx
extends RefCounted
## Integer helpers for the combat simulation.
## Division rounds half away from zero. Products must fit in a signed 64-bit integer.

const TICKS_PER_SECOND: int = 60
const MM_PER_M: int = 1000


static func abs_i(value: int) -> int:
	return -value if value < 0 else value


static func sign_i(value: int) -> int:
	if value < 0:
		return -1
	if value > 0:
		return 1
	return 0


static func clamp_i(value: int, low: int, high: int) -> int:
	if value < low:
		return low
	if value > high:
		return high
	return value


## (a * b) / c, rounded half away from zero. Returns 0 when c is 0.
static func mul_div(a: int, b: int, c: int) -> int:
	if c == 0:
		return 0
	var negative := (a < 0) != (b < 0)
	if c < 0:
		negative = not negative
	var numerator := abs_i(a) * abs_i(b)
	var denominator := abs_i(c)
	var rounded := (numerator + (denominator >> 1)) / denominator
	return -rounded if negative else rounded


## value * pct / 100, same rounding as mul_div. pct is a whole percent.
static func percent(value: int, pct: int) -> int:
	return mul_div(value, pct, 100)


## from + (to - from) * num / den.
static func lerp_i(from: int, to: int, numerator: int, denominator: int) -> int:
	return from + mul_div(to - from, numerator, denominator)


## Floor of the square root. Negative inputs return 0.
static func isqrt(value: int) -> int:
	if value <= 0:
		return 0
	var x := value
	var y := (x + 1) >> 1
	while y < x:
		x = y
		y = (x + int(value / x)) >> 1
	return x


## Milliseconds to 60 Hz ticks.
static func ticks_from_ms(milliseconds: int) -> int:
	return mul_div(milliseconds, TICKS_PER_SECOND, 1000)


## Seconds times 100 (150 means 1.50 s) to 60 Hz ticks.
static func ticks_from_seconds_x100(seconds_x100: int) -> int:
	return mul_div(seconds_x100, TICKS_PER_SECOND, 100)
