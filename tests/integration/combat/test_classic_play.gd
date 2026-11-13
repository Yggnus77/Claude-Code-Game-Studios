extends TestCase
## Integration: the classic play of design/gdd/jogabilidade-classica.md —
## the wide swing, the spin, the passive shield, no free dodge, the hint
## that lists only what the player has, and the bow in the tower.

var main: Node


func _setup(room_id: String = "t00_base") -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
	main.load_room(room_id)
	main.clear_enemies()
	var p: Player = main.player
	p.read_input = false
	return p


func teardown() -> void:
	if main:
		main.queue_free()
		await tree.process_frame
	# A new game's opening scene pauses the tree; do not leak that.
	tree.paused = false


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


## A still enemy of [param kind] at [param offset] from Yggnus.
func _dummy(p: Player, kind: String, offset: Vector2) -> EnemyBase:
	var e: EnemyBase = main.spawn_enemy(kind, Vector2i(10, 12))
	e.set_physics_process(false)
	e.global_position = p.global_position + offset
	return e


func test_one_swing_covers_the_whole_front_and_not_the_back() -> void:
	var p := _setup()
	p.respawn_at(main.room.data.tile_center(Vector2i(10, 10)))
	p.motor.facing = Vector2.RIGHT
	var ahead := _dummy(p, "soldado_corda", Vector2(22, -6))
	var up := _dummy(p, "soldado_corda", Vector2(10, -24))
	var down := _dummy(p, "soldado_corda", Vector2(10, 14))
	var behind := _dummy(p, "soldado_corda", Vector2(-22, -6))
	p.request_attack()
	await _frames(20)
	assert_eq(ahead.health.current, 2, "ahead: hit once")
	assert_eq(up.health.current, 2, "above, in front: hit")
	assert_eq(down.health.current, 2, "below, in front: hit")
	assert_eq(behind.health.current, 3, "behind: untouched")


func test_the_spin_hits_all_around_for_double_damage() -> void:
	var p := _setup()
	p.respawn_at(main.room.data.tile_center(Vector2i(10, 10)))
	p.motor.facing = Vector2.DOWN
	var around: Array[EnemyBase] = []
	# Off the held blade's line (it pokes what it touches while charging).
	for off: Vector2 in [Vector2(24, -6), Vector2(-24, -6), Vector2(0, -28), Vector2(18, 14)]:
		var e := _dummy(p, "soldado_corda", off)
		e.health = Health.new(9)  # the opening swing hits some of them too
		around.append(e)
	p.attack_held_override = true
	p.request_attack()
	await _frames(int((0.25 + p.sword.charge_time) * 60.0) + 4)
	assert_true(p.sword.is_charged(), "charged after holding")
	var before: Array[int] = []
	for e in around:
		before.append(e.health.current)
	p.attack_held_override = false
	await _frames(30)
	for i in around.size():
		assert_eq(before[i] - around[i].health.current, 2, "enemy %d took the spin's 2" % i)


func test_charging_walks_slowly_and_keeps_the_facing() -> void:
	var p := _setup()
	p.respawn_at(main.room.data.tile_center(Vector2i(10, 10)))
	p.motor.facing = Vector2.UP
	p.attack_held_override = true
	p.request_attack()
	await _frames(20)
	assert_true(p.sword.is_charging(), "charging")
	var start := p.global_position
	p.input_override = Vector2.RIGHT
	await _frames(30)
	p.input_override = Vector2.ZERO
	var moved := p.global_position.x - start.x
	assert_true(moved > 5.0 and moved < p.motor.speed * 0.5 * p.sword.charge_speed_factor + 6.0, "slow strafe (%.1f px)" % moved)
	assert_eq(p.motor.facing, Vector2.UP, "still facing up")


func test_the_shield_is_passive_but_not_while_swinging() -> void:
	var p := _setup()
	p.motor.facing = Vector2.RIGHT
	await _frames(2)
	var front := p.global_position + Vector2(20, 0)
	assert_eq(p.receive_hit(1, front), HitResolver.Outcome.BLOCKED, "standing: the shield blocks the front")
	assert_eq(p.receive_hit(1, p.global_position + Vector2(-20, 0)), HitResolver.Outcome.HIT, "the back is open")
	p.health.tick(5.0)
	await _frames(20)  # the hit stun ends
	p.motor.facing = Vector2.RIGHT
	p.request_attack()
	await _frames(3)
	assert_true(p.sword.is_busy(), "swinging")
	assert_eq(p.receive_hit(1, front), HitResolver.Outcome.HIT, "no shield during the swing")


func test_there_is_no_free_dodge() -> void:
	var p := _setup()
	var start := p.global_position
	p.input_override = Vector2.RIGHT
	p.request_dodge()
	await _frames(3)
	assert_true(not p.dodge.is_dodging(), "no dodge without the item")
	assert_true(not Controls.REBINDABLE.has("dodge") and not Controls.REBINDABLE.has("guard"), "neither is in the controls menu")
	assert_true(p.global_position.x > start.x, "just walks")


func test_damage_knocks_back_and_blinks_for_a_second() -> void:
	var p := _setup()
	p.respawn_at(main.room.data.tile_center(Vector2i(10, 10)))
	p.motor.facing = Vector2.UP
	var start := p.global_position
	p.receive_hit(1, start + Vector2(-20, 0))
	await _frames(20)
	assert_true(p.global_position.x - start.x > 20.0, "thrown back (%.1f px)" % (p.global_position.x - start.x))
	assert_true(p.health.is_invulnerable(), "still invulnerable after 0.33 s")
	await _frames(45)
	assert_true(not p.health.is_invulnerable(), "vulnerable again after ~1 s")


