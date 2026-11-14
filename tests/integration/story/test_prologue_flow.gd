extends TestCase
## Integration: the Versalhes stretch played with every scene skipped, the
## invasion fight, death during it and the first marco (Etapa 4).

var main: Node


func _setup(room_id: String, flags: Array = []) -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	main.start_unarmed = true
	tree.root.add_child(main)
	var effects := []
	for f in flags:
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


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


## Skips every scene that opens within the next frames; returns their ids.
func _skip_scenes() -> Array:
	var ids := []
	for i in 10:
		await _frames(3)
		if not main.dialogue.is_open():
			continue
		ids.append(main.dialogue._active_id)
		main.dialogue_box.runner.skip()
		main.dialogue_box._after_step()
	return ids


func _enter(room_id: String) -> void:
	main.load_room(room_id)
	main._on_room_entered()


func _cut(binding: Node, first_attack_id: int) -> void:
	binding.receive_sword_hit(1, first_attack_id, Vector2.ZERO)
	binding.receive_sword_hit(1, first_attack_id + 1, Vector2.ZERO)


func _bindings() -> Array:
	var out := []
	for n in main.invasion.get_children():
		if n is YameInvasion.Binding:
			out.append(n)
	return out


func test_new_game_starts_unarmed() -> void:
	var p := _setup("v00_oficina")
	assert_true(not p.has_sword and not p.has_shield, "no sword and no shield")
	p.request_attack()
	await _frames(2)
	assert_true(not p.sword.is_busy(), "attack press does nothing")
	assert_true(main.hud.objective_text().is_empty(), "no objective before the opening scene")


func test_whole_stretch_with_every_scene_skipped() -> void:
	var p := _setup("v00_oficina", ["seen.p00"])
	main._refresh_story()
	assert_true(main.hud.objective_text().contains("relógio"), "first objective: the clock")
	p.respawn_at(main.room.data.tile_center(Vector2i(22, 15)))
	p.motor.facing = Vector2.UP
	assert_eq(main.interact(), "scene", "clock plays p01")
	assert_eq(await _skip_scenes(), ["p01"], "p01 skipped")
	_enter("v01_praca")
	assert_eq(await _skip_scenes(), ["p02"], "the thirteenth bell in the square")
	_enter("v00_oficina")
	assert_eq(await _skip_scenes(), ["p03", "p04", "p05"], "workshop scenes chain without input")
	assert_eq(main.state.item_count("matrix"), 1, "Matrix kept")
	assert_true(p.has_sword and p.has_shield, "sword and shield handed by p05")
	assert_true(main.invasion != null, "Yame Black is in the workshop")
	var exit: Dictionary = main.room.data.doors[0]
	assert_true(not main.is_door_open(exit), "bindings tie the exit")
	var bs := _bindings()
	assert_eq(bs.size(), 3, "three bindings")
	for i in bs.size():
		_cut(bs[i], 100 + i * 10)
	await _frames(int(YameInvasion.FLEE_TIME * 60) + 5)
	assert_eq(await _skip_scenes(), ["p07"], "Yame flees and p07 plays")
	assert_true(main.invasion == null, "invasion over")
	assert_true(main.is_door_open(exit), "exit free")
	_enter("v01_praca")
	var road: Dictionary = main.room.data.doors[1]
	assert_true(main.is_door_open(road), "the road out is open after p07")
	p.respawn_at(main.room.data.tile_center(Vector2i(7, 13)))
	p.motor.facing = Vector2.UP
	assert_eq(main.interact(), "checkpoint", "marco used")
	assert_eq(await _skip_scenes(), ["p08"], "first marco scene")
	assert_eq(main.state.item_count("pulso_eco"), 1, "Pulso de Eco received")
	assert_eq(str(main.state.checkpoint.get("entity_id", "")), "v01_praca.marco_v", "checkpoint is the marco")
	assert_true(main.hud.objective_text().contains("estrada"), "objective points to the road")
	assert_true(not main.dialogue.request("yame_entra"), "p05 never plays again")
	assert_eq(main.state.item_count("espada_oficina"), 1, "one sword, never two")


