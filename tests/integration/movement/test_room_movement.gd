extends TestCase
## Integration: Yggnus in a real room with collision, driven for N physics steps.

var main: Node


func _setup(room_id: String = "r04_adega") -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
	main.load_room(room_id)
	var p: Player = main.player
	p.read_input = false
	return p


func _walk(p: Player, input: Vector2, steps: int) -> void:
	p.input_override = input
	for i in steps:
		await tree.physics_frame
	p.input_override = Vector2.ZERO


func teardown() -> void:
	if main:
		main.queue_free()
		await tree.process_frame


func test_cannot_walk_through_outer_wall() -> void:
	var p := _setup()
	var room: RoomData = main.room.data
	await _walk(p, Vector2.LEFT, 180)
	# Wall column 0 ends at x = 16; the feet box is 12 px wide.
	assert_true(p.global_position.x >= 16.0 + 6.0 - 0.5, "stopped at the west wall (x=%.2f)" % p.global_position.x)
	p.respawn_at(room.tile_center(Vector2i(12, 8)))  # away from the corner pots
	await _walk(p, Vector2.UP, 300)
	assert_true(p.global_position.y >= 16.0 + 5.0 - 0.5, "stopped at the north wall (y=%.2f)" % p.global_position.y)
	assert_true(room.is_walkable(Vector2i(p.global_position / room.tile_size)), "still standing on floor")


func test_slides_along_wall_on_diagonal() -> void:
	var p := _setup()
	p.respawn_at(main.room.data.tile_center(Vector2i(12, 8)))  # clear of the corner pots
	await _walk(p, Vector2.LEFT, 120)
	var y0 := p.global_position.y
	await _walk(p, Vector2(-1, 1).normalized(), 30)
	assert_true(p.global_position.y > y0 + 10.0, "diagonal into a wall still slides along it")


func test_distance_matches_speed() -> void:
	var p := _setup()
	var start := p.global_position
	await _walk(p, Vector2.RIGHT, 60)
	var moved := p.global_position.x - start.x
	# 1 s of input: accelerating costs speed²/(2·acceleration) px
	# (100²/(2·6000) ≈ 0.8 px with combate.json).
	var speed := p.motor.speed
	assert_near(moved, speed - speed * speed / (2.0 * p.motor.acceleration), 1.5, "distance walked in one second of physics")
	assert_near(p.global_position.y, start.y, 0.01, "no vertical drift")


func _measure(p: Player, from: Vector2, input: Vector2, steps: int) -> float:
	p.global_position = from
	p.velocity = Vector2.ZERO
	p.reset_physics_interpolation()
	await tree.physics_frame
	var start := p.global_position
	await _walk(p, input, steps)
	return p.global_position.distance_to(start)


func test_diagonal_distance_equals_straight() -> void:
	var p := _setup()
	var from := p.global_position
	var diag: float = await _measure(p, from, Vector2(1, 1).normalized(), 30)
	var straight: float = await _measure(p, from, Vector2.RIGHT, 30)
	assert_near(diag, straight, 0.5, "diagonal covers the same distance as straight")


func test_holding_run_goes_faster_than_walking() -> void:
	var p := _setup()
	p.respawn_at(main.room.data.tile_center(Vector2i(3, 8)))
	var start := p.global_position
	await _walk(p, Vector2.RIGHT, 30)
	var walked := p.global_position.x - start.x
	p.respawn_at(main.room.data.tile_center(Vector2i(3, 8)))
	p.run_override = true
	start = p.global_position
	await _walk(p, Vector2.RIGHT, 30)
	var ran := p.global_position.x - start.x
	p.run_override = false
	assert_near(ran / walked, p.run_speed_factor, 0.05, "run covers %.1f px, walk %.1f px" % [ran, walked])
	assert_true(p.run_speed_factor > 1.0, "running is faster")


func test_run_does_not_speed_up_a_charge() -> void:
	var p := _setup()
	p.respawn_at(main.room.data.tile_center(Vector2i(3, 8)))
	p.run_override = true
	p.attack_held_override = true
	p.request_attack()
	await _frames(40)
	var start := p.global_position
	await _walk(p, Vector2.RIGHT, 20)
	assert_true(not p.running, "no running while the blade charges")
	assert_true(p.global_position.x - start.x < p.motor.speed * 20.0 / 60.0, "slower than a walk")


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame
