extends TestCase
## DialogueDB eligibility and DialogueRunner completion/skip (integracao §3–4).


func _db() -> DialogueDB:
	return DialogueDB.load_from()


func test_all_scenes_load() -> void:
	var db := _db()
	assert_eq(db.scenes.size(), 147, "147 scenes in the data")


func test_requirements_and_seen() -> void:
	var db := _db()
	var s := GameState.new()
	assert_true(not db.scene_for("nova_partida", s, 0.0).is_empty(), "p00 plays on a new game")
	assert_true(db.scene_for("examinar_relogio", s, 0.0).is_empty(), "p01 needs seen.p00")
	s.apply([{"op": "set_flag", "flag": "seen.p00", "value": true}])
	assert_true(db.scene_for("nova_partida", s, 0.0).is_empty(), "p00 does not repeat")
	assert_eq(db.scene_for("examinar_relogio", s, 0.0).get("id"), "p01", "p01 now plays")


func test_requires_items() -> void:
	var db := _db()
	var s := GameState.new()
	s.apply([{"op": "set_flag", "flag": "seen.p07"}, {"op": "set_flag", "flag": "seen.r03"}])
	assert_true(db.scene_for("concluir_missao_bomba", s, 0.0).is_empty(), "r04 needs both pump parts")
	s.items = {"peca_bomba_a": 1, "peca_bomba_b": 1}
	assert_eq(db.scene_for("concluir_missao_bomba", s, 0.0).get("id"), "r04", "r04 plays with the parts")


func test_bark_cooldown() -> void:
	var db := _db()
	var s := GameState.new()
	assert_true(not db.scene_for("primeira_defesa", s, 0.0).is_empty(), "bark p06 available")
	db.mark_played("p06", 0.0)
	assert_true(db.scene_for("primeira_defesa", s, 5.0).is_empty(), "not again within 12 s")
	assert_true(not db.scene_for("primeira_defesa", s, 12.5).is_empty(), "back after 12 s")


func _complete(scene: Dictionary, s: GameState) -> void:
	var r := DialogueRunner.new(scene, s)
	for i in 100:
		if r.is_finished:
			return
		if r.is_choice():
			r.choose(i % 3)
		else:
			r.advance()


func test_complete_and_skip_give_the_same_state() -> void:
	var db := _db()
	for id in ["p04", "p05", "r04", "m02", "e04", "o07"]:
		var scene: Dictionary = db.scenes[id]
		var a := GameState.new()
		a.items = {"peca_bomba_a": 1, "peca_bomba_b": 1}
		var b := GameState.from_dict(a.to_dict())
		_complete(scene, a)
		DialogueRunner.new(scene, b).skip()
		assert_eq(a.to_dict(), b.to_dict(), "%s: reading and skipping end in the same state" % id)


func test_effects_apply_once_even_if_replayed() -> void:
	var db := _db()
	var s := GameState.new()
	var scene: Dictionary = db.scenes["p05"]
	_complete(scene, s)
	_complete(scene, s)
	DialogueRunner.new(scene, s).skip()
	assert_eq(s.item_count("espada_oficina"), 1, "sword granted once")
	assert_eq(s.item_count("escudo_bronze"), 1, "shield granted once")


func test_choices_converge_and_go_to_history() -> void:
	var db := _db()
	var s := GameState.new()
	var r := DialogueRunner.new(db.scenes["m02"], s)
	assert_true(r.is_choice(), "m02 opens with a question")
	r.choose(1)
	assert_eq(r.history[0]["text"], "O que você lembra de Ádally?", "the chosen question is in the history")
	assert_eq(r.node()["speaker"], "MORINA", "answer follows")
	r.advance()
	assert_eq(r.node_id, "m02.line0", "all options converge")


func test_speaker_names_keep_particles_lower_case() -> void:
	assert_eq(DialogueBox.display_name("MECÂNICA DO CAIS"), "Mecânica do Cais", "particle lower case")
	assert_eq(DialogueBox.display_name("ÁDALLY"), "Ádally", "accented initial")
