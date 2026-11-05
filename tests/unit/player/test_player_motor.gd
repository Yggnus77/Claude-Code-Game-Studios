extends TestCase
## Unit tests for PlayerMotor (design/kit/mecanicas-e-dificuldade.md §2).

const STEP := 1.0 / 60.0


func _params() -> Dictionary:
	return GameConfig.load_from().player()


func _run(motor: PlayerMotor, input: Vector2, seconds: float) -> Vector2:
	var v := Vector2.ZERO
	for i in int(round(seconds / STEP)):
		v = motor.step(v, input, STEP)
	return v


func test_reads_speed_from_data() -> void:
	var motor := PlayerMotor.new(_params())
	assert_eq(motor.speed, 110.0, "walking speed comes from combate.json")
	assert_eq(motor.acceleration, 1400.0, "acceleration comes from combate.json")
	assert_eq(motor.deceleration, 1800.0, "deceleration comes from combate.json")


func test_diagonal_is_not_faster() -> void:
	var motor := PlayerMotor.new(_params())
	var straight := _run(motor, Vector2.RIGHT, 1.0).length()
	var diagonal := _run(motor, Vector2(1, 1), 1.0).length()
	assert_near(straight, 110.0, 0.01, "straight walking reaches top speed")
	assert_true(diagonal <= straight + 0.001, "diagonal speed %.3f must not exceed %.3f" % [diagonal, straight])


func test_reaches_top_speed_quickly() -> void:
	var motor := PlayerMotor.new(_params())
	# 110 / 1400 = 0.0786 s, so five physics steps (0.083 s) are enough.
	var v := _run(motor, Vector2.LEFT, 5.0 * STEP)
	assert_near(v.length(), 110.0, 0.01, "top speed within 5 physics steps")
	var first := motor.step(Vector2.ZERO, Vector2.LEFT, STEP)
	assert_true(first.length() > 0.0, "movement starts on the first physics step")


func test_stops_when_released() -> void:
	var motor := PlayerMotor.new(_params())
	var v := Vector2(110, 0)
	for i in 4:
		v = motor.step(v, Vector2.ZERO, STEP)
	assert_eq(v, Vector2.ZERO, "stops within 4 physics steps (110 / 1800 s)")


func test_facing_follows_dominant_axis() -> void:
	var motor := PlayerMotor.new(_params())
	motor.step(Vector2.ZERO, Vector2(0.9, 0.3), STEP)
	assert_eq(motor.facing, Vector2.RIGHT, "mostly right faces right")
	motor.step(Vector2.ZERO, Vector2(-0.2, -0.8), STEP)
	assert_eq(motor.facing, Vector2.UP, "mostly up faces up")


func test_diagonal_tie_keeps_last_facing() -> void:
	var motor := PlayerMotor.new(_params())
	motor.step(Vector2.ZERO, Vector2.LEFT, STEP)
	motor.step(Vector2.ZERO, Vector2(1, 1), STEP)
	assert_eq(motor.facing, Vector2.LEFT, "exact diagonal keeps previous facing")


func test_speed_factor_scales_top_speed() -> void:
	var motor := PlayerMotor.new(_params())
	var v := Vector2.ZERO
	for i in 60:
		v = motor.step(v, Vector2.DOWN, STEP, 0.45)
	assert_near(v.length(), 49.5, 0.01, "guard walks at 45% speed")
