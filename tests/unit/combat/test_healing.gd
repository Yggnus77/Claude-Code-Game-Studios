extends TestCase
## Healing use: startup, effect frame, recovery and interruption (mecanicas §8).


func _healing() -> Healing:
	return Healing.new({"startup": 0.65, "recovery": 0.2, "movement_factor": 0.25})


func test_restores_on_the_effect_frame_only() -> void:
	var h := _healing()
	assert_true(h.start(3), "starts")
	assert_eq(h.tick(0.6), 0, "nothing before 0.65 s")
	assert_near(h.speed_factor(), 0.25, 0.001, "slowed while using")
	assert_eq(h.tick(0.06), 3, "restores at 0.65 s")
	assert_true(h.is_busy(), "recovery follows")
	assert_eq(h.tick(0.21), 0, "no second heal")
	assert_true(not h.is_busy(), "free again")


func test_interrupt_before_effect_spends_nothing() -> void:
	var h := _healing()
	h.start(3)
	h.tick(0.3)
	h.interrupt()
	assert_true(not h.is_busy(), "cancelled")
	assert_eq(h.tick(1.0), 0, "never restores")


func test_nothing_to_use_does_not_start() -> void:
	assert_true(not _healing().start(0), "no item, no use")
