extends TestCase
## SwordCombo timing (mecanicas §3–4; combate.json combo).

const STEP := 1.0 / 60.0


func _combo() -> SwordCombo:
	var cfg := GameConfig.load_all()
	return SwordCombo.new(cfg.combo(), cfg.weapon_damage("espada_oficina"))


func _run(c: SwordCombo, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		c.tick(STEP)


func _swing_until_idle(c: SwordCombo) -> void:
	for i in 120:
		if not c.is_busy():
			return
		c.tick(STEP)


func test_press_starts_first_hit_next_step() -> void:
	var c := _combo()
	c.request()
	assert_true(c.tick(STEP), "a swing starts on the step after the press")
	assert_eq(c.stage, 0, "first hit")
	assert_eq(c.damage(), 1, "first hit damage 1")


func test_no_automatic_combo() -> void:
	var c := _combo()
	c.request()
	c.tick(STEP)
	_swing_until_idle(c)
	_run(c, 0.2)
	assert_true(not c.is_busy(), "without another press nothing else happens")


func test_three_presses_make_full_combo_with_finisher_damage() -> void:
	var c := _combo()
	var damages := []
	for i in 3:
		c.request()
		c.tick(STEP)
		damages.append(c.damage())
		_swing_until_idle(c)
	assert_eq(damages, [1, 1, 2], "damage per hit comes from espada_oficina")


func test_pause_resets_chain() -> void:
	var c := _combo()
	c.request()
	c.tick(STEP)
	_swing_until_idle(c)
	_run(c, 0.40)
	c.request()
	c.tick(STEP)
	assert_eq(c.stage, 0, "after 0.38 s idle the chain restarts at hit 1")


func test_each_swing_has_new_attack_id() -> void:
	var c := _combo()
	c.request()
	c.tick(STEP)
	var first := c.attack_id
	_swing_until_idle(c)
	c.request()
	c.tick(STEP)
	assert_true(c.attack_id != first and c.attack_id != 0, "second swing has a new id")


func test_buffered_press_used_once() -> void:
	var c := _combo()
	c.request()
	c.tick(STEP)
	# Press in the last 0.1 s of the first swing: buffered, used once.
	var total := 0.09 + 0.08 + 0.16
	_run(c, total - 0.1)
	c.request()
	var starts := 0
	for i in 60:
		if c.tick(STEP):
			starts += 1
	assert_eq(starts, 1, "one buffered press gives exactly one swing")
	assert_eq(c.stage, 1, "and it is the second hit")


func test_old_press_expires() -> void:
	var c := _combo()
	c.request()
	c.tick(STEP)
	c.request()  # pressed during startup: 0.12 s buffer runs out before the swing ends
	_swing_until_idle(c)
	_run(c, 0.1)
	assert_true(not c.is_busy(), "a press older than the buffer is dropped")


func test_dodge_cancel_rules() -> void:
	var c := _combo()
	c.request()
	c.tick(STEP)
	assert_true(not c.can_cancel(), "no cancel during startup")
	_run(c, 0.09 + 0.08 + STEP)
	assert_eq(c.phase, SwordCombo.Phase.RECOVERY, "in recovery")
	assert_true(c.can_cancel(), "hit 1 can be cancelled after the active window")
	_swing_until_idle(c)
	c.request(); c.tick(STEP); _swing_until_idle(c)
	c.request(); c.tick(STEP)
	assert_eq(c.stage, 2, "finisher")
	_run(c, 0.16 + 0.10 + STEP)
	assert_true(not c.can_cancel(), "finisher recovery start cannot be cancelled")
	_run(c, 0.28 - 0.10)
	assert_true(c.can_cancel(), "finisher can be cancelled in its last 0.10 s")
