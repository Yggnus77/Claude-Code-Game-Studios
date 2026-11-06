extends TestCase
## GameState transactions, receipts and Bronze (integracao-e-salvamento §3, §5).


func test_bronze_overflow_goes_to_reserve() -> void:
	var s := GameState.new()
	s.bronze = 190
	s.apply([{"op": "grant_bronze_unique", "amount": 100, "receipt_id": "loot.a"}])
	assert_eq(s.bronze, 200, "purse fills to 200")
	assert_eq(s.bronze_reserve, 90, "90 goes to the reserve")
	s.apply([{"op": "grant_bronze_unique", "amount": 100, "receipt_id": "loot.a"}])
	assert_eq([s.bronze, s.bronze_reserve], [200, 90], "reopening the same pickup changes nothing")


func test_unique_grant_once() -> void:
	var s := GameState.new()
	var e := [{"op": "grant_unique", "item_id": "matrix", "quantity": 1, "receipt_id": "scene.p04.matrix"}]
	s.apply(e)
	s.apply(e)
	assert_eq(s.item_count("matrix"), 1, "same receipt grants once")


func test_transaction_is_all_or_nothing() -> void:
	var s := GameState.new()
	var ok := s.apply([
		{"op": "set_flag", "flag": "seen.r04", "value": true},
		{"op": "consume_quest_items_once", "items": {"peca_bomba_a": 1}, "receipt_id": "quest.pump.parts"},
	])
	assert_true(not ok, "missing quest item fails the transaction")
	assert_true(not s.has_flag("seen.r04"), "and the flag set before it is rolled back")
	assert_true(not s.apply([{"op": "no_such_op"}]), "unknown effects are refused")


func test_consume_quest_items_once() -> void:
	var s := GameState.new()
	s.items = {"peca_bomba_a": 1, "peca_bomba_b": 1}
	var e := [{"op": "consume_quest_items_once", "items": {"peca_bomba_a": 1, "peca_bomba_b": 1}, "receipt_id": "quest.pump.parts"}]
	assert_true(s.apply(e), "consumes when present")
	assert_eq(s.items, {}, "both parts gone")
	assert_true(s.apply(e), "repeating is a no-op")


func test_capacities_never_shrink() -> void:
	var s := GameState.new()
	s.apply([{"op": "set_wallet_capacity_min", "value": 1500}])
	s.apply([{"op": "set_wallet_capacity_min", "value": 600}])
	assert_eq(s.wallet_capacity, 1500, "a later smaller purse keeps 1500 (auditoria item 13)")


func test_life_from_fragments() -> void:
	var s := GameState.new()
	for i in 7:
		s.apply([{"op": "collect_fragment", "fragment_id": "fragment_%02d" % i, "receipt_id": "collectible.%d" % i}])
	assert_eq(s.life_max(), 7, "7 fragments: 6 + 1")
	for i in 40:
		s.apply([{"op": "collect_fragment", "fragment_id": "f%d" % i, "receipt_id": "c%d" % i}])
	assert_eq(s.life_max(), 14, "capped at 14")
