extends TestCase
## Prologue rules: scene order, objectives, the invasion and its exit
## (plano-implementacao.md Etapa 4).

const BINDINGS := ["v00_oficina.yame_bind_1", "v00_oficina.yame_bind_2", "v00_oficina.yame_bind_3"]
const DOOR := "door.v00_oficina.v01_praca"


func _rules() -> Prologue:
	return Prologue.new({"bindings": BINDINGS, "blocks_exit": DOOR, "start_after": "seen.p05", "projectile_interval": [1.8, 1.5, 1.2]})


func _state(flags: Array) -> GameState:
	var s := GameState.new()
	var effects := []
	for f in flags:
		effects.append({"op": "set_flag", "flag": f, "value": true})
	s.apply(effects)
	return s


func test_square_and_workshop_entries_follow_the_story() -> void:
	var r := _rules()
	assert_eq(r.trigger_on_enter(_state([]), "v01_praca"), "", "nothing before the clock rings")
	assert_eq(r.trigger_on_enter(_state(["seen.p01"]), "v01_praca"), "decima_terceira_badalada", "p02 in the square")
	assert_eq(r.trigger_on_enter(_state(["seen.p01", "seen.p02"]), "v01_praca"), "", "p02 only once")
	assert_eq(r.trigger_on_enter(_state(["seen.p02"]), "v00_oficina"), "adally_apresentada", "p03 back in the workshop")
	assert_eq(r.trigger_on_enter(_state(["seen.p02", "seen.p03"]), "v00_oficina"), "", "p03 only once")


func test_workshop_scenes_chain() -> void:
	var r := _rules()
	assert_eq(r.trigger_after("p03"), "exodia_abre_relogio", "p03 → p04")
	assert_eq(r.trigger_after("p04"), "yame_entra", "p04 → p05")
	assert_eq(r.trigger_after("p05"), "", "p05 hands over to play")


func test_invasion_runs_from_p05_to_p07() -> void:
	var r := _rules()
	assert_true(not r.invasion_active(_state(["seen.p04"])), "not before p05")
	assert_true(r.invasion_active(_state(["seen.p05"])), "during")
	assert_true(not r.invasion_active(_state(["seen.p05", "seen.p07"])), "over after p07")


func test_exit_tied_only_from_inside_during_invasion() -> void:
	var r := _rules()
	var s := _state(["seen.p05"])
	assert_true(r.blocks_door(s, "v00_oficina", DOOR), "workshop exit is tied")
	assert_true(not r.blocks_door(s, "v01_praca", DOOR), "coming back in from the square is allowed")
	assert_true(not r.blocks_door(_state(["seen.p05", "seen.p07"]), "v00_oficina", DOOR), "free after p07")


func test_cut_bindings_are_receipts() -> void:
	var r := _rules()
	var s := _state(["seen.p05"])
	assert_eq(r.bindings_left(s).size(), 3, "three at start")
	s.apply([{"op": "add_receipt", "receipt_id": Prologue.binding_receipt(BINDINGS[1])}])
	assert_eq(r.bindings_left(s), [BINDINGS[0], BINDINGS[2]], "the cut one is gone")
	assert_near(r.throw_interval(s), 1.5, 0.001, "Yame throws faster after a cut")
	for b in BINDINGS:
		s.apply([{"op": "add_receipt", "receipt_id": Prologue.binding_receipt(b)}])
	assert_true(r.all_bindings_cut(s), "all cut")


func test_objective_away_from_the_workshop_says_to_go_back() -> void:
	var r := _rules()
	var s := _state(["seen.p00", "seen.p01", "seen.p02", "seen.p05"])
	var away := r.objective(s, "v01_praca")
	assert_true(away.contains("Volte à oficina") and away.contains("correntes"), "away from the workshop: go back (got '%s')" % away)
	var inside := r.objective(s, Prologue.WORKSHOP)
	assert_true(inside.begins_with("Quebre as correntes"), "in the workshop: cut the bindings (got '%s')" % inside)


func test_objective_always_says_what_to_do() -> void:
	var r := _rules()
	var steps := [
		[["seen.p00"], "relógio"],
		[["seen.p00", "seen.p01"], "praça"],
		[["seen.p00", "seen.p01", "seen.p02"], "oficina"],
		[["seen.p00", "seen.p01", "seen.p02", "seen.p05"], "correntes"],
		[["seen.p00", "seen.p01", "seen.p02", "seen.p05", "seen.p07"], "Marco"],
		[["seen.p00", "seen.p01", "seen.p02", "seen.p05", "seen.p07", "seen.p08"], "estrada"],
		[["seen.p00", "seen.p01", "seen.p02", "seen.p05", "seen.p07", "seen.p08", "visited.t00_base"], "guardas"],
		[["seen.p00", "seen.p01", "seen.p02", "seen.p05", "seen.p07", "seen.p08", "visited.t00_base", "world.guards_clear", "seen.t03"], "gancho"],
		[["seen.p00", "seen.p01", "seen.p02", "seen.p05", "seen.p07", "seen.p08", "visited.t00_base", "world.guards_clear", "seen.t03", "world.weight_locked"], "sinos"],
		[["seen.p00", "seen.p01", "seen.p02", "seen.p05", "seen.p07", "seen.p08", "visited.t00_base", "world.guards_clear", "seen.t03", "world.weight_locked", "world.bells_solved"], "Chave Grande"],
		[["seen.p00", "seen.p01", "seen.p02", "seen.p05", "seen.p07", "seen.p08", "visited.t00_base", "world.guards_clear", "seen.t03", "world.weight_locked", "world.bells_solved", "visited.t07_igris"], "Igris"],
	]
	for step in steps:
		var text := r.objective(_state(step[0]))
		assert_true(text.contains(step[1]), "objective mentions '%s' (got '%s')" % [step[1], text])
