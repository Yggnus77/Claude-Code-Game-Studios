extends TestCase
## Integration: the screens of design/gdd/telas-e-mochila.md, after the
## user's reference screens: the opening and main menu, the HUD (segmented
## life, action slots, area panel, objective box) and the backpack
## inventory (pockets, tabs, using an item).

var main: Node
var _dir := ""
var _nodes: Array[Node] = []


func _new_main() -> Node:
	_dir = "user://test_screens/%d" % Time.get_ticks_usec()
	var m: Node = load("res://src/scenes/main.tscn").instantiate()
	m.play_intro = false
	m.save_dir = _dir
	m.settings_path = _dir.path_join("settings.cfg")
	tree.root.add_child(m)
	m.player.read_input = false
	return m


func teardown() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	if main:
		main.queue_free()
		main = null
	await tree.process_frame
	tree.paused = false


func _title(m: Node) -> TitleScreen:
	var t := TitleScreen.new(m.saves, 1)
	t.describe = m.describe_save
	t.settings = m.settings
	m.add_child(t)
	_nodes.append(t)
	return t


func _key(keycode: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.physical_keycode = keycode
	e.pressed = true
	return e


func _pad(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	e.pressed = true
	return e


func test_the_opening_waits_for_a_key_then_shows_the_main_menu() -> void:
	main = _new_main()
	var t := _title(main)
	assert_eq(t.page, TitleScreen.Page.OPENING, "starts on the opening")
	assert_true(not t.menu.visible, "no menu yet")
	assert_true(t._press.visible and t._press.text == TitleScreen.PRESS, "says press any button")
	assert_true(t._logo != null and t._logo.visible, "the game's name is drawn")
	t._unhandled_input(_key(KEY_X))
	assert_eq(t.page, TitleScreen.Page.OPENING, "a press inside the open guard is ignored")
	t._opened_at -= 1.0
	t._unhandled_input(_key(KEY_X))
	assert_eq(t.page, TitleScreen.Page.MAIN, "any key: the main menu")
	assert_eq(Array(t.menu.options), ["Novo jogo", "Configurações", "Créditos", "Sair do jogo"], "no save: no Continuar nor Carregar")


func test_a_gamepad_button_leaves_the_opening_and_b_goes_back() -> void:
	main = _new_main()
	var t := _title(main)
	t._opened_at -= 1.0
	t._unhandled_input(_pad(JOY_BUTTON_A))
	assert_eq(t.page, TitleScreen.Page.MAIN, "a pad button opens the menu")
	t.menu.selected = Array(t.menu.options).find("Créditos")
	t.menu.confirm()
	assert_eq(t.page, TitleScreen.Page.CREDITS, "credits")
	var b := InputEventAction.new()
	b.action = "ui_cancel"
	b.pressed = true
	t._unhandled_input(b)
	assert_eq(t.page, TitleScreen.Page.MAIN, "B (ui_cancel) goes back")


func test_continue_skips_a_damaged_last_slot() -> void:
	main = _new_main()
	for slot in [1, 2]:
		main.save_slot = slot
		main.save_now()
	var f := FileAccess.open(main.saves.main_path(2), FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	var t := TitleScreen.new(main.saves, 2)
	t.describe = main.describe_save
	main.add_child(t)
	_nodes.append(t)
	var got := []
	t.start.connect(func(slot: int, doc: Dictionary) -> void: got.append([slot, doc]))
	t.show_main()
	assert_eq(t._last_slot(), 1, "slot 2 was last but cannot open: slot 1")
	t.menu.confirm()
	assert_eq(got[0][0], 1, "Continuar opens slot 1")


func test_continue_on_a_recovered_slot_warns_first_and_back_returns_to_the_menu() -> void:
	main = _new_main()
	main.save_slot = 1
	main.save_now()
	main.save_now()
	var f := FileAccess.open(main.saves.main_path(1), FileAccess.WRITE)
	f.store_string("{\"schema_version\": 1, \"cut")
	f.close()
	var t := _title(main)
	t.show_main()
	assert_eq(t.menu.options[0], "Continuar", "the copy can continue")
	t.menu.confirm()
	assert_eq(t.page, TitleScreen.Page.SLOT, "the slot's notice first")
	assert_true(t.menu.options[0].contains("cópia"), "continue from the copy")
	t._back()
	assert_eq(t.page, TitleScreen.Page.MAIN, "back: the main menu, where it came from")


func test_a_damaged_only_save_still_lists_the_slots() -> void:
	main = _new_main()
	main.save_slot = 1
	main.save_now()
	var f := FileAccess.open(main.saves.main_path(1), FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	var t := _title(main)
	t.show_main()
	var rows := Array(t.menu.options)
	assert_true(not rows.has("Continuar"), "nothing to continue")
	assert_true(rows.has("Carregar jogo"), "but the slots are listed: %s" % [rows])


func test_no_on_the_confirm_page_returns_to_the_slot_page() -> void:
	main = _new_main()
	main.save_slot = 1
	main.save_now()
	var t := _title(main)
	t.show_slots(1)
	t.menu.confirm()
	assert_eq(t.page, TitleScreen.Page.SLOT, "slot 1's page")
	t.menu.selected = 1
	t.menu.confirm()
	assert_eq(t.page, TitleScreen.Page.CONFIRM, "start over?")
	t.menu.selected = 1
	t.menu.confirm()
	assert_eq(t.page, TitleScreen.Page.SLOT, "Não: back on slot 1's page")


func test_continue_opens_the_last_journey() -> void:
	main = _new_main()
	main.save_slot = 2
	assert_eq(main.save_now(), OK, "slot 2 saved")
	var t := _title(main)
	var got := []
	t.start.connect(func(slot: int, doc: Dictionary) -> void: got.append([slot, doc]))
	t.show_main()
	assert_eq(t.menu.options[0], "Continuar", "Continuar first")
	assert_true(Array(t.menu.options).has("Carregar jogo"), "and Carregar jogo")
	assert_true(t._last.text.begins_with("Última jornada · Espaço 2"), "the footer names it: %s" % t._last.text)
	t.menu.confirm()
	assert_eq(got.size(), 1, "continues")
	assert_eq(got[0][0], 2, "slot 2, the only one saved")
	assert_eq(str(got[0][1]["current_room"]), main.room_id, "with its save")


func test_new_game_takes_the_first_empty_slot() -> void:
	main = _new_main()
	main.save_slot = 1
	main.save_now()
	var t := _title(main)
	var got := []
	t.start.connect(func(slot: int, doc: Dictionary) -> void: got.append([slot, doc]))
	t.show_main()
	t.menu.selected = Array(t.menu.options).find("Novo jogo")
	t.menu.confirm()
	assert_eq(got.size(), 1, "starts at once")
	assert_eq(got[0][0], 2, "in slot 2, the first empty one")
	assert_true(got[0][1].is_empty(), "as a new game")


func test_new_game_with_every_slot_full_asks_before_replacing() -> void:
	main = _new_main()
	for slot in [1, 2, 3]:
		main.save_slot = slot
		main.save_now()
	var t := _title(main)
	var got := []
	t.start.connect(func(slot: int, doc: Dictionary) -> void: got.append([slot, doc]))
	t.show_main()
	t.menu.selected = Array(t.menu.options).find("Novo jogo")
	t.menu.confirm()
	assert_eq(t.page, TitleScreen.Page.SLOTS, "pick a slot")
	t.menu.selected = 2
	t.menu.confirm()
	assert_eq(t.page, TitleScreen.Page.CONFIRM, "asks before replacing slot 3")
	assert_eq(got.size(), 0, "nothing started yet")
	t.menu.selected = 0
	t.menu.confirm()
	assert_eq(got.size(), 1, "started")
	assert_eq(got[0][0], 3, "in slot 3")
	assert_true(got[0][1].is_empty(), "as a new game")


func test_back_from_the_slot_list_returns_to_the_main_menu() -> void:
	main = _new_main()
	main.save_slot = 1
	assert_eq(main.save_now(), OK, "saved")
	var t := _title(main)
	t.show_main()
	t.menu.selected = Array(t.menu.options).find("Carregar jogo")
	t.menu.confirm()
	assert_eq(t.page, TitleScreen.Page.SLOTS, "slot list")
	t._back()
	assert_eq(t.page, TitleScreen.Page.MAIN, "back on the main menu")
	assert_eq(t.menu.options[t.menu.selected], "Carregar jogo", "on the option it came from")


func test_the_life_bar_has_one_segment_per_point() -> void:
	main = _new_main()
	main.load_room("v01_praca")
	main.clear_enemies()
	var p: Player = main.player
	p.receive_hit(1, p.global_position + Vector2(0, -20))
	assert_eq(main.hud.life_text(), "5/6", "one segment lost")
	assert_eq(main.hud.life_numbers(), "5 / 6", "the panel's numbers")
	assert_eq(main.hud.life_segments(), Vector2i(5, 6), "five of six segments filled")
	assert_eq(Hud.segment_width(6), 20.0, "6 points: 20 px each")
	assert_eq(Hud.segment_width(14), 7.0, "14 points: 7 px each (§4)")
	assert_true(main.hud._area_name == "VERSALHES", "the area panel names the region: %s" % main.hud._area_name)
	main.load_room("t01_guardas")
	assert_eq(main.hud._area_name, "TORRE DE AKURAME", "the tower")


func test_the_objective_box_hides_without_a_goal() -> void:
	main = _new_main()
	main.hud.set_objective("")
	assert_true(not main.hud._objective_box.visible, "hidden")
	main.hud.set_objective("Examine o relógio.")
	assert_true(main.hud._objective_box.visible, "shown")
	assert_eq(main.hud.objective_text(), "Examine o relógio.", "the text")


func test_the_backpack_lists_items_by_kind_and_tab() -> void:
	main = _new_main()
	main.state.apply([{"op": "grant_unique", "item_id": "lamparina_oleo", "quantity": 1, "receipt_id": "t.lamp"},
		{"op": "grant_unique", "item_id": "espada_oficina", "quantity": 1, "receipt_id": "t.sword"},
		{"op": "grant_unique", "item_id": "arco_fio", "quantity": 1, "receipt_id": "t.arco"},
		{"op": "add_item", "item_id": "pao_porto", "quantity": 2}])
	main.hud.toggle_inventory(main.state, main.config)
	var bag: InventoryScreen = main.hud.inventory()
	assert_true(main.hud.is_inventory_open(), "open")
	assert_eq(bag.pockets[0], "espada_oficina", "weapons first")
	assert_true(bag.pockets.has("pao_porto") and bag.pockets.has("lamparina_oleo"), "everything carried: %s" % [bag.pockets])
	assert_true(bag.pockets.find("lamparina_oleo") < bag.pockets.find("pao_porto"), "tools before food")
	for id: String in bag.pockets:
		assert_true(UiArt.icon(id) != null, "%s is drawn" % id)
	assert_true(not main.hud._status.visible and not main.hud._slots.visible, "the play HUD hides under the backpack")
	assert_true(not bag.tab_open(4) and not bag.tab_open(6), "no Magias nor Relíquias tab yet")
	bag.next_tab()
	assert_true(bag.pockets.has("espada_oficina") and not bag.pockets.has("arco_fio"), "Equipamento: the sword, not the bow: %s" % [bag.pockets])
	bag.next_tab()
	assert_true(bag.pockets.has("arco_fio") and bag.pockets.has("lamparina_oleo"), "Ferramentas: bow and lamp: %s" % [bag.pockets])
	assert_true(not bag.pockets.has("pao_porto"), "no bread there")
	main.hud.toggle_inventory(main.state, main.config)


func test_the_cursor_moves_across_the_pockets() -> void:
	main = _new_main()
	for id: String in ["espada_oficina", "escudo_bronze", "lamparina_oleo", "gancho_retorno", "arco_fio", "matrix", "mapa_akurame"]:
		main.state.apply([{"op": "grant_unique", "item_id": id, "quantity": 1, "receipt_id": "t." + id}])
	main.hud.toggle_inventory(main.state, main.config)
	var bag: InventoryScreen = main.hud.inventory()
	var n := bag.pockets.size()
	assert_true(n >= 7, "seven items and the starting flask (%d)" % n)
	bag.move(Vector2i.LEFT)
	assert_eq(bag.selected, n - 1, "left from the first wraps to the last")
	bag.select(0)
	bag.move(Vector2i.DOWN)
	assert_eq(bag.selected, 6, "down: the next row of six")
	bag.move(Vector2i.DOWN)
	assert_eq(bag.selected, 0, "past the last row: back to the top")
	bag.select(3)
	bag.move(Vector2i.DOWN)
	assert_eq(bag.selected, n - 1, "down onto a short last row: its last pocket")
	main.hud.toggle_inventory(main.state, main.config)


func test_using_a_tool_in_the_backpack_puts_it_on_the_item_button() -> void:
	main = _new_main()
	main.state.apply([{"op": "grant_unique", "item_id": "lamparina_oleo", "quantity": 1, "receipt_id": "t.lamp"},
		{"op": "grant_unique", "item_id": "gancho_retorno", "quantity": 1, "receipt_id": "t.gancho"}])
	main.hud.toggle_inventory(main.state, main.config)
	var bag: InventoryScreen = main.hud.inventory()
	bag.select(bag.pockets.find("gancho_retorno"))
	bag.use_selected()
	assert_eq(main.equipped, "gancho", "the hook is on the button")
	assert_true(bag.status.begins_with("Gancho"), "says so: %s" % bag.status)
	assert_true(main.hud.is_equipped.call("gancho_retorno"), "marked as equipped")
	bag.select(bag.pockets.find("frasco_01"))
	bag.use_selected()
	assert_eq(main.equipped, "frasco", "a flask puts the flask back")
	main.hud.toggle_inventory(main.state, main.config)


func test_a_relic_is_equipped_and_removed_from_the_backpack() -> void:
	main = _new_main()
	main.clear_enemies()
	main.state.apply([{"op": "set_flag", "flag": GameState.RELIC_SLOT_FLAG, "value": true},
		{"op": "grant_unique", "item_id": "mola_retorno", "quantity": 1, "receipt_id": "t.mola"}])
	assert_eq(main.use_from_backpack("mola_retorno"), "Relíquia: Mola de Retorno.", "equipped")
	assert_eq(main.state.equipped_relic, "mola_retorno", "in the slot")
	assert_eq(main.use_from_backpack("mola_retorno"), "Relíquia: nenhuma.", "again: taken off")
	assert_eq(main.state.equipped_relic, "", "slot empty")
	assert_eq(main.use_from_backpack("pao_porto"), "", "bread: nothing to equip")


func test_an_empty_tab_and_an_unknown_item_still_read_well() -> void:
	main = _new_main()
	main.state.apply([{"op": "set_flag", "flag": GameState.RELIC_SLOT_FLAG, "value": true}])
	main.hud.toggle_inventory(main.state, main.config)
	var bag: InventoryScreen = main.hud.inventory()
	assert_true(bag.tab_open(6), "Relíquias with the slot")
	bag.tab = 6
	bag.refresh()
	assert_true(bag.pockets.is_empty(), "no relic yet")
	assert_eq(bag._name.text, "Nada aqui ainda", "says so")
	assert_eq(UiArt.icon("item_que_nao_existe").region, UiArt.icon("_generico").region, "an unknown item gets the pouch")
	main.hud.toggle_inventory(main.state, main.config)


func test_more_than_24_items_scroll_by_rows() -> void:
	main = _new_main()
	var n := 0
	for id: String in main.config.items:
		if n >= 30:
			break
		main.state.apply([{"op": "grant_unique", "item_id": id, "quantity": 1, "receipt_id": "t.many." + id}])
		n += 1
	main.hud.toggle_inventory(main.state, main.config)
	var bag: InventoryScreen = main.hud.inventory()
	assert_true(bag.pockets.size() > 24, "%d items" % bag.pockets.size())
	bag.select(bag.pockets.size() - 1)
	assert_eq(bag.first_row, (bag.pockets.size() - 1) / 6 - 3, "the last row is in view")
	bag.select(0)
	assert_eq(bag.first_row, 0, "back to the top")
	main.hud.toggle_inventory(main.state, main.config)


func test_tab_opens_the_backpack_paused_and_esc_closes_it() -> void:
	main = _new_main()
	main.load_room("v01_praca")
	main.clear_enemies()
	await tree.process_frame
	var tab := InputEventAction.new()
	tab.action = "map"
	tab.pressed = true
	main._unhandled_input(tab)
	assert_true(main.hud.is_inventory_open() and tree.paused, "open and paused")
	var esc := InputEventAction.new()
	esc.action = "pause"
	esc.pressed = true
	main.hud._unhandled_input(esc)
	assert_true(not main.hud.is_inventory_open() and not tree.paused, "closed and running")
	assert_true(main.hud._status.visible, "the play HUD is back")


func test_a_relic_cannot_change_in_combat_from_the_backpack() -> void:
	main = _new_main()
	main.load_room("v01_praca")
	main.clear_enemies()
	main.state.apply([{"op": "set_flag", "flag": GameState.RELIC_SLOT_FLAG, "value": true},
		{"op": "grant_unique", "item_id": "mola_retorno", "quantity": 1, "receipt_id": "t.mola"}])
	var e: EnemyBase = main.spawn_enemy("soldado_corda", Vector2i(10, 12))
	e.set_physics_process(false)
	e.global_position = main.player.global_position + Vector2(30, 0)
	assert_eq(main.use_from_backpack("mola_retorno"), "Não dá para trocar a relíquia em combate.", "not in combat")
	assert_eq(main.state.equipped_relic, "", "slot unchanged")


func test_the_flask_on_the_button_has_no_second_slot() -> void:
	main = _new_main()
	main.state.apply([{"op": "grant_unique", "item_id": "lamparina_oleo", "quantity": 1, "receipt_id": "t.lamp"},
		{"op": "grant_unique", "item_id": "espada_oficina", "quantity": 1, "receipt_id": "t.sword"}])
	var labels := func() -> Array: return main.hud.action_slots().map(func(x: Array) -> String: return str(x[1]))
	assert_true((labels.call() as Array).has("Lamparina"), "the lamp has its slot: %s" % [labels.call()])
	main.quick_swap()
	assert_eq(main.equipped, "frasco", "flask on the button")
	var slots: Array = main.hud.action_slots()
	assert_eq(slots.size(), 2, "Atacar and Cura only: %s" % [labels.call()])
	assert_eq(str(slots[1][2]), "item", "Cura carries the item key")
	assert_true(bool(slots[1][4]), "and the swap mark")
	assert_true(not bool(slots[0][4]), "not on Atacar")
