class_name TitleScreen
extends CanvasLayer
## The first screen: three save slots (design/kit/integracao-e-salvamento.md §7).
## An empty slot starts a new game; a saved one continues or starts over.
## A damaged file says so plainly, names the recovery used and is never
## deleted without the player choosing to start over.

## [param doc] is the save to continue, or empty for a new game.
signal start(slot: int, doc: Dictionary)

var store: SaveStore
## One line about a save document (room and play time), from the game.
var describe: Callable = func(_doc: Dictionary) -> String: return ""
var menu: MenuPanel
## Slot shown in the per-slot menu, or 0 on the slot list.
var _slot := 0
var _reads: Dictionary = {}
var _confirming := false
var _first_slot := 1


func _init(save_store: SaveStore, first_slot: int = 1) -> void:
	store = save_store
	_first_slot = first_slot


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	var back := ColorRect.new()
	back.color = Color("101218")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var name_label := Label.new()
	name_label.text = "A Lenda de Yggnus"
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", DialogueBox.COLOR_EDGE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 36)
	name_label.size = Vector2(640, 32)
	add_child(name_label)
	menu = MenuPanel.new()
	add_child(menu)
	menu.chosen.connect(_on_chosen)
	show_slots(_first_slot)


## The slot list, with [param highlight] (1–3) selected.
func show_slots(highlight: int = 1) -> void:
	_slot = 0
	_confirming = false
	var rows := PackedStringArray()
	for slot in range(1, SaveStore.SLOT_COUNT + 1):
		_reads[slot] = store.read(slot)
		rows.append("Espaço %d · %s" % [slot, _row_text(_reads[slot])])
	menu.show_menu("Escolha um espaço", "", rows, highlight - 1)


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


func _unhandled_input(event: InputEvent) -> void:
	if _slot != 0 and event.is_action_pressed("pause"):
		show_slots(_slot)
		get_viewport().set_input_as_handled()


func _on_chosen(index: int) -> void:
	if _slot == 0:
		_open_slot(index + 1)
	elif _confirming:
		if index == 0:
			start.emit(_slot, {})
		else:
			show_slots(_slot)
	else:
		_on_slot_action(index)


func _open_slot(slot: int) -> void:
	var r: Dictionary = _reads[slot]
	if int(r["status"]) == SaveStore.Status.EMPTY:
		start.emit(slot, {})
		return
	_slot = slot
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


func _on_slot_action(index: int) -> void:
	var r: Dictionary = _reads[_slot]
	var status := int(r["status"])
	var can_continue := status == SaveStore.Status.OK or status == SaveStore.Status.RECOVERED
	var action := index if can_continue else index + 1
	match action:
		0:
			start.emit(_slot, r["data"])
		1:
			_confirming = true
			menu.show_menu("Começar de novo no espaço %d?" % _slot, "O progresso salvo neste espaço será substituído pelo novo jogo.", ["Sim, começar de novo", "Não"], 1, "volta")
		_:
			show_slots(_slot)
