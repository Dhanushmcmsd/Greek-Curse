extends TestBase


func test_sign_abs_and_clamp() -> void:
	assert_eq(Fx.sign_i(-4), -1, "sign negative")
	assert_eq(Fx.sign_i(0), 0, "sign zero")
	assert_eq(Fx.sign_i(9), 1, "sign positive")
	assert_eq(Fx.abs_i(-5), 5, "abs negative")
	assert_eq(Fx.abs_i(5), 5, "abs positive")
	assert_eq(Fx.clamp_i(-1, 0, 10), 0, "clamp low")
	assert_eq(Fx.clamp_i(11, 0, 10), 10, "clamp high")
	assert_eq(Fx.clamp_i(4, 0, 10), 4, "clamp inside")


func test_mul_div_rounds_half_away_from_zero() -> void:
	assert_eq(Fx.mul_div(1, 1, 2), 1, "positive half")
	assert_eq(Fx.mul_div(-1, 1, 2), -1, "negative half")
	assert_eq(Fx.mul_div(1, 1, 3), 0, "positive below half")
	assert_eq(Fx.mul_div(-1, 1, 3), 0, "negative below half")
	assert_eq(Fx.mul_div(5, 1, 2), 3, "2.5 away from zero")
	assert_eq(Fx.mul_div(-5, 2, 4), -3, "negative 2.5")
	assert_eq(Fx.mul_div(1, 2, -4), -1, "negative divisor")
	assert_eq(Fx.mul_div(4, 2, 0), 0, "zero divisor")


func test_mul_div_large_product_fits_in_64_bit() -> void:
	assert_eq(Fx.mul_div(1000000, 1000000, 1), 1000000000000, "1e6 squared")
	assert_eq(Fx.mul_div(1000000, 1000000, 1000000), 1000000, "cancel")


func test_percent_exact_cases() -> void:
	assert_eq(Fx.percent(300, 0), 0, "zero percent")
	assert_eq(Fx.percent(300, 100), 300, "full percent")
	assert_eq(Fx.percent(200, 50), 100, "half")
	assert_eq(Fx.percent(1, 50), 1, "half rounds away from zero")
	assert_eq(Fx.percent(-1, 50), -1, "negative half percent")


func test_lerp_and_tick_conversion() -> void:
	assert_eq(Fx.lerp_i(0, 10, 1, 2), 5, "midpoint")
	assert_eq(Fx.lerp_i(0, 1, 1, 2), 1, "lerp half away from zero")
	assert_eq(Fx.ticks_from_ms(1000), 60, "one second")
	assert_eq(Fx.ticks_from_ms(500), 30, "half second")
	assert_eq(Fx.ticks_from_seconds_x100(150), 90, "1.50 seconds")
	assert_eq(Fx.ticks_from_seconds_x100(100), 60, "1.00 second")
	assert_eq(Fx.TICKS_PER_SECOND, 60, "constant")
	assert_eq(Fx.MM_PER_M, 1000, "millimetres")


func test_isqrt_sample_through_one_million() -> void:
	assert_eq(Fx.isqrt(0), 0, "sqrt 0")
	assert_eq(Fx.isqrt(-4), 0, "sqrt negative")
	assert_eq(Fx.isqrt(1), 1, "sqrt 1")
	assert_eq(Fx.isqrt(15), 3, "sqrt 15")
	assert_eq(Fx.isqrt(16), 4, "sqrt 16")
	assert_eq(Fx.isqrt(1000000), 1000, "sqrt 1e6")
	var n := 0
	while n <= 1000000:
		var root := Fx.isqrt(n)
		assert_true(root * root <= n, "floor at %d" % n)
		assert_true((root + 1) * (root + 1) > n, "next square at %d" % n)
		n += 1000
