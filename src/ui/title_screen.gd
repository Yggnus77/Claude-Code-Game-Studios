class_name TitleScreen
extends CanvasLayer
## The first screens (design/gdd/telas-e-mochila.md §3.1, after the user's
## reference screens): the opening picture with the game's name and "press
## any button", then the main menu (Continuar, Novo jogo, Carregar jogo,
## Configurações, Créditos, Sair do jogo) with the last journey below.
## The three save slots keep their rules (integracao-e-salvamento.md §7):
## an empty slot starts a new game; a saved one continues or starts over;
## a damaged file says so plainly, names the recovery used and is never
## deleted without the player choosing to start over.

## [param doc] is the save to continue, or empty for a new game.
signal start(slot: int, doc: Dictionary)
## The settings menu changed something (already saved).
signal settings_changed

enum Page { OPENING, MAIN, SLOTS, SLOT, CONFIRM, CREDITS }

const TAGLINE := "Toda memória deixa um caminho."
const SUBTITLE := "Memórias de um mundo esquecido"
const PRESS := "Pressione qualquer botão"
const CREDITS := "História, mundo e imagem de abertura: Yggnus77.\nProgramação e pixel art: Claude, com o Claude Code Game Studios.\nFeito com Godot Engine (licença MIT)."
const LOGO_OPENING := Vector2(34, 104)
const LOGO_MENU := Vector2(34, 22)
const MENU_AT := Vector2(30, 112)

var store: SaveStore
## One line about a save document (room and play time), from the game.
var describe: Callable = func(_doc: Dictionary) -> String: return ""
## Player settings; set, the main menu offers "Configurações".
var settings: Settings
## Closes the game ("Sair do jogo").
var on_quit: Callable = func() -> void: get_tree().quit()
var settings_screen: SettingsScreen
var menu: MenuPanel
var page: Page = Page.OPENING
## Slot shown in the per-slot menu, or 0.
var _slot := 0
## True when the slot list was opened by "Novo jogo".
var _new_game := false
## True when the slot page was opened by "Continuar" (back: main menu).
var _from_main := false
## True when the confirm page came from a slot's own page.
var _confirm_from_slot := false
var _reads: Dictionary = {}
var _main_actions: Array[Callable] = []
var _first_slot := 1
var _time := 0.0
var _opened_at := 0.0
var _fx: Control
var _logo: TextureRect
var _name_fallback: Label
var _rule: ColorRect
var _tagline: Label
var _subtitle: Label
var _press: Label
var _footer: Label
var _last: Label


func _init(save_store: SaveStore, first_slot: int = 1) -> void:
	store = save_store
	_first_slot = first_slot


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	var bg_tex := UiArt.texture("titulo.png")
	if bg_tex:
		var bg := TextureRect.new()
		bg.texture = bg_tex
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
	else:
		var back := ColorRect.new()
		back.color = Color("101218")
		back.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(back)
	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	var logo_tex := UiArt.texture("logo.png")
	if logo_tex:
		_logo = TextureRect.new()
		_logo.texture = logo_tex
		add_child(_logo)
	else:
		_name_fallback = _label("A Lenda de Yggnus", 24, UiArt.CREAM)
		add_child(_name_fallback)
	_rule = ColorRect.new()
	_rule.color = Color(UiArt.CREAM, 0.6)
	_rule.size = Vector2(230, 1)
	add_child(_rule)
	_tagline = _label(TAGLINE, 10, UiArt.TEXT)
	add_child(_tagline)
	_press = _label(PRESS, 12, UiArt.ACCENT)
	add_child(_press)
	_footer = _label("Áudio e controles disponíveis no menu", 8, UiArt.DIM)
	_footer.position = Vector2(34, 334)
	add_child(_footer)
	_subtitle = _label(SUBTITLE, 9, UiArt.ACCENT)
	add_child(_subtitle)
	_last = _label("", 8, UiArt.DIM)
	_last.position = Vector2(36, 316)
	add_child(_last)
	menu = MenuPanel.new()
	menu.anchor = MENU_AT
	menu.set_framed(false)
	add_child(menu)
	menu.chosen.connect(_on_chosen)
	show_opening()


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.06, 0.9))
	l.add_theme_constant_override("outline_size", 3)
	return l


func _place_logo(at: Vector2) -> void:
	if _logo:
		_logo.position = at
	elif _name_fallback:
		_name_fallback.position = at


## The opening: picture, name, tagline and "press any button".
func show_opening() -> void:
	page = Page.OPENING
	_opened_at = _now()
	_place_logo(LOGO_OPENING)
	_rule.position = LOGO_OPENING + Vector2(2, 74)
	_tagline.position = LOGO_OPENING + Vector2(2, 84)
	_press.position = LOGO_OPENING + Vector2(2, 150)
	for n: CanvasItem in [_rule, _tagline, _press, _footer]:
		n.visible = true
	_subtitle.visible = false
	_last.visible = false
	menu.visible = false


