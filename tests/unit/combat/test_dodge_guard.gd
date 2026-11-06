extends TestCase
## Dodge and guard rules (mecanicas §5) and HitResolver.

const STEP := 1.0 / 60.0


func _cfg() -> GameConfig:
	return GameConfig.load_all()


func test_dodge_invulnerability_window() -> void:
	var d := Dodge.new(_cfg().dodge())
	d.start(Vector2.RIGHT)
	assert_true(not d.is_invulnerable(), "not invulnerable at 0 s")
	d.tick(0.05)
	assert_true(d.is_invulnerable(), "invulnerable at 0.05 s")
	d.tick(0.11)
	assert_true(not d.is_invulnerable(), "vulnerable again at 0.16 s")
	assert_true(d.is_dodging(), "still moving at 0.16 s")
	d.tick(0.07)
	assert_true(not d.is_dodging(), "dodge over after 0.22 s")


func test_dodge_distance_and_cooldown() -> void:
	var d := Dodge.new(_cfg().dodge())
	d.request()
	assert_true(d.wants_to_start(), "ready at first")
	d.start(Vector2.RIGHT)
	var dist := 0.0
	for i in 60:
		dist += d.velocity().length() * STEP
		d.tick(STEP)
		if i == 30:
			d.request()
			assert_true(not d.wants_to_start(), "cooldown blocks a dodge at 0.5 s")
	assert_near(dist, 230.0 * 0.22, 230.0 * STEP, "about 50.6 px")
	d.tick(0.2)
	d.request()
	assert_true(d.wants_to_start(), "ready again after 0.65 s from start")


func test_guard_cone_front_not_back() -> void:
	var g := Guard.new(_cfg().guard())
	assert_true(g.covers(Vector2.RIGHT, Vector2(1, 0.5)), "front-ish is covered")
	assert_true(g.covers(Vector2.RIGHT, Vector2.RIGHT.rotated(deg_to_rad(49))), "49° is inside the 100° cone")
	assert_true(not g.covers(Vector2.RIGHT, Vector2.RIGHT.rotated(deg_to_rad(55))), "55° is outside")
	assert_true(not g.covers(Vector2.RIGHT, Vector2.LEFT), "back is not covered")


func test_perfect_window_and_retrigger() -> void:
	var g := Guard.new(_cfg().guard())
	g.set_held(true)
	assert_true(g.is_perfect(), "perfect right after pressing")
	g.tick(0.12)
	assert_true(g.is_up() and not g.is_perfect(), "plain guard after 0.11 s")
	g.set_held(false)
	g.set_held(true)
	assert_true(not g.is_up(), "re-press before 0.25 s is ignored")
	g.set_held(false)
	g.tick(0.14)
	g.set_held(true)
	assert_true(g.is_perfect(), "new attempt after 0.25 s is perfect again")


func test_resolver_outcomes() -> void:
	var cfg := _cfg()
	var h := Health.new(6, 0.75)
	var d := Dodge.new(cfg.dodge())
	var g := Guard.new(cfg.guard())
	g.set_held(true)
	g.tick(0.2)
	assert_eq(HitResolver.resolve(h, d, g, Vector2.RIGHT, Vector2.RIGHT, 1), HitResolver.Outcome.BLOCKED, "light hit from the front is blocked")
	assert_eq(h.current, 6, "no damage when blocked")
	assert_eq(HitResolver.resolve(h, d, g, Vector2.RIGHT, Vector2.LEFT, 1), HitResolver.Outcome.HIT, "hit from behind lands")
	assert_eq(h.current, 5, "1 damage")
	assert_eq(HitResolver.resolve(h, d, g, Vector2.RIGHT, Vector2.LEFT, 1), HitResolver.Outcome.IGNORED, "invulnerable right after")
	h.tick(1.0)
	assert_eq(HitResolver.resolve(h, d, g, Vector2.RIGHT, Vector2.RIGHT, 3, true), HitResolver.Outcome.GUARD_BREAK, "heavy hit breaks the guard")
	assert_eq(h.current, 4, "guard break costs 1, not 3")
	assert_true(g.is_broken(), "guard is broken")
	h.tick(1.0)
	d.start(Vector2.UP)
	d.tick(0.05)
	assert_eq(HitResolver.resolve(h, d, g, Vector2.RIGHT, Vector2.LEFT, 2), HitResolver.Outcome.DODGED, "dodge i-frames avoid the hit")
	assert_eq(h.current, 4, "no damage while dodging")
