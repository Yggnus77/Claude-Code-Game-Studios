extends TestCase
## Integration: the two prototype mysteries in the world and the relic slot.

const AFTER_IGRIS := ["seen.p00", "seen.p01", "seen.p02", "seen.p03", "seen.p04", "seen.p05", "seen.p07", "seen.p08",
	"seen.r05", "seen.t01", "seen.t02", "seen.t03", "seen.t05", "seen.t08", "seen.t10", "seen.t11", "seen.t12",
	"world.guards_clear", "world.weight_locked", "world.bells_solved", "visited.t00_base"]

var main: Node


func _setup(room_id: String, extra: Array = []) -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
	var effects := []
	for f in AFTER_IGRIS + extra:
		effects.append({"op": "set_flag", "flag": f, "value": true})
	main.state.apply(effects)
	main.load_room(room_id)
	var p: Player = main.player
	p.read_input = false
	return p


func teardown() -> void:
	if main:
		main.dialogue_box.runner = null
		main.dialogue._on_box_closed()
		main.queue_free()
		await tree.process_frame
		tree.paused = false


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func _skip_scenes() -> Array:
	var ids := []
	for i in 8:
		await _frames(3)
		if main.dialogue.is_open():
			ids.append(main.dialogue._active_id)
			main.dialogue_box.runner.skip()
			main.dialogue_box._after_step()
	return ids


func _face(p: Player, tile: Vector2i) -> void:
	p.respawn_at(main.room.data.tile_center(tile + Vector2i(0, 1)))
	p.motor.facing = Vector2.UP


func test_troco_from_first_talk_to_the_seal() -> void:
	var p := _setup("v01_praca")
	await _skip_scenes()
	_face(p, Vector2i(6, 10))
	assert_eq(main.interact(), "scene", "the merchant starts the mystery")
	assert_eq(await _skip_scenes(), ["x01a"], "x01a")
	_face(p, Vector2i(33, 10))
	assert_eq(main.interact(), "clue", "market receipt")
	_face(p, Vector2i(25, 15))
	assert_eq(main.interact(), "clue", "delivery stamp")
	main.state.apply([{"op": "set_flag", "flag": "clue.m01.via_cais", "value": true}])
	_face(p, Vector2i(6, 10))
	assert_eq(main.interact(), "scene", "all clues: comparison")
	assert_eq(await _skip_scenes(), ["x01b"], "x01b")
	var bronze: int = main.state.bronze
	assert_eq(main.answer_mystery("m01", 0), MysteryQuest.Result.WRONG, "wrong answer")
	assert_eq(await _skip_scenes(), ["x01d"], "Ádally's nudge")
	assert_eq(main.state.bronze, bronze, "a wrong answer costs nothing")
	assert_eq(main.answer_mystery("m01", 1), MysteryQuest.Result.CORRECT, "right answer")
	assert_eq(await _skip_scenes(), ["x01c"], "reward scene")
	assert_eq(main.state.bronze, bronze + 30, "30 Bronze")
	assert_eq(main.state.item_count("selo_restaurador"), 1, "Selo do Restaurador")
	assert_true(main.state.has_flag(GameState.RELIC_SLOT_FLAG), "slot open")
	main.answer_mystery("m01", 1)
	await _skip_scenes()
	assert_eq(main.state.bronze, bronze + 30, "the reward is unique")
	assert_eq(main.state.item_count("selo_restaurador"), 1, "one seal")
	_face(p, Vector2i(6, 10))
	assert_eq(main.interact(), "shop", "solved: the merchant sells again")
	main.shop_panel.close()


func test_quarto_toque_starts_on_entering_the_bells() -> void:
	_setup("t05_sinos")
	main._on_room_entered()
	assert_eq(await _skip_scenes(), ["x02a"], "Igris tells of the fourth answer")


