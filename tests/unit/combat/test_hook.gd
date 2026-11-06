extends TestCase
## Hook rule: startup, reach, walls along the path, return and cooldown
## (mecanicas-e-dificuldade.md §7).

const PARAMS := {"range": 112, "startup": 0.1, "tip_speed": 360, "return_cooldown": 0.35, "speed_factor": 0.35}
const DT := 1.0 / 60.0


func _run(h: Hook, probe: Callable, frames: int) -> Array:
	var hits := []
	for i in frames:
		var r := h.tick(DT, Vector2.ZERO, probe)
		if not r.is_empty():
			hits.append(r)
	return hits


func test_tip_waits_for_startup_then_stops_at_range() -> void:
	var h := Hook.new(PARAMS)
	assert_true(h.fire(Vector2.RIGHT), "fires")
	assert_true(not h.fire(Vector2.RIGHT), "cannot fire twice")
	h.tick(0.09, Vector2.ZERO, func(_p: Vector2) -> Dictionary: return {})
	assert_eq(h.distance, 0.0, "nothing moves during the 0.10 s startup")
	var furthest := 0.0
	for i in 60:
		h.tick(DT, Vector2.ZERO, func(_p: Vector2) -> Dictionary: return {})
		furthest = maxf(furthest, h.distance)
	assert_near(furthest, 112.0, 0.01, "tip reaches exactly 112 px")


func test_wall_on_the_path_stops_the_tip() -> void:
	var h := Hook.new(PARAMS)
	# A thin wall at x = 50..54; an anchor behind it at x = 80.
	var probe := func(p: Vector2) -> Dictionary:
		if p.x >= 50 and p.x <= 54:
			return {"type": "wall"}
		if absf(p.x - 80) <= 8:
			return {"type": "anchor"}
		return {}
	h.fire(Vector2.RIGHT)
	var hits := _run(h, probe, 60)
	assert_eq(hits.size(), 1, "one touch")
	assert_eq(hits[0]["type"], "wall", "the wall, never the anchor behind it")


func test_returns_and_cools_down() -> void:
	var h := Hook.new(PARAMS)
	h.fire(Vector2.UP)
	_run(h, func(_p: Vector2) -> Dictionary: return {}, 40)
	assert_eq(h.phase, Hook.Phase.COOLDOWN, "back, cooling down")
	assert_true(not h.fire(Vector2.UP), "no throw during cooldown")
	_run(h, func(_p: Vector2) -> Dictionary: return {}, 22)
	assert_true(h.fire(Vector2.UP), "ready after 0.35 s")


func test_pull_then_cooldown() -> void:
	var h := Hook.new(PARAMS)
	h.fire(Vector2.RIGHT)
	_run(h, func(p: Vector2) -> Dictionary: return {"type": "anchor"} if p.x >= 60 else {}, 20)
	h.begin_pull()
	assert_true(h.is_busy(), "busy while pulled")
	h.end_pull()
	assert_eq(h.phase, Hook.Phase.COOLDOWN, "cooldown after the pull")
