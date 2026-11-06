extends TestCase
## Flasks, bread, the merchant and Bronze pickups (Etapa 5;
## auditoria-e-decisoes.md items 2 and 14, integracao-e-salvamento.md §5).


func _config() -> GameConfig:
	return GameConfig.load_all()


func _state_with_first_flask() -> GameState:
	var s := GameState.new()
	s.apply([{"op": "grant_unique", "item_id": "frasco_01", "quantity": 1, "receipt_id": "new_game.frasco_01"}])
	return s


func test_new_flask_is_empty_and_refills_once() -> void:
	var s := _state_with_first_flask()
	assert_eq(s.flasks(), ["frasco_01"], "one flask")
	assert_eq(s.full_flask_count(), 0, "it starts empty")
	assert_true(s.apply([{"op": "refill_flask"}]), "refill")
	assert_eq(s.full_flask_count(), 1, "now full")
	assert_true(not s.apply([{"op": "refill_flask"}]), "nothing left to refill")
	assert_true(s.apply([{"op": "drink_flask"}]), "drink")
	assert_true(not s.apply([{"op": "drink_flask"}]), "cannot drink an empty flask")


func test_pump_gives_only_the_second_flask() -> void:
	var s := _state_with_first_flask()
	s.apply([
		{"op": "grant_unique", "item_id": "peca_bomba_a", "quantity": 1, "receipt_id": "reward.pump.a"},
		{"op": "grant_unique", "item_id": "peca_bomba_b", "quantity": 1, "receipt_id": "reward.pump.b"},
	])
	var r04 := [
		{"op": "consume_quest_items_once", "items": {"peca_bomba_a": 1, "peca_bomba_b": 1}, "receipt_id": "quest.pump.parts"},
		{"op": "grant_unique", "item_id": "frasco_02", "quantity": 1, "receipt_id": "scene.r04.frasco_02"},
	]
	assert_true(s.apply(r04), "pump repaired")
	assert_true(s.apply(r04), "replaying the scene is harmless")
	assert_eq(s.flasks(), ["frasco_01", "frasco_02"], "two flasks, the pump's is the second")
	assert_eq(s.item_count("frasco_02"), 1, "never two pump flasks")
	assert_eq(s.item_count("peca_bomba_a"), 0, "parts handed over")
	assert_eq(s.flask_capacity, 2, "capacity stays at the starting two")


func test_flasks_never_exceed_capacity() -> void:
	var s := _state_with_first_flask()
	s.apply([
		{"op": "grant_unique", "item_id": "frasco_02", "quantity": 1, "receipt_id": "a"},
		{"op": "grant_unique", "item_id": "frasco_03", "quantity": 1, "receipt_id": "b"},
	])
	assert_eq(s.flasks().size(), 2, "a third flask without a third slot is not usable")


func test_two_travel_reserves_buy_one_refill() -> void:
	var s := _state_with_first_flask()
	var shop := Shop.new(_config())
	var refill: Dictionary = shop.offers[1]
	s.apply([{"op": "grant_bronze_unique", "amount": 10, "receipt_id": "loot.v01_praca.reserva_viagem"}])
	assert_true(not shop.buy(s, refill), "10 Bronze is not enough")
	assert_eq(s.bronze, 10, "nothing charged")
	s.apply([{"op": "grant_bronze_unique", "amount": 10, "receipt_id": "loot.r00_estrada.apoio_estrada"}])
	assert_true(shop.buy(s, refill), "20 Bronze buys the refill")
	assert_eq(s.bronze, 0, "paid 20")
	assert_eq(s.full_flask_count(), 1, "flask filled")


func test_refused_purchase_costs_nothing() -> void:
	var s := _state_with_first_flask()
	var shop := Shop.new(_config())
	s.apply([{"op": "add_bronze", "amount": 100}, {"op": "refill_flask"}])
	assert_eq(shop.refusal(s, shop.offers[1]), "Seus frascos já estão cheios.", "explains why")
	assert_true(not shop.buy(s, shop.offers[1]), "no refill when full")
	assert_eq(s.bronze, 100, "no Bronze lost")
	for i in 10:
		shop.buy(s, shop.offers[0])
	assert_eq(s.item_count("pao_porto"), 10, "bread up to the stack limit")
	assert_true(not shop.buy(s, shop.offers[0]), "the eleventh does not fit")
	assert_eq(s.bronze, 50, "only ten breads were paid")


func test_drops_overflow_to_reserve() -> void:
	var s := GameState.new()
	s.apply([{"op": "add_bronze", "amount": 190}])
	s.apply([{"op": "add_bronze", "amount": 100}])
	assert_eq(s.bronze, 200, "bag full at 200")
	assert_eq(s.bronze_reserve, 90, "90 to the reserve")
	assert_eq(Pickup.bronze_amount("bronze_5"), 5, "drop id parsed")
	assert_eq(Pickup.bronze_amount("energy_10"), 0, "energy drops are not Bronze")


func test_flask_state_is_saved() -> void:
	var s := _state_with_first_flask()
	s.apply([{"op": "refill_flask"}])
	var copy := GameState.from_dict(s.to_dict())
	assert_eq(copy.full_flask_count(), 1, "full flask survives a save")
