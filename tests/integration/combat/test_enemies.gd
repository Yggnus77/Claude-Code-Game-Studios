extends TestCase
## Integration: Mariposa, Soldado and Guarda against Yggnus in a real room.

var main: Node


func _setup() -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
	main.load_room("r04_adega")
	var p: Player = main.player
	p.read_input = false
	p.respawn_at(main.room.data.tile_center(Vector2i(8, 12)))
	return p


func teardown() -> void:
	if main:
		main.queue_free()
		await tree.process_frame


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func _swing_at(p: Player, dir: Vector2) -> void:
	p.motor.facing = dir
	p.request_attack()
	await _frames(25)


func test_mariposa_only_hittable_when_landed() -> void:
	var p := _setup()
	var m: Mariposa = main.spawn_enemy("mariposa_papel", Vector2i(10, 12))
	m.set_physics_process(false)
	m.global_position = p.global_position + Vector2(16, 0)
	m.state = Mariposa.State.HOVER
	await _swing_at(p, Vector2.RIGHT)
	assert_eq(m.health.current, 1, "flying moth is not hit")
	m.state = Mariposa.State.REST
	var defeated := [false]
	m.defeated.connect(func(_e: EnemyBase) -> void: defeated[0] = true)
	await _swing_at(p, Vector2.RIGHT)
	assert_true(defeated[0], "landed moth falls to one hit")


func test_mariposa_dive_hurts_once() -> void:
	var p := _setup()
	main.spawn_enemy("mariposa_papel", Vector2i(13, 12))
	await _frames(200)
	assert_eq(p.health.current, p.health.maximum - 1, "one dive costs exactly 1 life")


func test_soldado_does_not_flinch_while_winding_up() -> void:
	var p := _setup()
	var s: Soldado = main.spawn_enemy("soldado_corda", Vector2i(10, 12))
	s.global_position = p.global_position + Vector2(16, 0)
	await _frames(3)
	assert_eq(s.state, Soldado.State.WINDUP, "close soldier starts its cut")
	await _swing_at(p, Vector2.RIGHT)
	assert_eq(s.health.current, 2, "the hit lands")
	assert_eq(s.state, Soldado.State.WINDUP, "but does not interrupt the windup")


func test_soldado_cut_blocked_from_front() -> void:
	var p := _setup()
	p.motor.facing = Vector2.RIGHT
	# The shield is passive: up while Yggnus stands.
	main.spawn_enemy("soldado_corda", Vector2i(11, 12))
	await _frames(120)
	assert_eq(p.health.current, p.health.maximum, "guard from the front blocks the cut")


func test_guarda_shield_blocks_until_slam_opening() -> void:
	var p := _setup()
	var g: Guarda = main.spawn_enemy("guarda_contrapeso", Vector2i(10, 12))
	g.set_physics_process(false)
	g.global_position = p.global_position + Vector2(18, 0)
	g.facing = Vector2.LEFT
	await _swing_at(p, Vector2.RIGHT)
	assert_eq(g.health.current, 4, "shield blocks while not open")
	# After a slam: still facing left (towards where the player was).
	g.expose(0.7)
	await _swing_at(p, Vector2.RIGHT)
	assert_eq(g.health.current, 4, "the front stays covered during the opening")
	p.respawn_at(g.global_position + Vector2(18, 0))
	await _swing_at(p, Vector2.LEFT)
	assert_eq(g.health.current, 3, "a hit from behind lands during the opening")


func test_guarda_can_be_beaten_without_hook() -> void:
	var p := _setup()
	var g: Guarda = main.spawn_enemy("guarda_contrapeso", Vector2i(10, 12))
	g.set_physics_process(false)
	g.facing = Vector2.LEFT
	var defeated := [false]
	g.defeated.connect(func(_e: EnemyBase) -> void: defeated[0] = true)
	for i in 4:
		g.expose(0.7)
		p.respawn_at(g.global_position + Vector2(18, 0))
		await _swing_at(p, Vector2.LEFT)
	assert_true(defeated[0], "four openings are enough to win")


func test_guarda_slam_breaks_guard() -> void:
	var p := _setup()
	p.motor.facing = Vector2.RIGHT
	# The shield is passive: up while Yggnus stands.
	var outcomes := []
	p.hit_taken.connect(func(o: HitResolver.Outcome) -> void: outcomes.append(o))
	main.spawn_enemy("guarda_contrapeso", Vector2i(11, 12))
	await _frames(150)
	assert_true(outcomes.has(HitResolver.Outcome.GUARD_BREAK), "slam on the shield breaks the guard (%s)" % [outcomes])
	assert_eq(p.health.current, p.health.maximum - 1, "guard break costs 1 instead of 2")
