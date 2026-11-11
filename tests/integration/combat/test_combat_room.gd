extends TestCase
## Integration: Yggnus and a Rastejo in a real room.

var main: Node


func _setup(room_id: String = "t00_base") -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
	main.load_room(room_id)
	var p: Player = main.player
	p.read_input = false
	return p


func teardown() -> void:
	if main:
		main.queue_free()
		await tree.process_frame


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func test_swing_hits_enemy_once_and_two_swings_defeat_it() -> void:
	var p := _setup()
	var e: Rastejo = main.spawn_enemy("rastejo_tinta", Vector2i(10, 12))
	e.set_physics_process(false)  # hold still: we only test the sword
	p.respawn_at(e.global_position + Vector2(-14, 0))
	p.motor.facing = Vector2.RIGHT
	p.request_attack()
	await _frames(25)
	assert_eq(e.health.current, 1, "one swing removes exactly 1 of 2 life")
	var defeated := [false]
	e.defeated.connect(func(_x: EnemyBase) -> void: defeated[0] = true)
	p.request_attack()
	await _frames(25)
	assert_true(defeated[0], "second swing defeats it")


func test_rastejo_charges_and_hurts_player_once() -> void:
	var p := _setup()
	p.respawn_at(main.room.data.tile_center(Vector2i(8, 12)))
	main.spawn_enemy("rastejo_tinta", Vector2i(12, 12))
	await _frames(150)
	assert_eq(p.health.current, p.health.maximum - 1, "one charge costs exactly 1 life")


func test_guard_blocks_charge_from_front() -> void:
	var p := _setup()
	p.respawn_at(main.room.data.tile_center(Vector2i(8, 12)))
	p.motor.facing = Vector2.RIGHT
	main.spawn_enemy("rastejo_tinta", Vector2i(12, 12))
	await _frames(20)
	# The shield is passive: up while Yggnus stands (jogabilidade-classica §3.3).
	var outcomes := []
	p.hit_taken.connect(func(o: HitResolver.Outcome) -> void: outcomes.append(o))
	await _frames(100)
	assert_true(outcomes.has(HitResolver.Outcome.BLOCKED) or outcomes.has(HitResolver.Outcome.PERFECT_BLOCK), "the charge reached the guard (%s)" % [outcomes])
	assert_eq(p.health.current, p.health.maximum, "facing guard blocks the charge")


func test_dodge_does_not_cross_wall() -> void:
	var p := _setup()
	var data: RoomData = main.room.data
	# Row 8: no door there (walking up to a door's arch would go through it).
	p.respawn_at(data.tile_center(Vector2i(1, 8)) + Vector2(2, 0))
	p.input_override = Vector2.LEFT
	p.has_dodge = true  # the dash of a later item
	p.request_dodge()
	await _frames(20)
	assert_true(p.global_position.x >= 16.0 + 5.5, "dodge stops at the wall (x=%.2f)" % p.global_position.x)


func test_death_respawns_with_full_life() -> void:
	var p := _setup()
	for i in p.health.maximum:
		p.health.tick(1.0)
		p.receive_hit(1, p.global_position + Vector2(20, 0))
	assert_true(p.is_dead(), "dead after losing all life")
	await tree.create_timer(main.RESPAWN_DELAY + 0.2).timeout
	assert_eq(p.health.current, p.health.maximum, "back with full life")
	assert_true(not p.is_dead(), "alive again")


func test_drinking_lowers_the_shield() -> void:
	# mecanicas §8: healing can be interrupted; the shield cannot cover it.
	var p := _setup()
	main.state.apply([{"op": "refill_flask"}])
	p.health.take_damage(2)
	p.health.tick(5.0)
	p.motor.facing = Vector2.RIGHT
	await _frames(3)
	assert_true(p.guard.is_up(), "shield up")
	assert_true(p.request_heal(), "drinks")
	assert_true(not p.guard.is_up(), "the shield comes down to drink")
	await _frames(10)
	p.receive_hit(1, p.global_position + Vector2(20, 0))
	await _frames(60)
	assert_eq(main.state.full_flask_count(), 1, "a frontal hit interrupts the drink")


func test_dodge_after_drinking_travels_full_distance() -> void:
	var p := _setup()
	var full := p.dodge.speed * p.dodge.duration
	main.state.apply([{"op": "refill_flask"}])
	p.respawn_at(main.room.data.tile_center(Vector2i(10, 14)))
	p.health.take_damage(2)
	p.health.tick(5.0)
	assert_true(p.request_heal(), "drinks")
	while p.healing.phase != Healing.Phase.RECOVERY:
		await tree.physics_frame
	var start := p.global_position
	p.input_override = Vector2.RIGHT
	p.has_dodge = true  # the dash of a later item
	p.request_dodge()
	await _frames(20)
	p.input_override = Vector2.ZERO
	var moved := p.global_position.x - start.x
	assert_true(moved > full * 0.8, "the dodge leaves the recovery (moved %.1f of %.1f px)" % [moved, full])


func test_attack_pressed_while_hooking_expires() -> void:
	# mecanicas §3: a buffered press lasts 0.12 s and is used once.
	var p := _setup()
	p.hook_probe = func(_pos: Vector2) -> Dictionary: return {}
	assert_true(p.fire_hook(), "hook thrown")
	p.request_attack()
	var swung := false
	for i in 90:
		await tree.physics_frame
		if p.sword.is_busy():
			swung = true
	assert_true(not swung, "the old press does not swing after the hook returns")
