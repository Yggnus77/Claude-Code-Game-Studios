extends TestCase
## Health: damage, invulnerability, death (mecanicas §6).


func test_invulnerability_blocks_second_contact_same_step() -> void:
	var h := Health.new(6, 0.75)
	assert_true(h.take_damage(1), "first contact applies")
	assert_true(not h.take_damage(1), "second contact in the same step is ignored")
	assert_eq(h.current, 5, "only one point lost")


func test_invulnerability_expires() -> void:
	var h := Health.new(6, 0.75)
	h.take_damage(1)
	h.tick(0.74)
	assert_true(h.is_invulnerable(), "still invulnerable at 0.74 s")
	h.tick(0.02)
	assert_true(h.take_damage(1), "can be hit again after 0.75 s")
	assert_eq(h.current, 4, "two points lost in total")


func test_death_and_reset() -> void:
	var h := Health.new(2, 0.0)
	var died := [false]
	h.died.connect(func() -> void: died[0] = true)
	h.take_damage(3)
	assert_eq(h.current, 0, "life never goes below zero")
	assert_true(died[0], "died is emitted")
	assert_true(not h.take_damage(1), "no damage after death")
	h.reset()
	assert_eq(h.current, 2, "reset restores full life")
