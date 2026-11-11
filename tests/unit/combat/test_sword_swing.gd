extends TestCase
## Unit: the classic sword (design/gdd/jogabilidade-classica.md §3.1–3.2, §4).

const STEP := 1.0 / 60.0


func _sword() -> SwordSwing:
	var cfg := GameConfig.load_from()
	return SwordSwing.new(cfg.sword(), cfg.weapon_damage("espada_oficina"))


## Runs [param s] for [param seconds]; returns the events it reported.
func _run(s: SwordSwing, seconds: float) -> Array:
	var events := []
	for i in int(round(seconds / STEP)):
		var e := s.tick(STEP)
		if not e.is_empty():
			events.append(e)
	return events


func test_the_data_matches_the_design_numbers() -> void:
	var s := _sword()
	assert_near(s.reach, 27.0, 0.001, "reach 27 px")
	assert_near(s.charge_time, 0.75, 0.001, "charge 0.75 s")
	assert_near(rad_to_deg(s.arc_to - s.arc_from), 175.0, 0.01, "a 175° arc")
	assert_eq(s.damage_base, 1, "workshop sword: 1 per swing")
	assert_eq(s.spin_damage_factor, 2, "the spin doubles it")


func test_a_press_swings_once_and_ends() -> void:
	var s := _sword()
	s.press()
	assert_eq(s.tick(STEP), "swing", "starts on the next step")
	var total := s.swing_startup + s.swing_active + s.swing_recovery
	_run(s, total + 0.05)
	assert_true(not s.is_busy(), "one press, one swing (%.2f s)" % total)
	assert_eq(_run(s, 0.3), [], "no second swing")


func test_the_blade_sweeps_the_whole_arc_once() -> void:
	var s := _sword()
	s.press()
	s.tick(STEP)
	var lo := INF
	var hi := -INF
	var cut_steps := 0
	while s.is_busy():
		s.tick(STEP)
		if s.is_cutting():
			cut_steps += 1
			lo = minf(lo, minf(s.sweep().x, s.sweep().y))
			hi = maxf(hi, maxf(s.sweep().x, s.sweep().y))
	assert_near(lo, s.arc_from, 0.001, "from the start of the arc")
	assert_near(hi, s.arc_to, 0.001, "to its end")
	assert_true(cut_steps >= 7, "cuts for the active window (%d steps)" % cut_steps)


func test_holding_charges_and_releasing_full_spins() -> void:
	var s := _sword()
	s.press()
	s.set_held(true)
	var events := _run(s, 0.3)
	assert_true(s.is_charging(), "held after the swing: charging")
	events.append_array(_run(s, s.charge_time))
	assert_true(events.has("charged"), "the charge fills (%s)" % [events])
	assert_true(s.is_charged(), "charged")
	s.set_held(false)
	assert_eq(s.tick(STEP), "spin", "release: spin")
	assert_eq(s.damage(), 2, "spin damage 1 × 2")
	assert_near(s.current_reach(), s.spin_reach, 0.001, "spin reaches further")
	var lo := INF
	var hi := -INF
	while s.is_busy():
		s.tick(STEP)
		lo = minf(lo, s.sweep().x)
		hi = maxf(hi, s.sweep().y)
	assert_true(hi - lo >= TAU, "a full turn (%.0f°)" % rad_to_deg(hi - lo))


func test_releasing_early_does_not_spin() -> void:
	var s := _sword()
	s.press()
	s.set_held(true)
	_run(s, 0.3 + s.charge_time * 0.5)
	assert_true(s.is_charging() and not s.is_charged(), "half charged")
	s.set_held(false)
	assert_eq(s.tick(STEP), "", "no spin")
	assert_true(not s.is_busy(), "sword put away")


func test_a_released_button_never_charges() -> void:
	var s := _sword()
	s.press()
	s.set_held(false)
	_run(s, 0.4)
	assert_true(not s.is_busy(), "swing then idle, no charge")


func test_the_held_blade_pokes_only_after_a_while() -> void:
	var s := _sword()
	s.press()
	s.set_held(true)
	_run(s, s.swing_startup + s.swing_active + s.swing_recovery + STEP)
	assert_true(s.is_charging(), "charging")
	assert_true(not s.is_cutting(), "no poke right after the swing")
	_run(s, s.poke_interval)
	assert_true(s.can_poke() and s.is_cutting(), "pokes after %.2f s" % s.poke_interval)
	assert_eq(s.damage(), s.poke_damage, "poke damage")


func test_cancel_drops_the_charge() -> void:
	var s := _sword()
	s.press()
	s.set_held(true)
	_run(s, 0.3 + s.charge_time)
	s.cancel()
	assert_true(not s.is_busy() and s.charge == 0.0, "hit: charge lost")


func test_sweep_hits_in_front_and_misses_behind() -> void:
	var o := Vector2.ZERO
	var right := 0.0
	var arc := Vector2(deg_to_rad(-100), deg_to_rad(75))
	var hit := func(p: Vector2) -> bool: return SwordSwing.sweep_hits(o, right, arc.x, arc.y, 5.0, 27.0, p, 6.0)
	assert_true(hit.call(Vector2(20, 0)), "straight ahead")
	assert_true(hit.call(Vector2(10, -20)), "ahead and up")
	assert_true(hit.call(Vector2(10, 20)), "ahead and down")
	assert_true(not hit.call(Vector2(-20, 0)), "not behind")
	assert_true(not hit.call(Vector2(36, 0)), "not out of reach (27 + 6 < 36)")
	assert_true(hit.call(Vector2(-6, 2)), "touching the hilt counts")


func test_sweep_works_across_the_angle_wrap() -> void:
	# Facing left (180°): the arc crosses ±180°.
	var left := PI
	var hit := SwordSwing.sweep_hits(Vector2.ZERO, left, deg_to_rad(-100), deg_to_rad(75), 5.0, 27.0, Vector2(-20, 0), 6.0)
	assert_true(hit, "straight ahead to the left")
	assert_true(not SwordSwing.sweep_hits(Vector2.ZERO, left, deg_to_rad(-100), deg_to_rad(75), 5.0, 27.0, Vector2(20, 0), 6.0), "not behind")


func test_hearts_count_halves() -> void:
	assert_eq(HudIcons.heart_fills(6, 6), [2, 2, 2] as Array[int], "three full hearts")
	assert_eq(HudIcons.heart_fills(3, 6), [2, 1, 0] as Array[int], "one and a half")
	assert_eq(HudIcons.heart_fills(0, 7), [0, 0, 0, 0] as Array[int], "7 points: four hearts")