## The main menu, with [param highlight] picked (an action's label).
func show_main(highlight: String = "") -> void:
	page = Page.MAIN
	_slot = 0
	_new_game = false
	_read_slots()
	_place_logo(LOGO_MENU)
	for n: CanvasItem in [_rule, _tagline, _press, _footer]:
		n.visible = false
	_subtitle.visible = true
	_subtitle.position = LOGO_MENU + Vector2(4, 70)
	var rows := PackedStringArray()
	_main_actions.clear()
	var last := _last_slot()
	if last > 0:
		rows.append("Continuar")
		_main_actions.append(func() -> void: _continue(last))
	rows.append("Novo jogo")
	_main_actions.append(_new_game_pick)
	# A damaged or newer-version file still lists the slots, so the player
	# sees what happened to it.
	var used := _first_used_slot()
	if used > 0:
		rows.append("Carregar jogo")
		_main_actions.append(func() -> void: show_slots(last if last > 0 else used))
	if settings != null:
		rows.append("Configurações")
		_main_actions.append(open_settings)
	rows.append("Créditos")
	_main_actions.append(_show_credits)
	rows.append("Sair do jogo")
	_main_actions.append(func() -> void: on_quit.call())
	menu.max_rows = 0
	menu.show_menu("", "", rows, maxi(0, rows.find(highlight)))
	_last.visible = last > 0
	if last > 0:
		_last.text = "Última jornada · Espaço %d · %s" % [last, describe.call(_reads[last]["data"])]


## The slot list ("Carregar jogo", or "Novo jogo" with no empty slot), with
## [param highlight] (1–3) picked.
func show_slots(highlight: int = 1) -> void:
	page = Page.SLOTS
	_slot = 0
	_read_slots()
	_hide_opening()
	var rows := PackedStringArray()
	for slot in range(1, SaveStore.SLOT_COUNT + 1):
		rows.append("Espaço %d · %s" % [slot, _row_text(_reads[slot])])
	menu.show_menu("Escolha um espaço para o novo jogo" if _new_game else "Carregar jogo", "", rows, highlight - 1, "volta")


## Opens the settings menu over the main menu.
func open_settings() -> void:
	if settings == null:
		return
	if settings_screen == null:
		settings_screen = SettingsScreen.new(settings)
		add_child(settings_screen)
		settings_screen.closed.connect(func() -> void: show_main("Configurações"))
		settings_screen.changed.connect(settings_changed.emit)
	menu.visible = false
	settings_screen.open()


func _hide_opening() -> void:
	_place_logo(LOGO_MENU)
	for n: CanvasItem in [_rule, _tagline, _press, _footer]:
		n.visible = false
	_subtitle.visible = true
	_subtitle.position = LOGO_MENU + Vector2(4, 70)
	_last.visible = false


func _read_slots() -> void:
	for slot in range(1, SaveStore.SLOT_COUNT + 1):
		_reads[slot] = store.read(slot)


func _can_continue(slot: int) -> bool:
	var st := int(_reads[slot]["status"])
	return st == SaveStore.Status.OK or st == SaveStore.Status.RECOVERED


## The slot "Continuar" opens: the last one played if it can continue,
## else the first that can; 0 when none can.
func _last_slot() -> int:
	if _reads.has(_first_slot) and _can_continue(_first_slot):
		return _first_slot
	for slot in range(1, SaveStore.SLOT_COUNT + 1):
		if _can_continue(slot):
			return slot
	return 0


## The first slot that is not empty (any status), or 0.
func _first_used_slot() -> int:
	for slot in range(1, SaveStore.SLOT_COUNT + 1):
		if int(_reads[slot]["status"]) != SaveStore.Status.EMPTY:
			return slot
	return 0


func _continue(slot: int) -> void:
	if int(_reads[slot]["status"]) == SaveStore.Status.OK:
		start.emit(slot, _reads[slot]["data"])
	else:
		_open_slot(slot)
		_from_main = true


## "Novo jogo": the first empty slot starts at once; with none empty the
## player picks one to replace.
func _new_game_pick() -> void:
	for slot in range(1, SaveStore.SLOT_COUNT + 1):
		if int(_reads[slot]["status"]) == SaveStore.Status.EMPTY:
			start.emit(slot, {})
			return
	_new_game = true
	show_slots(1)


func _show_credits() -> void:
	page = Page.CREDITS
	_hide_opening()
	menu.show_menu("Créditos", CREDITS, ["Voltar"], 0, "volta")