func test_cut_binding_needs_two_different_swings() -> void:
	_setup("v00_oficina", ["seen.p05"])
	await _frames(2)
	var b: Node = _bindings()[0]
	b.receive_sword_hit(1, 7, Vector2.ZERO)
	b.receive_sword_hit(1, 7, Vector2.ZERO)
	assert_eq(main.prologue.bindings_left(main.state).size(), 3, "same swing twice does not cut")
	b.receive_sword_hit(1, 8, Vector2.ZERO)
	assert_eq(main.prologue.bindings_left(main.state).size(), 2, "second swing cuts")


func test_death_in_invasion_keeps_matrix_and_cut_bindings() -> void:
	var p := _setup("v00_oficina", ["seen.p05"])
	main.state.apply([{"op": "grant_unique", "item_id": "matrix", "quantity": 1, "receipt_id": "scene.p04.matrix"}])
	await _frames(2)
	_cut(_bindings()[0], 1)
	p.receive_hit(99, p.global_position + Vector2(0, -20))
	assert_true(p.is_dead(), "Yggnus falls")
	await _frames(int(main.RESPAWN_DELAY * 60) + 10)
	assert_true(not p.is_dead(), "back with full life")
	assert_eq(main.state.item_count("matrix"), 1, "Matrix kept")
	assert_eq(_bindings().size(), 2, "the cut binding stays cut")


func test_shield_stops_paper_from_the_front() -> void:
	var p := _setup("v00_oficina", ["seen.p05"])
	main.state.apply([{"op": "grant_unique", "item_id": "escudo_bronze", "quantity": 1, "receipt_id": "scene.p05.escudo_bronze"}])
	p.respawn_at(main.room.data.tile_center(Vector2i(12, 12)))
	p.motor.facing = Vector2.UP
	# The shield is passive: facing the paper is enough.
	main.invasion._throw_left = 0.0
	await _frames(90)
	assert_eq(p.health.current, p.health.maximum, "guarded: no damage")
	p.motor.facing = Vector2.DOWN
	main.invasion._throw_left = 0.0
	await _frames(90)
	assert_true(p.health.current < p.health.maximum, "unguarded: the paper hurts")


func test_the_sword_on_yame_says_to_cut_the_bindings() -> void:
	_setup("v00_oficina", ["seen.p05"])
	main.state.apply([{"op": "grant_unique", "item_id": "espada_oficina", "quantity": 1, "receipt_id": "scene.p05.espada_oficina"}])
	await _frames(2)
	var p: Player = main.player
	p.has_sword = true
	p.respawn_at(main.invasion.global_position + Vector2(0, 16))
	p.motor.facing = Vector2.UP
	p.request_attack()
	await _frames(20)
	assert_eq(main.prologue.bindings_left(main.state).size(), 3, "Yame takes nothing, bindings untouched")
	assert_eq(main.playtest.refused.get("espada em Yame Black", 0), 1, "one swing, one notice")
	assert_true(main.hud._toast.text.contains("correntes"), "the player is told what to hit")


## Teste do usuário (2026-11-07): após morrer na invasão e voltar no marco da
## praça, a linha de objetivo só dizia "corte as amarras" e ele ficou quase
## 5 min na praça. Fora da oficina ela agora manda voltar.
func test_objective_in_the_square_during_invasion_says_go_back() -> void:
	_setup("v00_oficina", ["seen.p00", "seen.p01", "seen.p02", "seen.p05"])
	await _frames(2)
	main.load_room("v01_praca")
	await _frames(2)
	var line: String = main.hud._objective.text
	assert_true(line.contains("Volte à oficina"), "square during invasion: go back (got '%s')" % line)
	main.load_room("v00_oficina")
	await _frames(2)
	line = main.hud._objective.text
	assert_true(line.contains("Quebre as correntes"), "workshop: cut the bindings (got '%s')" % line)
