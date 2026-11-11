extends TestCase
## Etapa 8 rules: mysteries (misterios-e-reliquias.md) and the relic slot.

var config: GameConfig:
	get:
		if _config == null:
			_config = GameConfig.load_all()
		return _config
var _config: GameConfig


func _quest(id: String) -> MysteryQuest:
	return config.mystery_quests()[id]


func _state(flags: Array) -> GameState:
	var s := GameState.new()
	var fx := []
	for f in flags:
		fx.append({"op": "set_flag", "flag": f, "value": true})
	s.apply(fx)
	return s


func test_right_answer_without_clues_does_not_solve() -> void:
	var q := _quest("m01")
	var s := _state(["seen.t11", "seen.x01a", "clue.m01.recibo_mercado", "clue.m01.via_cais"])
	assert_eq(q.submit(s, "doacao_antes_da_venda"), MysteryQuest.Result.NOT_READY, "two of three clues")
	assert_true(not q.is_solved(s), "not solved")


func test_wrong_answer_costs_nothing_and_gives_the_next_hint() -> void:
	var q := _quest("m01")
	var s := _state(["seen.t11", "seen.x01a", "clue.m01.recibo_mercado", "clue.m01.via_cais", "clue.m01.carimbo_doacao"])
	s.apply([{"op": "add_bronze", "amount": 40}])
	for i in 5:
		assert_eq(q.submit(s, "cobranca_mais_antiga"), MysteryQuest.Result.WRONG, "wrong")
	assert_eq(s.bronze, 40, "no money removed")
	assert_eq(q.hint_level(s), 3, "hints stop at the last one")
	assert_eq(q.hint(s), str(q.def["hints"][2]), "third hint")
	assert_eq(q.submit(s, "doacao_antes_da_venda"), MysteryQuest.Result.CORRECT, "can still be solved")


func test_steps_follow_the_kit_order() -> void:
	var q := _quest("m02")
	var s := _state([])
	assert_eq(q.step(s), MysteryQuest.Step.LOCKED, "before Igris")
	s.apply([{"op": "set_flag", "flag": "seen.t11", "value": true}])
	assert_eq(q.step(s), MysteryQuest.Step.START, "offered")
	s.apply([{"op": "set_flag", "flag": "seen.x02a", "value": true}])
	assert_eq(q.step(s), MysteryQuest.Step.COLLECT, "collect")
	for f in q.clue_flags():
		s.apply([{"op": "set_flag", "flag": f, "value": true}])
	assert_eq(q.step(s), MysteryQuest.Step.COMPARE, "compare")
	s.apply([{"op": "set_flag", "flag": "seen.x02b", "value": true}])
	assert_eq(q.step(s), MysteryQuest.Step.ANSWER, "answer")
	q.submit(s, "chamado_resposta_pausa")
	assert_eq(q.step(s), MysteryQuest.Step.REWARD, "reward")
	s.apply([{"op": "set_flag", "flag": "seen.x02c", "value": true}])
	assert_eq(q.step(s), MysteryQuest.Step.DONE, "done")
	assert_eq(q.submit(s, "chamado_resposta_pausa"), MysteryQuest.Result.ALREADY_SOLVED, "once")


func test_relic_params_never_stack() -> void:
	var r := config.relic_loadout()
	var base := r.params("")
	var order := ["selo_restaurador", "mola_retorno", "", "selo_restaurador", ""]
	var last := {}
	for i in 60:
		last = r.params(order[i % order.size()])
	assert_eq(r.params(""), base, "base never modified")
	assert_eq(last, r.params(order[59 % order.size()]), "same relic, same numbers every time")


func test_spring_changes_only_the_hook_cooldown() -> void:
	var r := config.relic_loadout()
	var base := r.params("")
	var with := r.params("mola_retorno")
	for key in base:
		if key == "hook.return_cooldown":
			assert_true(is_equal_approx(float(with[key]), 0.25), "0.35 → 0.25")
		else:
			assert_eq(with[key], base[key], "%s unchanged" % key)


func test_seal_changes_both_times_only() -> void:
	var r := config.relic_loadout()
	var base := r.params("")
	var with := r.params("selo_restaurador")
	assert_true(is_equal_approx(float(with["healing.startup"]), 0.55), "startup 0.55")
	assert_true(is_equal_approx(float(with["healing.recovery"]), 0.30), "recovery 0.30")
	for key in base:
		if not key.begins_with("healing."):
			assert_eq(with[key], base[key], "%s unchanged" % key)


func test_relic_base_matches_combat_data() -> void:
	# Two files hold these numbers; they must agree or a relic swap changes more.
	var base := config.relic_loadout().params("")
	assert_true(is_equal_approx(float(base["healing.startup"]), float(config.data["healing"]["startup"])), "startup")
	assert_true(is_equal_approx(float(base["healing.recovery"]), float(config.data["healing"]["recovery"])), "recovery")
	assert_true(is_equal_approx(float(base["hook.return_cooldown"]), float(config.data["hook"]["return_cooldown"])), "hook cooldown")
	assert_true(is_equal_approx(float(base["guard.perfect_window"]), float(config.data["guard"]["perfect_window"])), "perfect window")
	assert_true(is_equal_approx(float(base["guard.angle_degrees"]), float(config.data["guard"]["angle_degrees"])), "shield cover")
	assert_true(is_equal_approx(float(base["player.speed"]), float(config.data["player"]["speed"])), "speed")
	assert_true(is_equal_approx(float(base["player.knockback_max"]), float(config.data["player"]["knockback"])), "knockback")


func test_equip_needs_the_slot_and_the_relic() -> void:
	var s := GameState.new()
	assert_true(not s.apply([{"op": "equip_relic", "relic_id": "mola_retorno"}]), "no slot yet")
	s.apply([{"op": "set_flag", "flag": GameState.RELIC_SLOT_FLAG, "value": true}])
	assert_true(not s.apply([{"op": "equip_relic", "relic_id": "mola_retorno"}]), "not owned")
	s.apply([{"op": "grant_unique", "item_id": "mola_retorno", "quantity": 1, "receipt_id": "t"}])
	assert_true(s.apply([{"op": "equip_relic", "relic_id": "mola_retorno"}]), "equipped")
	assert_eq(GameState.from_dict(s.to_dict()).equipped_relic, "mola_retorno", "saved")


func test_slot_takes_only_relics_and_loads_safely() -> void:
	var s := GameState.new()
	s.relic_ids = ["mola_retorno", "selo_restaurador"]
	s.apply([{"op": "set_flag", "flag": GameState.RELIC_SLOT_FLAG, "value": true},
		{"op": "grant_unique", "item_id": "gancho_retorno", "quantity": 1, "receipt_id": "a"}])
	assert_true(not s.apply([{"op": "equip_relic", "relic_id": "gancho_retorno"}]), "the hook is not a relic")
	var loaded := GameState.from_dict({"equipped_relic": "mola_retorno"})
	assert_eq(loaded.equipped_relic, "", "no slot and no item: nothing equipped")