func test_the_hint_lists_only_what_the_player_has() -> void:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.start_unarmed = true
	main.show_title = false
	tree.root.add_child(main)
	await _frames(2)
	var hint: String = main.hud._hint.text
	assert_true(not main.player.has_sword and not main.player.has_shield, "a new game starts with neither")
	assert_true(not hint.contains("espada"), "no sword yet: %s" % hint)
	assert_true(not hint.contains("esquiva") and not hint.contains("defesa"), "never dodge or guard")
	assert_true(not hint.contains("troca"), "nothing to swap")
	main.state.apply([{"op": "grant_unique", "item_id": "espada_oficina", "quantity": 1, "receipt_id": "scene.p05.espada_oficina"}])
	assert_true(main.hud._hint.text.contains("espada"), "the sword appears: %s" % main.hud._hint.text)
	main.state.apply([{"op": "grant_unique", "item_id": "lamparina_oleo", "quantity": 1, "receipt_id": "t.lamp"}])
	assert_true(main.hud._hint.text.contains("troca"), "a tool: swap appears")


func test_the_hud_shows_three_hearts_and_the_item_box() -> void:
	var p := _setup()
	assert_eq(HudIcons.heart_fills(p.health.current, p.health.maximum).size(), 3, "6 life = 3 hearts")
	p.receive_hit(1, p.global_position + Vector2(0, -20))
	assert_eq(main.hud.life_text(), "5/6", "half a heart lost")
	main.state.apply([{"op": "grant_unique", "item_id": "arco_fio", "quantity": 1, "receipt_id": "t.arco"}])
	assert_eq(main.hud._item_tool, "arco", "the box draws the bow")


func test_the_bow_is_in_the_tower_and_the_cellar_holds_bronze() -> void:
	var p := _setup("r04_adega")
	p.respawn_at(main.room.data.tile_center(Vector2i(12, 6)))
	p.motor.facing = Vector2.UP
	var before: int = main.state.bronze
	assert_eq(main.interact(), "chest", "cellar chest")
	assert_eq(main.state.bronze - before, 50, "50 Bronze")
	assert_eq(main.state.item_count("arco_fio"), 0, "no bow here")
	main.load_room("t06_marco")
	p.respawn_at(main.room.data.tile_center(Vector2i(8, 10)))
	p.motor.facing = Vector2.UP
	assert_eq(main.interact(), "chest", "antechamber chest")
	assert_eq(main.state.item_count("arco_fio"), 1, "the bow")


func test_holding_after_hitting_a_bell_rings_it_once() -> void:
	# Review fix: the held blade must not ring bells (Igris' order, t05).
	var p := _setup("t05_sinos")
	var rings: Array = []
	for b in main.bells:
		b.rung.connect(func(id: String) -> void: rings.append(id))
	p.respawn_at(main.room.data.tile_center(Vector2i(10, 10)))
	p.motor.facing = Vector2.LEFT
	await _frames(2)
	p.attack_held_override = true
	p.request_attack()
	# Held well past a poke, released before the charge fills (a spin would
	# be a new strike and may ring it again).
	await _frames(14 + int(p.sword.charge_time * 60.0) - 6)
	assert_true(p.sword.is_charging() and not p.sword.is_charged(), "still charging")
	p.attack_held_override = false
	await _frames(5)
	assert_eq(rings.size(), 1, "one press, one ring (%s)" % [rings])


func test_the_held_blade_pokes_each_enemy_at_its_own_pace() -> void:
	var p := _setup()
	p.respawn_at(main.room.data.tile_center(Vector2i(10, 10)))
	p.motor.facing = Vector2.RIGHT
	var e := _dummy(p, "soldado_corda", Vector2(22, -8))
	e.health = Health.new(20)
	p.attack_held_override = true
	p.request_attack()
	await _frames(16)
	assert_eq(e.health.current, 19, "the swing hits once, no instant poke after it")
	await _frames(30)
	var after_one := e.health.current
	assert_eq(after_one, 18, "then one poke")
	await _frames(int(p.sword.poke_interval * 60.0) + 2)
	assert_eq(e.health.current, 17, "and one more per poke_interval")
	p.attack_held_override = false


func test_no_shield_while_charging() -> void:
	var p := _setup()
	p.motor.facing = Vector2.RIGHT
	p.attack_held_override = true
	p.request_attack()
	await _frames(20)
	assert_true(p.sword.is_charging(), "charging")
	assert_eq(p.receive_hit(1, p.global_position + Vector2(20, 0)), HitResolver.Outcome.HIT, "the front is open while charging")


func test_an_old_save_with_the_bow_finds_the_tower_chest_empty() -> void:
	var p := _setup("t06_marco")
	main.state.apply([{"op": "grant_unique", "item_id": "arco_fio", "quantity": 1, "receipt_id": "reward.arco_fio"},
		{"op": "grant_unique", "item_id": "agulha_fio", "quantity": 4, "receipt_id": "reward.arco_fio.also.0"}])
	p.respawn_at(main.room.data.tile_center(Vector2i(8, 10)))
	p.motor.facing = Vector2.UP
	assert_eq(main.interact(), "chest_empty", "nothing new inside")
	assert_true(main.hud._toast.text.begins_with("Vazio"), "says so: %s" % main.hud._toast.text)
	assert_eq(main.state.item_count("agulha_fio"), 4, "no needles appear from nowhere")
	assert_eq(main.interact(), "chest_empty", "stays open")