func test_seal_keeps_healing_at_three_and_equips_outside_combat() -> void:
	var p := _setup("v01_praca", ["seen.x01c", "mystery.m01.solved", "gear.relic_slot_unlocked"])
	main.state.apply([{"op": "grant_unique", "item_id": "selo_restaurador", "quantity": 1, "receipt_id": "mystery.m01.relic"},
		{"op": "refill_flask"}])
	assert_eq(main.cycle_relic(), "Relíquia: Selo do Restaurador.", "equipped")
	assert_true(is_equal_approx(p.healing.startup, 0.55), "startup 0.55")
	assert_true(is_equal_approx(p.healing.recovery, 0.30), "recovery 0.30")
	p.health.take_damage(4)
	p.health.tick(5.0)
	assert_true(p.request_heal(), "drinks")
	await _frames(int(0.55 * 60) + 3)
	assert_eq(p.health.current, 5, "still +3")
	for i in 19:
		main.cycle_relic()
	assert_eq(main.state.equipped_relic, "", "19 more swaps (20 in all) end empty")
	assert_true(is_equal_approx(p.healing.startup, 0.65), "back to the base 0.65")
	main.spawn_near_player("rastejo_tinta")
	assert_eq(main.cycle_relic(), "Não dá para trocar a relíquia em combate.", "not in combat")


func test_spring_shortens_only_the_hook_cooldown_in_play() -> void:
	var p := _setup("t05_sinos", ["seen.x02a", "seen.x02c", "gear.relic_slot_unlocked"])
	main.state.apply([{"op": "grant_unique", "item_id": "mola_retorno", "quantity": 1, "receipt_id": "mystery.m02.relic"},
		{"op": "grant_unique", "item_id": "gancho_retorno", "quantity": 1, "receipt_id": "scene.t03.gancho_retorno"}])
	var reach: float = p.hook.reach
	var speed: float = p.motor.speed
	main.state.apply([{"op": "equip_relic", "relic_id": "mola_retorno"}])
	assert_true(is_equal_approx(p.hook.cooldown, 0.25), "cooldown 0.25")
	assert_eq(p.hook.reach, reach, "reach unchanged")
	assert_eq(p.motor.speed, speed, "speed unchanged")
	assert_true(is_equal_approx(p.healing.startup, 0.65), "healing unchanged")


func test_no_swap_after_a_kill_with_an_enemy_near_or_in_a_boss_attempt() -> void:
	var p := _setup("v01_praca", ["gear.relic_slot_unlocked"])
	main.state.apply([{"op": "grant_unique", "item_id": "mola_retorno", "quantity": 1, "receipt_id": "mystery.m02.relic"}])
	var first: EnemyBase = main.spawn_near_player("rastejo_tinta")
	first.health.take_damage(99)
	first._defeat()
	await _frames(30)
	assert_true(not is_instance_valid(first), "the defeated enemy is freed")
	assert_eq(main.cycle_relic(), "Relíquia: Mola de Retorno.", "free again after the kill")
	main.spawn_near_player("rastejo_tinta")
	assert_eq(main.cycle_relic(), "Não dá para trocar a relíquia em combate.", "a new enemy near")
	main.clear_enemies()
	main._attempt = {"full_flasks": [], "bread": 0}
	assert_eq(main.cycle_relic(), "Não dá para trocar a relíquia em combate.", "never during a boss attempt")
	main._attempt = {}
	assert_eq(p.hook.cooldown, 0.25, "the spring stayed on")


func test_pressing_again_never_gives_clues() -> void:
	var p := _setup("v01_praca", ["seen.x01a"])
	_face(p, Vector2i(6, 10))
	var flags_before: int = main.state.flags.size()
	for i in 6:
		main.interact()
		main.shop_panel.close()
	_face(p, Vector2i(33, 10))
	main.interact()
	main.interact()
	assert_eq(main.state.flags.size(), flags_before + 1, "only the clue actually examined")


func test_quarto_toque_through_the_tower() -> void:
	var p := _setup("t05_sinos", ["seen.x02a"])
	for tile in [Vector2i(5, 4), Vector2i(27, 4), Vector2i(16, 17)]:
		_face(p, tile)
		assert_eq(main.interact(), "clue", "clue at %s" % tile)
	assert_eq(await _skip_scenes(), ["x02b"], "comparison after the third clue")
	_face(p, Vector2i(16, 5))
	assert_eq(main.interact(), "question", "the inscription asks")
	main.dialogue_box.runner.choose(1)
	main.dialogue_box._after_step()
	var bronze: int = main.state.bronze
	assert_eq(await _skip_scenes(), ["x02c"], "the reward scene")
	assert_eq(main.state.bronze, bronze + 50, "50 Bronze")
	assert_eq(main.state.item_count("mola_retorno"), 1, "Mola de Retorno")
	assert_true(main.state.has_flag(GameState.RELIC_SLOT_FLAG), "slot open")
	var lines: PackedStringArray = main._inventory_lines()
	assert_true("\n".join(lines).contains("0,35 → 0,25"), "effect shown before equipping")