func _row_text(r: Dictionary) -> String:
	match int(r["status"]):
		SaveStore.Status.EMPTY:
			return "vazio (novo jogo)"
		SaveStore.Status.DAMAGED:
			return "arquivo danificado"
		SaveStore.Status.FUTURE:
			return "salvo por uma versão mais nova"
	var text := str(describe.call(r["data"]))
	return text + (" (cópia recuperada)" if int(r["status"]) == SaveStore.Status.RECOVERED else "")


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(delta: float) -> void:
	_time += delta
	if _press.visible:
		_press.modulate.a = 0.55 + 0.45 * sin(_time * 3.2)
	_fx.queue_redraw()


## Soft glow on the crystal in Yggnus's hand and slow motes of light.
func _draw_fx() -> void:
	var at := Vector2(484, 90)
	var info: Variant = UiArt.meta().get("titulo", {}).get("crystal", null)
	if info is Array and (info as Array).size() == 2:
		at = Vector2(float(info[0]), float(info[1]))
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	for i in 4:
		_fx.draw_circle(at, 4.0 + i * 3.5 + pulse * 2.0, Color(0.4, 0.95, 0.95, 0.10 - i * 0.02))
	for k in 18:
		var seed_x := fmod(k * 97.31, 640.0)
		var speed := 6.0 + fmod(k * 13.7, 10.0)
		var y := 360.0 - fmod(_time * speed + k * 41.0, 380.0)
		var x := seed_x + sin(_time * 0.7 + k) * 8.0
		var a := 0.25 + 0.25 * sin(_time * 2.0 + k * 1.7)
		_fx.draw_rect(Rect2(x, y, 1, 1), Color(1.0, 0.85, 0.5, a))


func _unhandled_input(event: InputEvent) -> void:
	if page == Page.OPENING:
		var pressed := (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo()
		if pressed and _now() - _opened_at >= MenuPanel.OPEN_GUARD:
			show_main()
			get_viewport().set_input_as_handled()
		return
	if settings_screen != null and settings_screen.is_open():
		return
	if page != Page.MAIN and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_back()
		get_viewport().set_input_as_handled()


## The pause key: one step back.
func _back() -> void:
	match page:
		Page.SLOT:
			if _from_main:
				show_main("Continuar")
			else:
				show_slots(_slot)
		Page.CONFIRM:
			if _confirm_from_slot:
				var from_main := _from_main
				_open_slot(_slot)
				_from_main = from_main
			else:
				show_slots(_slot)
		_:
			show_main("Novo jogo" if _new_game else ("Carregar jogo" if page == Page.SLOTS else "Créditos"))


func _on_chosen(index: int) -> void:
	match page:
		Page.MAIN:
			if index < _main_actions.size():
				_main_actions[index].call()
		Page.SLOTS:
			_open_slot(index + 1)
		Page.CONFIRM:
			if index == 0:
				start.emit(_slot, {})
			else:
				_back()
		Page.SLOT:
			_on_slot_action(index)
		Page.CREDITS:
			show_main("Créditos")


func _open_slot(slot: int) -> void:
	var r: Dictionary = _reads[slot]
	if int(r["status"]) == SaveStore.Status.EMPTY:
		start.emit(slot, {})
		return
	_slot = slot
	_from_main = false
	if _new_game:
		_confirm_start_over(false)
		return
	page = Page.SLOT
	var title := "Espaço %d" % slot
	match int(r["status"]):
		SaveStore.Status.OK:
			menu.show_menu(title, str(describe.call(r["data"])), ["Continuar", "Começar de novo", "Voltar"], 0, "volta")
		SaveStore.Status.RECOVERED:
			menu.show_menu(title, "O último salvamento ficou incompleto ou danificado. Dá para continuar da cópia válida anterior: %s." % describe.call(r["data"]), ["Continuar da cópia", "Começar de novo", "Voltar"], 0, "volta")
		SaveStore.Status.DAMAGED:
			menu.show_menu(title, "Este arquivo não pôde ser lido (%s) e não há cópia válida. Começar de novo guarda o arquivo danificado à parte, sem apagá-lo." % ", ".join(r["problems"]), ["Começar de novo", "Voltar"], 1, "volta")
		SaveStore.Status.FUTURE:
			menu.show_menu(title, "Este salvamento foi feito por uma versão mais nova do jogo e não pode ser aberto nesta (%s)." % ", ".join(r["problems"]), ["Começar de novo", "Voltar"], 1, "volta")


func _confirm_start_over(from_slot: bool = true) -> void:
	_confirm_from_slot = from_slot
	page = Page.CONFIRM
	menu.show_menu("Começar de novo no espaço %d?" % _slot, "O progresso salvo neste espaço será substituído pelo novo jogo.", ["Sim, começar de novo", "Não"], 1, "volta")


func _on_slot_action(index: int) -> void:
	var r: Dictionary = _reads[_slot]
	var status := int(r["status"])
	var can_continue := status == SaveStore.Status.OK or status == SaveStore.Status.RECOVERED
	var action := index if can_continue else index + 1
	match action:
		0:
			start.emit(_slot, r["data"])
		1:
			_confirm_start_over()
		_:
			_back()
