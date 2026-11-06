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
	p.guard_override = true
	var outcomes := []
	p.hit_taken.connect(func(o: HitResolver.Outcome) -> void: outcomes.append(o))
	await _frames(100)
	assert_true(outcomes.has(HitResolver.Outcome.BLOCKED) or outcomes.has(HitResolver.Outcome.PERFECT_BLOCK), "the charge reached the guard (%s)" % [outcomes])
	assert_eq(p.health.current, p.health.maximum, "facing guard blocks the charge")


func test_dodge_does_not_cross_wall() -> void:
	var p := _setup()
	var data: RoomData = main.room.data
	p.respawn_at(data.tile_center(Vector2i(1, 12)) + Vector2(2, 0))
	p.input_override = Vector2.LEFT
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
