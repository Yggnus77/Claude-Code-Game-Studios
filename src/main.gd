extends Node2D
## Entry scene: loads a prototype room, places Yggnus, spawns the room's
## enemies, and wires progress ([GameState]), story scenes ([DialogueService]),
## interaction (chests, clues, checkpoints, NPCs), fragments and doors.
## Command-line user args (after `--`):
##   --room=<id>              open another prototype room;
##   --flags=<a>,<b>          start with these story flags set (tests, evidence);
##   --autowalk=<x>,<y>       hold that movement input (for recorded evidence runs);
##   --spawn=<enemy>@<col>,<row>  add an enemy on that tile;
##   --autoattack             press attack every 0.4 s (for recorded evidence runs);
##   --at=<col>,<row>         start on that tile, facing up (evidence runs);
##   --autointeract           press interact every 0.8 s (evidence runs);
##   --slot=<1-3>             play in that save slot: continue it, or start a
##                            new game there when it is empty (evidence runs).
## With no user args, the title screen opens first and the game saves to the
## chosen slot (design/kit/integracao-e-salvamento.md §7).

const PLAYER_SCENE := preload("res://src/scenes/player.tscn")
const DEFAULT_ROOM := "v00_oficina"
## Seconds between death and returning to the checkpoint.
const RESPAWN_DELAY := 1.2
## Fade out and fade in of a room transition (mecanicas §2).
const FADE_TIME := 0.18
## Door sides that slide the screen (others fade).
const SLIDE_DIRS := ["north", "south", "east", "west"]
## Reach of the interact action, in front of the feet.
const INTERACT_REACH := 14.0
const INTERACT_RADIUS := 14.0
## Kinds the interact action can use.
const INTERACTABLE := ["chest", "mystery_clue", "npc", "interact", "checkpoint", "refill"]
## Arrow hits get their own attack ids, far above the sword's.
const ARROW_ATTACK_BASE := 1000000
## Entity kinds a needle stops at (things standing on the floor).
const ARROW_STOPPERS := ["chest", "npc", "interact", "checkpoint", "anchor", "push_block", "bell"]
## How far back from where a needle stopped it may fall, looking for
## floor (it never lands on a gap or in a wall).
const NEEDLE_DROP_SEARCH := 64.0
## Playtest keys 1–4 spawn these enemies near the player.
## Triggers tried when an interactable's own scene has already played:
## the pump hands its reward once both parts are found (r03 → r04).
const TRIGGER_FOLLOW_UPS := {
	"iniciar_missao_bomba": ["concluir_missao_bomba"],
	"examinar_inscricao_sinos": ["pedir_dica_sinos"],
}
## What the player reads when an interactable has nothing new to play.
const FOLLOW_UP_NOTES := {
	"iniciar_missao_bomba": "A bomba ainda precisa das duas peças.",
	"examinar_inscricao_sinos": "A inscrição: círculo, fenda, ondas.",
}
## The merchant's trigger and scene (r05 opens the shop).
const SHOP_TRIGGER := "primeira_loja"
const SHOP_SCENE := "r05"
## Seen when the slice ends back in Exódia's workshop (scene t12).
const SLICE_END_FLAG := "seen.t12"

const SPAWN_KEYS := ["rastejo_tinta", "mariposa_papel", "soldado_corda", "guarda_contrapeso"]
## Enemy kinds that have an implementation, by inimigos.json id.
const ENEMY_SCRIPTS := {
	"rastejo_tinta": preload("res://src/enemies/rastejo.gd"),
	"mariposa_papel": preload("res://src/enemies/mariposa.gd"),
	"soldado_corda": preload("res://src/enemies/soldado.gd"),
	"guarda_contrapeso": preload("res://src/enemies/guarda.gd"),
}

## Plays the opening scene on a new game in the first room. Tests turn it off.
var play_intro := true
var config: GameConfig
var state: GameState
var dialogue: DialogueService
var dialogue_box: DialogueBox
var room: Room
var room_id := ""
var player: Player
var enemies: Array[Node] = []
var _autoattack := false
var _autoattack_timer := 0.0
var _autointeract := false
var _autoitem := false
var _autoitem_timer := 0.5
var _autointeract_timer := 0.5
## Door the player arrived on; doors fire again only after leaving it.
var _arrival_door := ""
var _locked_notice := ""
var _transitioning := false
var _fade: ColorRect
## Chest whose story scene is playing: its receipt is added when the scene ends.
## Receipt to add when the chest's scene ends: {"scene": id, "receipt": id}.
var _pending_chest: Dictionary = {}
## Flag to set when the counterweight scene ends: {"scene": id, "flag": id}.
var _pending_weight: Dictionary = {}
## Prologue rules (Etapa 4) and the running Yame Black invasion, if any.
var prologue: Prologue
var invasion: YameInvasion
## Merchant rules and menu (Etapa 5).
var shop: Shop
var shop_panel: ShopPanel
## Tool on the item button: "frasco" (flask, else bread), "gancho",
## "arco", "cargas" or "lamparina" (ferramentas.json "order").
var equipped := "frasco"
## Item-button tools (ferramentas.json).
var tools: ToolRules
## Tools owned at the last story refresh (a new one gets equipped).
var _owned_tools: Array[String] = [ToolRules.FLASK]
## How-to text of a tool just found, until a toast shows it.
var _new_tool_tip := ""
## Seconds before the bow, charges or lamp can be used again.
var _tool_cooldown := 0.0
var _arrow_ids := 0
## Counts room loads, so a needle drawn in one visit is not shot in the next.
var _visit := 0
## Bell puzzle of the current room, if it has one, and its bells.
var bell_puzzle: BellPuzzle
var bells: Array[Bell] = []
## Igris while his room is loaded and the fight is not won, else null.
var igris: Igris
## Bush and pot rules (exploracao.json).
var breakables: Breakables
## Key dungeons: map, compass, keys (masmorras.json).
var dungeons: Dungeons
## Random number in [0, 1) for drops; tests replace it to pick the outcome.
var drop_roll: Callable = func() -> float: return randf()
## Optional mysteries wired into this slice (m01, m02), keyed by id.
var mysteries: Dictionary = {}
## The relic slot rules (always rebuilt from the base numbers).
var relics: RelicLoadout
## Hint to show when a wrong-answer scene ends: {"scene": id, "text": hint}.
var _pending_hint: Dictionary = {}
## Flasks and bread at the start of the Igris attempt (restored on death).
var _attempt: Dictionary = {}
## A new game starts unarmed. Playtests and tests that skip the intro (or
## start in another room) get the sword and shield, unless this is true.
var start_unarmed := false
## Shows the title screen on a normal launch (no user args). Tests turn it off.
var show_title := true
## Save slot in use (1–3), or 0 when this run does not save (tests, and
## evidence runs without --slot).
var save_slot := 0
## Folder of the save slots and path of the settings file (tests use others).
var save_dir := "user://saves"
var settings_path := Settings.PATH
var saves: SaveStore
var settings: Settings
var title: TitleScreen
## Seconds played in this slot (counted while the game runs, not paused).
var playtime := 0.0
## Result of the last save write (OK when it worked).
var last_save_error: Error = OK
## Tile the player last entered the room on (door, respawn, marco): a load
## puts Yggnus back there.
var _entry_tile := Vector2i(-1, -1)
var _save_queued := false
## Playtest record of this session (Etapa 10), written next to the saves.
var playtest: PlaytestLog
## Folder of the playtest records ("" writes nothing).
var playtest_dir := "user://playtest"
var _session_ms := 0
var _playtest_file := ""
var _slice_was_done := false

@onready var hud: Hud = $Hud
@onready var pause_overlay: PauseOverlay = $PauseOverlay


func _ready() -> void:
	config = GameConfig.load_all()
	state = GameState.new()
	prologue = Prologue.new(config.encounter("yame_oficina"))
	if not start_unarmed and (not play_intro or _arg("--room=", DEFAULT_ROOM) != DEFAULT_ROOM or "--gear" in OS.get_cmdline_user_args()):
		# Same receipts as scene p05, so the scene never hands them out twice.
		state.apply([
			{"op": "grant_unique", "item_id": "espada_oficina", "quantity": 1, "receipt_id": "scene.p05.espada_oficina"},
			{"op": "grant_unique", "item_id": "escudo_bronze", "quantity": 1, "receipt_id": "scene.p05.escudo_bronze"},
		])
	# Every game starts with one empty flask (auditoria-e-decisoes.md item 2).
	state.apply([{"op": "grant_unique", "item_id": "frasco_01", "quantity": 1, "receipt_id": "new_game.frasco_01"}])
	breakables = Breakables.load_from()
	dungeons = Dungeons.load_from()
	tools = ToolRules.load_from()
	shop = Shop.new(config)
	mysteries = config.mystery_quests()
	relics = config.relic_loadout()
	state.relic_ids = relics.relics.keys()
	_session_ms = Time.get_ticks_msec()
	playtest = PlaytestLog.new(Time.get_datetime_string_from_system(false, true))
	saves = SaveStore.new(save_dir, SaveGame.new(config.room_ids, config.items.keys(), config.fragments.keys()).validate)
	settings = Settings.new(settings_path).load_file()
	# Saved key and button choices and the window mode.
	settings.apply()
	# Height on screen decides who is drawn in front (Yggnus, enemies, props).
	y_sort_enabled = true
	shop_panel = ShopPanel.new()
	add_child(shop_panel)
	_apply_state_args()
	dialogue_box = DialogueBox.new()
	add_child(dialogue_box)
	dialogue = DialogueService.new()
	add_child(dialogue)
	dialogue.setup(DialogueDB.load_from(), state, dialogue_box)
	dialogue.bark.connect(func(text: String) -> void: hud.toast(text, 3.0 + 1.5 * text.count("\n")))
	dialogue.scene_finished.connect(_on_scene_finished)
	pause_overlay.is_blocked = func() -> bool: return dialogue.is_open() or hud.is_inventory_open() or shop_panel.is_open() or _transitioning or title != null
	pause_overlay.on_quit = quit_game
	pause_overlay.on_open_logs = open_playtest_folder
	pause_overlay.pause_on_focus_loss = settings.pause_on_focus_loss
	pause_overlay.settings = settings
	pause_overlay.settings_screen_changed.connect(hud.refresh_hint)
	# The HUD was built before the saved controls were applied.
	hud.refresh_hint()
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.size = Vector2(640, 360)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	fade_layer.add_child(_fade)
	add_child(fade_layer)
	hud.dungeon_view = dungeon_map_view
	hud.key_view = dungeon_key_view
	hud.hint_state = func() -> Dictionary: return {"sword": player != null and player.has_sword, "tools": _owned_tools.size() > 1, "flask": not state.flasks().is_empty()}
	hud.bind_state(state)
	hud.inventory_extra = func() -> PackedStringArray: return _inventory_lines(false)
	hud.item_action = use_from_backpack
	hud.item_detail = func(id: String) -> String: return ("Efeito: " + _relic_effect_text(id)) if relics.relics.has(id) else ""
	hud.is_equipped = func(id: String) -> bool: return id == state.equipped_relic or (tools.item_of(equipped) == id and not id.is_empty()) or (equipped == ToolRules.FLASK and id.begins_with(GameState.FLASK_PREFIX))
	state.changed.connect(func() -> void: if room: room.queue_redraw())
	state.changed.connect(_refresh_story)
	state.changed.connect(_queue_save)
	state.changed.connect(_note_slice_end)
	load_room(_arg("--room=", DEFAULT_ROOM))
	_refresh_story()
	dialogue.player_busy = func() -> bool: return player.is_busy() or player.is_dead()
	_apply_playtest_args()
	if show_title and play_intro and OS.get_cmdline_user_args().is_empty():
		_show_title()
		return
	var slot := int(_arg("--slot=", "0"))
	if slot >= 1 and slot <= SaveStore.SLOT_COUNT:
		var r := saves.read(slot)
		var status := int(r["status"])
		if status == SaveStore.Status.DAMAGED or status == SaveStore.Status.FUTURE:
			# Only the title screen may start over a slot that cannot be read.
			push_warning("--slot=%d cannot be read (%s); this run does not save." % [slot, r["problems"]])
			_begin_new_game.call_deferred()
		else:
			_on_title_start.call_deferred(slot, r["data"])
	else:
		_begin_new_game.call_deferred()


func _show_title() -> void:
	get_tree().paused = true
	title = TitleScreen.new(saves, settings.last_slot)
	title.describe = describe_save
	title.start.connect(_on_title_start)
	title.settings = settings
	title.settings_changed.connect(hud.refresh_hint)
	add_child(title)


## The player picked [param slot]: continue [param doc], or start a new
## game there when it is empty.
func _on_title_start(slot: int, doc: Dictionary) -> void:
	if title:
		title.queue_free()
		title = null
	get_tree().paused = false
	settings.last_slot = slot
	settings.save_file()
	var recovered := int(saves.read(slot)["status"]) == SaveStore.Status.RECOVERED
	save_slot = slot
	# The playtest clock starts when play starts, not on the title screen.
	_session_ms = Time.get_ticks_msec()
	pause_overlay.on_title = quit_to_title
	if doc.is_empty():
		saves.start_over(slot)
		_begin_new_game()
		return
	continue_from(doc)
	if recovered:
		hud.toast("O último salvamento ficou incompleto ou danificado. O jogo voltou da cópia válida anterior.", 5.0)


func _begin_new_game() -> void:
	if play_intro and room_id == DEFAULT_ROOM:
		dialogue.request("nova_partida")
	_on_room_entered()
	_queue_save()


## Loads the progress in [param doc] (a save that passed validation) and
## puts Yggnus on its safe entry tile.
func continue_from(doc: Dictionary) -> void:
	var r := SaveGame.restore(doc)
	var loaded: GameState = r["state"]
	_owned_tools = tools.owned(loaded)
	var saved_tool := str(r["tool"])
	equipped = saved_tool if tools.owns(saved_tool, loaded) else ToolRules.FLASK
	playtime = float(r["playtime"])
	_slice_was_done = loaded.has_flag(SLICE_END_FLAG)
	state.replace_with(loaded)
	player.health.maximum = state.life_max()
	var entry: Vector2i = r["entry"]
	var saved_room := RoomData.load_room(str(r["room"]))
	if saved_room != null and not saved_room.is_walkable(entry):
		entry = saved_room.entry_default  # the room was redrawn since this save
	load_room(str(r["room"]), entry)
	player.health.set_current(int(r["life"]))
	if not _attempt.is_empty():
		# The attempt began on load, before the saved life was put back.
		_attempt["life"] = player.health.current
	_refresh_story()
	_on_room_entered()


## "Praça de Versalhes · 12 min" for the title screen.
func describe_save(doc: Dictionary) -> String:
	var data := RoomData.load_room(str(doc.get("current_room", "")))
	var minutes := floori(float(doc.get("playtime_seconds", 0)) / 60.0)
	var time := ("%d min" % minutes) if minutes < 60 else ("%d h %02d min" % [floori(minutes / 60.0), minutes % 60])
	return "%s · %s" % [data.display_name if data else "?", time]


func _process(delta: float) -> void:
	if save_slot > 0:
		playtime += delta


## Saves at the end of this frame, once, after every change made in it
## (inventory transactions finish first; integracao-e-salvamento.md §7).
func _queue_save() -> void:
	if save_slot <= 0 or _save_queued:
		return
	_save_queued = true
	save_now.call_deferred()


## Writes the slot now. During the Igris attempt the save is the attempt's
## start: flasks, bread and life as they were, on the chamber's entry
## (mecanicas-e-dificuldade.md §9).
func save_now() -> Error:
	_save_queued = false
	if save_slot <= 0 or player == null or player.is_dead() or room_id.is_empty():
		return ERR_UNAVAILABLE
	var snap := state
	var life := player.health.current
	if not _attempt.is_empty():
		snap = GameState.from_dict(state.to_dict())
		snap.apply([{"op": "restore_supplies", "full_flasks": _attempt["full_flasks"], "bread": _attempt["bread"]}])
		life = int(_attempt.get("life", life))
	var doc := SaveGame.capture(snap, {"room": room_id, "entry": _entry_tile, "life": life, "tool": equipped, "playtime": int(playtime), "slot": save_slot})
	last_save_error = saves.write(save_slot, doc)
	if last_save_error != OK:
		hud.toast("Não foi possível salvar o jogo (erro %d)." % last_save_error, 4.0)
	else:
		hud.flash_saved()
	return last_save_error


## Records the end of the slice once, when it happens in this session (a
## loaded save that had already finished does not count).
func _note_slice_end() -> void:
	var done := state.has_flag(SLICE_END_FLAG)
	if done and not _slice_was_done:
		playtest.finish(session_time())
	_slice_was_done = done


## Seconds since the game started (the playtest clock: real time, as the
## observer measures it).
func session_time() -> float:
	return (Time.get_ticks_msec() - _session_ms) / 1000.0


## What dealt the last hit before a death (the attacker names itself when
## it hits), or "causa não vista".
func death_cause() -> String:
	return player.last_hit_by if not player.last_hit_by.is_empty() else "causa não vista"


## Writes the playtest record (summary .txt and data .json) for this
## session. Only a game played in a slot writes, and only with
## Settings.playtest_log on.
func write_playtest() -> void:
	if save_slot <= 0 or playtest_dir.is_empty() or not settings.playtest_log:
		return
	if DirAccess.make_dir_recursive_absolute(playtest_dir) != OK:
		return
	if _playtest_file.is_empty():
		_playtest_file = playtest_dir.path_join("sessao-%s-espaco%d" % [playtest.started_at.replace(":", "-").replace(" ", "_"), save_slot])
	var t := session_time()
	for pair in [[".txt", playtest.summary(t)], [".json", JSON.stringify(playtest.to_dict(), "\t")]]:
		var f := FileAccess.open(_playtest_file + pair[0], FileAccess.WRITE)
		if f:
			f.store_string(pair[1])
			f.close()


## Pause menu: opens the folder with the playtest records.
func open_playtest_folder() -> void:
	write_playtest()
	DirAccess.make_dir_recursive_absolute(playtest_dir)
	OS.shell_open(ProjectSettings.globalize_path(playtest_dir))


## Pause menu: save, then show the title screen again.
func quit_to_title() -> void:
	if not _saved_before_leaving():
		return
	get_tree().paused = false
	get_tree().reload_current_scene()


## Pause menu: save, then close the game.
func quit_game() -> void:
	if not _saved_before_leaving():
		return
	get_tree().quit()


## Saves before leaving. A failed write keeps the game open on the pause
## menu with the error, so progress is never dropped silently. (Nothing to
## save, or Yggnus mid-respawn, leaves with the last save as it is.)
func _saved_before_leaving() -> bool:
	if not _attempt.is_empty():
		playtest.igris_end(session_time(), "saiu")
	write_playtest()
	var err := save_now()
	if err == OK or err == ERR_UNAVAILABLE:
		return true
	pause_overlay.set_paused(true, "Não foi possível salvar (erro %d). Tente de novo." % err)
	return false


func _notification(what: int) -> void:
	# Closing the window also saves (the last safe entry, as always).
	if what == NOTIFICATION_WM_CLOSE_REQUEST and save_slot > 0:
		if not _attempt.is_empty():
			playtest.igris_end(session_time(), "saiu")
		write_playtest()
		save_now()


## Playtest start state: --items= and --flags= (see the header).
func _apply_state_args() -> void:
	var give := _arg("--items=", "")
	if not give.is_empty():
		for item in give.split(","):
			state.apply([{"op": "grant_unique", "item_id": item, "quantity": 1, "receipt_id": "playtest.%s" % item}])
	var preset := _arg("--flags=", "")
	if not preset.is_empty():
		var effects := []
		for f in preset.split(","):
			effects.append({"op": "set_flag", "flag": f, "value": true})
		state.apply(effects)


## Evidence-run helpers: --autowalk, --spawn, --auto*, --at, --face.
func _apply_playtest_args() -> void:
	var walk := _arg("--autowalk=", "")
	if not walk.is_empty() and player:
		var parts := walk.split(",")
		player.read_input = false
		player.input_override = Vector2(float(parts[0]), float(parts[1]))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--spawn="):
			var spec := arg.trim_prefix("--spawn=").split("@")
			var tile := spec[1].split(",")
			spawn_enemy(spec[0], Vector2i(int(tile[0]), int(tile[1])))
	_autoattack = "--autoattack" in OS.get_cmdline_user_args()
	_autointeract = "--autointeract" in OS.get_cmdline_user_args()
	_autoitem = "--autoitem" in OS.get_cmdline_user_args()
	var face := _arg("--face=", "")
	var at := _arg("--at=", "")
	if not at.is_empty():
		var xy := at.split(",")
		player.respawn_at(room.data.tile_center(Vector2i(int(xy[0]), int(xy[1]))))
		player.motor.facing = Vector2.UP
	if not face.is_empty():
		var f := face.split(",")
		player.motor.facing = Vector2(float(f[0]), float(f[1]))


## Builds room [param id] with Yggnus on [param entry] (or its default
## entry), then spawns the room's enemies. [param restore_life] is false for
## doors and the room reset, so walking out and back in never heals.
func load_room(id: String, entry: Vector2i = Vector2i(-1, -1), restore_life: bool = true) -> void:
	var data := RoomData.load_room(id)
	if data == null:
		return
	room_id = id
	_visit += 1
	_refresh_story()  # the objective line depends on the room too
	if room == null:
		room = Room.new()
		room.state = state
		room.door_open = is_door_open
		room.breakable_rules = breakables
		room.dark_ambient = tools.dark_ambient
		room.torch_light_radius = tools.num("lamparina", "torch_light_radius", 104.0)
		room.breakable_broken.connect(_on_breakable_broken)
		add_child(room)
		move_child(room, 0)
	room.build(data)
	if player == null:
		player = PLAYER_SCENE.instantiate()
		player.configure(config)
		add_child(player)
		player.died.connect(_on_player_died)
		player.hit_taken.connect(_on_player_hit)
		player.heal_source = _heal_source
		player.heal_commit = _heal_commit
		player.hook_probe = _hook_probe
		player.hook_hit.connect(_on_hook_hit)
		player.sword_landed.connect(func() -> void: playtest.first(session_time(), "espada"))
		player.spun.connect(func() -> void: playtest.first(session_time(), "giro"))
		player.item_pressed.connect(use_item)
		if hud:
			hud.bind(player.health)
	var tile := entry if entry.x >= 0 else data.entry_default
	player.respawn_at(data.tile_center(tile), restore_life)
	_entry_tile = tile
	player.set_camera_limits(data.pixel_size(), room.top_extent())
	_update_glow()
	_arrival_door = _door_at(player.global_position)
	clear_enemies()
	room.raised = {}
	var cleared := state.has_flag(str(config.tower.get("room_clear_flags", {}).get(id, "-")))
	for entity in data.entities:
		var kind := str(entity.get("kind", ""))
		if ENEMY_SCRIPTS.has(kind) and not cleared:
			var t: Array = entity.get("tile", [0, 0])
			var enemy := spawn_enemy(kind, Vector2i(int(t[0]), int(t[1])))
			if enemy:
				enemy.set_meta("entity", entity)
	if hud:
		hud.set_area(id, data.display_name)
		hud.refresh_status(state)  # the key line depends on the room
	_build_bells()
	_build_igris()
	_sync_invasion()
	_queue_save()


## Starts or removes the Yame Black invasion to match the story state.
func _sync_invasion() -> void:
	var wanted := room_id == Prologue.WORKSHOP and prologue.invasion_active(state)
	if wanted and prologue.all_bindings_cut(state):
		# Cut before a death or a reload, scene not seen yet: finish it now.
		wanted = false
		dialogue.request.call_deferred("tres_amarras_cortadas")
	if invasion and is_instance_valid(invasion) and (not wanted or invasion.room_data != room.data):
		invasion.queue_free()
		invasion = null
	if wanted and invasion == null:
		invasion = YameInvasion.new()
		invasion.setup(config.encounter("yame_oficina"), state, prologue, room.data, player)
		invasion.thrown.connect(func(_paper: Node2D) -> void: dialogue.request(str(invasion.def.get("hint_bark", ""))))
		invasion.binding_cut.connect(_on_binding_cut)
		invasion.sword_deflected.connect(_on_yame_deflected)
		invasion.cleared.connect(_on_invasion_cleared)
		add_child(invasion)
		move_child(invasion, 1)


## The sword reached Yame: say what to hit instead.
func _on_yame_deflected() -> void:
	hud.toast("A espada não fere Yame Black. Corte as amarras que prendem a porta!", 3.0)
	playtest.refuse(session_time(), "espada em Yame Black")


func _on_binding_cut(_binding_id: String, left: int) -> void:
	hud.toast("Amarra cortada!" if left > 0 else "A última amarra se rompeu!")


func _on_invasion_cleared() -> void:
	invasion = null
	dialogue.request(str(config.encounter("yame_oficina").get("success_event", "tres_amarras_cortadas")))


func _on_player_hit(outcome: HitResolver.Outcome) -> void:
	if outcome == HitResolver.Outcome.HIT and not player.is_dead():
		playtest.hit(session_time(), death_cause())
	if outcome == HitResolver.Outcome.BLOCKED or outcome == HitResolver.Outcome.PERFECT_BLOCK:
		playtest.first(session_time(), "defesa")
	if outcome == HitResolver.Outcome.HIT and invasion != null:
		dialogue.request(str(invasion.def.get("hint_bark", "")))


## Raises the story trigger of the room just entered, if any.
func _on_room_entered() -> void:
	playtest.room(session_time(), room.data.display_name)
	write_playtest()
	state.apply([{"op": "set_flag", "flag": "visited.%s" % room_id, "value": true}])
	for q: MysteryQuest in mysteries.values():
		if str(q.wiring.get("start_on_enter", "")) == room_id and q.step(state) == MysteryQuest.Step.START:
			_request_scene(q.scene("start"))
	var trigger := prologue.trigger_on_enter(state, room_id)
	if trigger.is_empty():
		trigger = str(config.tower.get("on_enter", {}).get(room_id, ""))
	if not trigger.is_empty():
		dialogue.request(trigger)


## Follows the story state: weapons in hand and the objective line.
func _refresh_story() -> void:
	if player:
		player.has_sword = state.item_count("espada_oficina") > 0
		player.has_shield = state.item_count("escudo_bronze") > 0
		player.apply_relic_params(relics.params(state.equipped_relic))
	var found := tools.new_tools(_owned_tools, state)
	_owned_tools = tools.owned(state)
	if not found.is_empty():
		# The newest tool goes on the button; its how-to is told once.
		equipped = found[-1]
		_new_tool_tip = "%s: %s" % [tools.text(equipped, "equipped"), _tool_how(equipped)]
		_flush_tool_tip.call_deferred()
		_update_glow()
	if not tools.owns(equipped, state):
		equipped = ToolRules.FLASK
	if hud:
		hud.set_objective(prologue.objective(state, room_id))
		hud.set_item(tools.label(equipped, state), _owned_tools.size() > 1, equipped, tools.item_of(equipped))
		hud.refresh_hint()


## Adds enemy [param kind] on [param tile]. Returns it, or null if unknown.
func spawn_enemy(kind: String, tile: Vector2i) -> Node:
	if not ENEMY_SCRIPTS.has(kind) or room == null:
		return null
	var enemy: Node2D = ENEMY_SCRIPTS[kind].new()
	enemy.setup(config.enemy(kind), player)
	enemy.position = room.data.tile_center(tile)
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)
	enemies.append(enemy)
	return enemy


func clear_enemies() -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	for paper in get_tree().get_nodes_in_group("projectiles"):
		paper.queue_free()
	for coin in get_tree().get_nodes_in_group("pickups"):
		coin.queue_free()
	if player and player.hook:
		player.hook.reset()


## Common enemies drop their Bronze; a designated one (an entity with a
## world reward trigger, e.g. the pump's scrap creature) also hands its
## unique reward the first time only.
func _on_enemy_defeated(enemy: Node) -> void:
	var entity: Dictionary = enemy.get_meta("entity", {})
	var reward := str(entity.get("trigger_id", ""))
	if not reward.is_empty() and reward != "<null>" and config.rewards.has(reward):
		var receipt := config.reward_receipt(reward)
		if not state.has_receipt(receipt) and state.apply(config.reward_effects(reward)):
			hud.toast("Recebeu %s" % config.item_name(str(config.rewards[reward].get("item", ""))))
	_check_room_clear()
	var amount := Pickup.bronze_amount(str(enemy.params.get("repeatable_drop", "")))
	if amount > 0:
		var coin := Pickup.new()
		coin.amount = amount
		coin.target = player
		coin.position = enemy.global_position
		coin.collected.connect(func(c: Pickup) -> void: state.apply([{"op": "add_bronze", "amount": c.amount}]))
		add_child.call_deferred(coin)


## A bush or pot broke: roll its drop (exploracao.json) and leave it there.
func _on_breakable_broken(b: Breakable) -> void:
	_drop_from(b.kind, b.global_position, drop_roll.call())


## Spawns what [param kind] drops for [param roll] in [0, 1) at [param at].
## Returns the drop id ("none" when nothing). Nothing drops in a boss arena.
func _drop_from(kind: String, at: Vector2, roll: float) -> String:
	if igris != null:
		return "none"
	var drop := breakables.drop_for(kind, roll)
	var life := Breakables.life_amount(drop)
	var coin_amount := Pickup.bronze_amount(drop)
	if life <= 0 and coin_amount <= 0:
		# Once the bow is found, an empty pot or bush may hold needles
		# (ferramentas.json arco.drop_chance), on a second roll.
		var chance := float((tools.def_of("arco").get("drop_chance", {}) as Dictionary).get(kind, 0.0))
		if chance > 0.0 and tools.owns("arco", state) and float(drop_roll.call()) < chance:
			var n := int(tools.num("arco", "drop_amount", 3))
			drop_needles(at, n, breakables.life_lifetime)
			return "agulha_%d" % n
		return "none"
	var p := Pickup.new()
	p.target = player
	p.position = at
	if life > 0:
		p.kind = Pickup.KIND_LIFE
		p.amount = life
		p.lifetime = breakables.life_lifetime
		p.collected.connect(func(c: Pickup) -> void: player.health.heal(c.amount))
	else:
		p.amount = coin_amount
		p.collected.connect(func(c: Pickup) -> void: state.apply([{"op": "add_bronze", "amount": c.amount}]))
	# Added now (not deferred), so a door taken in the same frame clears it.
	add_child(p)
	return drop


## Sets the room's clear flag (torre-akurame.json "room_clear_flags") once
## every enemy of the room is defeated; the room stays clear afterwards.
func _check_room_clear() -> void:
	var flag := str(config.tower.get("room_clear_flags", {}).get(room_id, ""))
	if flag.is_empty() or state.has_flag(flag):
		return
	for e in enemies:
		if is_instance_valid(e) and not e.is_defeated:
			return
	state.apply([{"op": "set_flag", "flag": flag, "value": true}])
	hud.toast("Ouviu-se a trava da porta se abrir.")


## Item button: throws the hook, shoots, sets a charge, lights the lamp,
## or drinks/eats, by what is equipped.
func use_item() -> void:
	match equipped:
		"gancho":
			if tools.owns("gancho", state):
				player.fire_hook()
				return
		"arco":
			shoot_arrow()
			return
		"cargas":
			place_bomb()
			return
		"lamparina":
			use_lamp()
			return
	if player.health.current >= player.health.maximum:
		playtest.refuse(session_time(), "curar com a vida cheia")
		return
	if not player.request_heal() and _heal_source() == 0:
		hud.toast("Nenhum frasco cheio nem pão.")
		playtest.refuse(session_time(), "curar sem frasco cheio nem pão")


## Quick swap: the next tool the player has (ferramentas.json "order").
func quick_swap() -> void:
	if _owned_tools.size() <= 1:
		return
	equipped = tools.next_tool(equipped, state)
	_refresh_story()
	_queue_save()


## A tool's how-to text with the player's own keys.
func _tool_how(tool: String) -> String:
	return tools.text(tool, "how").replace("{item}", DialogueBox._key("item")).replace("{swap}", DialogueBox._key("quick_swap"))


## Shows the how-to of a tool just found, unless a chest's toast already
## carried it.
func _flush_tool_tip() -> void:
	if not _new_tool_tip.is_empty() and hud:
		hud.toast(_new_tool_tip, 4.5)
	_new_tool_tip = ""


## Hands over (and forgets) the how-to of a tool just found ("" if none).
func _take_tool_tip() -> String:
	var tip := _new_tool_tip
	_new_tool_tip = ""
	return tip


## The light around Yggnus: wider in a dark room once he has the lamp.
func _update_glow() -> void:
	if player == null or room == null:
		return
	if room.is_dark() and tools.owns("lamparina", state):
		player.set_glow(tools.num("lamparina", "dark_glow_radius", 120.0), tools.num("lamparina", "dark_glow_energy", 0.95))
	elif room.is_painted() and not room.is_dark():
		player.set_glow(Player.GLOW_RADIUS, 0.0)  # the picture has its own light
	else:
		player.set_glow(Player.GLOW_RADIUS, Player.GLOW_ENERGY)


## Whether a tool can be used now; tells the player why not. Returns ""
## when it can, else "busy" or "empty".
func _tool_ready(tool: String) -> String:
	if _tool_cooldown > 0.0 or player.is_dead() or player.is_busy():
		return "busy"
	if tools.ammo_count(tool, state) == 0:
		hud.toast(tools.text(tool, "empty"), 3.0)
		playtest.refuse(session_time(), "%s sem munição" % tools.text(tool, "name").to_lower())
		return "empty"
	if not player.ready_tool(tools.num(tool, "startup", 0.0)):
		return "busy"
	return ""


## Arco de Fio: spends a needle and shoots it where Yggnus faces after the
## draw time (ferramentas.md §3). Returns "shot", "busy" or "empty".
func shoot_arrow() -> String:
	var why := _tool_ready("arco")
	if not why.is_empty():
		return why
	if not state.apply([{"op": "use_item", "item_id": tools.ammo_of("arco")}]):
		return "empty"
	var startup := tools.num("arco", "startup", 0.18)
	_tool_cooldown = startup + tools.num("arco", "cooldown", 0.3)
	playtest.first(session_time(), "arco")
	_release_arrow(_visit, player.motor.facing, startup)
	return "shot"


## Lets the needle go after the draw time [param startup], unless the room
## changed (visit [param visit] is over) or Yggnus fell meanwhile.
func _release_arrow(visit: int, dir: Vector2, startup: float) -> void:
	if startup > 0.0:
		await get_tree().create_timer(startup, false).timeout
	if visit != _visit or not is_instance_valid(player) or player.is_dead():
		return  # the needle is lost
	# Yggnus is busy through the draw (Player.ready_tool), so nothing else
	# (sword, dodge, hook) can start before the needle leaves.
	spawn_arrow(player.global_position + dir.normalized() * 6.0, dir)


## Puts a flying needle at [param from] going [param dir].
func spawn_arrow(from: Vector2, dir: Vector2) -> Arrow:
	var a := Arrow.new()
	a.direction = dir
	a.speed = tools.num("arco", "speed", 260.0)
	a.max_range = tools.num("arco", "range", 224.0)
	a.probe = _arrow_probe
	a.position = from
	a.stopped.connect(_on_arrow_stopped.bind(dir.normalized()))
	add_child(a)
	return a


## What a needle's tip touches at [param pos]: an enemy, a plate, a pot or
## bush ("solid"), a wall, or {}.
func _arrow_probe(pos: Vector2) -> Dictionary:
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_defeated and enemy.global_position.distance_to(pos) <= enemy.body_radius():
			return {"type": "enemy", "node": enemy}
	var cell := Vector2i((pos / room.data.tile_size).floor())
	for e: Dictionary in room.data.entities:
		if str(e.get("kind", "")) != "plate":
			continue
		var t := Vector2i(int(e["tile"][0]), int(e["tile"][1]))
		# Once at the plate's row, a near miss by a column still counts.
		if cell.y <= t.y and absf(pos.x - room.data.tile_center(t).x) <= tools.num("arco", "plate_half_width", 16.0):
			return {"type": "plate", "entity": e}
	for e: Dictionary in room.data.entities:
		if ARROW_STOPPERS.has(str(e.get("kind", ""))) and Vector2i(int(e["tile"][0]), int(e["tile"][1])) == cell:
			return {"type": "solid"}
	for b in get_tree().get_nodes_in_group("breakables"):
		if b is Breakable and not (b as Breakable).is_broken and b.global_position.distance_to(pos) <= (b as Breakable).body_radius():
			return {"type": "solid"}
	if room.data.cell(cell) == RoomData.WALL:
		return {"type": "wall"}
	return {}


func _on_arrow_stopped(hit: Dictionary, at: Vector2, dir: Vector2) -> void:
	match str(hit.get("type", "")):
		"enemy":
			var enemy: Node = hit["node"]
			if enemy is EnemyBase:
				_arrow_ids += 1
				enemy.receive_sword_hit(int(tools.num("arco", "damage", 2)), ARROW_ATTACK_BASE + _arrow_ids, at - dir * 8.0)
			else:
				# Igris: the needle glances off his brass.
				Fx.hit_sparks(self, at, at - dir * 8.0, true)
		"plate":
			var flag := str((hit["entity"] as Dictionary).get("sets_flag", ""))
			Fx.hit_sparks(self, at, at - dir * 8.0, true)
			if not flag.is_empty() and not state.has_flag(flag):
				state.apply([{"op": "set_flag", "flag": flag, "value": true}])
				hud.toast("A placa soou. Uma passagem se abriu.", 3.0)
				playtest.first(session_time(), "placa")
		"solid":
			Fx.hit_sparks(self, at, at - dir * 8.0, true)
		"wall", "range":
			# A needle that missed falls and can be picked up again, on the
			# nearest floor back along its path (never on a gap).
			var back := 4.0
			while back <= NEEDLE_DROP_SEARCH:
				var spot := at - dir * back
				if room.data.is_walkable(Vector2i((spot / room.data.tile_size).floor())):
					drop_needles(spot, 1, tools.num("arco", "dropped_lifetime", 10.0))
					break
				back += 4.0


## Leaves [param amount] needles on the ground at [param at].
func drop_needles(at: Vector2, amount: int, lifetime: float) -> Pickup:
	var p := Pickup.new()
	p.kind = Pickup.KIND_NEEDLE
	p.amount = amount
	p.lifetime = lifetime
	p.target = player
	p.position = at
	# A full quiver leaves the needles on the ground.
	p.can_collect = func() -> bool: return state.item_count(tools.ammo_of("arco")) < tools.ammo_cap("arco")
	p.collected.connect(func(c: Pickup) -> void:
		var item := tools.ammo_of("arco")
		var room_left := tools.ammo_cap("arco") - state.item_count(item)
		if room_left > 0:
			state.apply([{"op": "add_item", "item_id": item, "quantity": mini(c.amount, room_left), "stack_limit": tools.ammo_cap("arco")}]))
	add_child(p)
	return p


## Cargas de Bronze: sets a charge a step ahead (at the feet when that is
## not floor). Returns "placed", "busy", "full" or "empty".
func place_bomb() -> String:
	var why := _tool_ready("cargas")
	if not why.is_empty():
		return why
	if active_bombs().size() >= int(tools.num("cargas", "max_active", 2)):
		return "full"
	if not state.apply([{"op": "use_item", "item_id": tools.ammo_of("cargas")}]):
		return "empty"
	_tool_cooldown = tools.num("cargas", "cooldown", 0.3)
	var at := player.global_position + player.motor.facing.normalized() * tools.num("cargas", "place_distance", 14.0)
	if not room.data.is_walkable(Vector2i((at / room.data.tile_size).floor())):
		at = player.global_position
	spawn_bomb(at)
	playtest.first(session_time(), "carga")
	return "placed"


## Puts a lit charge at [param at].
func spawn_bomb(at: Vector2) -> Bomb:
	var b := Bomb.new()
	b.fuse = tools.num("cargas", "fuse", 1.6)
	b.radius = tools.num("cargas", "radius", 28.0)
	b.position = at
	b.exploded.connect(_on_bomb_exploded)
	add_child(b)
	return b


## Charges burning now.
func active_bombs() -> Array[Bomb]:
	var out: Array[Bomb] = []
	for n in get_tree().get_nodes_in_group("projectiles"):
		if n is Bomb and not (n as Bomb).done and not n.is_queued_for_deletion():
			out.append(n)
	return out


## What a blast reaches: enemies (no shield stops it), pots and bushes,
## other charges, Yggnus, and cracked walls (ferramentas.md §3).
func _on_bomb_exploded(bomb: Bomb) -> void:
	var at := bomb.global_position
	var r := bomb.radius
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is EnemyBase and not enemy.is_defeated and enemy.global_position.distance_to(at) <= r + enemy.body_radius():
			(enemy as EnemyBase).receive_blast(int(tools.num("cargas", "damage", 3)), at)
	for b in get_tree().get_nodes_in_group("breakables"):
		if b is Breakable and not (b as Breakable).is_broken and b.global_position.distance_to(at) <= r + (b as Breakable).body_radius():
			(b as Breakable).break_open(at)
	for other in active_bombs():
		if other != bomb and other.global_position.distance_to(at) <= r:
			other.detonate.call_deferred()
	if not player.is_dead() and player.global_position.distance_to(at) <= r + Player.FEET_RADIUS:
		# It hurts, but never takes the last point of life (ferramentas.md §3).
		var hurt := mini(int(tools.num("cargas", "self_damage", 1)), player.health.current - 1)
		if hurt > 0:
			player.receive_hit(hurt, at, false, true, "a própria Carga de Bronze")
	for door: Dictionary in room.data.doors:
		if not Room.is_cracked(door) or is_door_open(door):
			continue
		if tools.blast_reaches_wall(at, room.data.tile_center(room.door_frame_tile(door)), r):
			state.apply([{"op": "set_flag", "flag": str(door.get("gate", "")), "value": true}])
			hud.toast("A parede rachada desmoronou!", 3.0)
			playtest.first(session_time(), "parede_rachada")


## Lamparina: lights the torch in front of Yggnus. When every torch of its
## puzzle burns, the puzzle's flag is set for good. Returns "lit",
## "solved", "nothing" or "busy".
func use_lamp() -> String:
	var why := _tool_ready("lamparina")
	if not why.is_empty():
		return why
	_tool_cooldown = tools.num("lamparina", "cooldown", 0.35)
	var flame := player.global_position + player.motor.facing.normalized() * tools.num("lamparina", "reach", 18.0)
	Fx.flame_puff(self, flame)
	for torch in room.torches:
		if torch.lit or torch.position.distance_to(flame) > tools.num("lamparina", "torch_radius", 20.0):
			continue
		torch.set_lit(true)
		playtest.first(session_time(), "lamparina")
		var flag := torch.puzzle_flag()
		if flag.is_empty() or state.has_flag(flag):
			hud.toast("A tocha acendeu.")
			return "lit"
		for other in room.torches:
			if other.puzzle_flag() == flag and not other.lit:
				hud.toast("A tocha acendeu. Falta outra.")
				return "lit"
		state.apply([{"op": "set_flag", "flag": flag, "value": true}])
		hud.toast("As tochas ardem juntas. A porta selada se abriu.", 3.5)
		return "solved"
	return "nothing"


## What the hook's tip touches at [param pos].
func _hook_probe(pos: Vector2) -> Dictionary:
	var tower_hook: Dictionary = config.tower.get("hook", {})
	var anchor_r := float(tower_hook.get("anchor_radius", 8))
	for e in room.data.entities:
		var kind := str(e.get("kind", ""))
		if kind != "anchor" and kind != "push_block":
			continue
		var t := Vector2i(int(e["tile"][0]), int(e["tile"][1]))
		var c := room.data.tile_center(t)
		if kind == "anchor" and c.distance_to(player.global_position) <= anchor_r:
			continue  # the ring Yggnus stands on is not a target
		if c.distance_to(pos) <= anchor_r:
			return {"type": "anchor" if kind == "anchor" else "weight", "id": str(e["id"]), "tile": t}
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_defeated and enemy.global_position.distance_to(pos) <= enemy.body_radius():
			return {"type": "enemy", "node": enemy}
	if room.data.cell(Vector2i((pos / room.data.tile_size).floor())) == RoomData.WALL:
		return {"type": "wall"}
	return {}


func _on_hook_hit(hit: Dictionary) -> void:
	var tower_hook: Dictionary = config.tower.get("hook", {})
	match str(hit.get("type", "")):
		"anchor":
			var dest := room.data.grapple_destination(hit["tile"], player.global_position, float(tower_hook.get("start_radius", 32)), func(item: String) -> bool: return state.item_count(item) > 0)
			if dest.x < 0 and _is_free_anchor(str(hit.get("id", ""))) and room.data.is_walkable(hit["tile"]):
				# Igris's arena: the ring itself is a safe spot to pull to.
				dest = hit["tile"]
			if dest.x < 0:
				hud.toast("Daqui o aro não leva a um lugar seguro.")
				playtest.refuse(session_time(), "gancho num aro sem lugar seguro")
				return
			dialogue.request(str(tower_hook.get("valid_hook_bark", "")))
			player.start_pull(room.data.tile_center(dest))
			playtest.first(session_time(), "gancho")
		"enemy":
			var enemy: Node = hit["node"]
			if enemy.has_method("hook_muffler"):
				if enemy.hook_muffler():
					# The bark (t09) speaks first; the plain hint only when it is
					# on cooldown, so one never hides the other.
					if not dialogue.request(str(config.tower.get("igris", {}).get("muffler_bark", ""))):
						hud.toast("Abafador solto! Agora os sinos, na ordem em que acenderem.")
			elif enemy.has_method("expose"):
				# The guard's own data (inimigos.json hook_opening) sets how long.
				enemy.expose()
				hud.toast("O escudo do guarda ficou aberto!")
		"weight":
			var w: Dictionary = config.tower.get("weight", {})
			if str(hit["id"]) == str(w.get("block", "")) and not state.has_flag(str(w.get("solved_flag", ""))):
				room.raised[hit["id"]] = true
				room.queue_redraw()
				hud.toast("O peso subiu. Agora, a trava!")


## Creates the bells of the current room: the gallery puzzle
## (torre-akurame.json "bells") or the bells of Igris's chamber.
func _build_bells() -> void:
	for b in bells:
		if is_instance_valid(b):
			b.queue_free()
	bells.clear()
	bell_puzzle = null
	var def: Dictionary = config.tower.get("bells", {})
	var in_igris := str(config.tower.get("igris", {}).get("room", "")) == room_id
	if str(def.get("room", "")) != room_id and not in_igris:
		return
	if not in_igris:
		bell_puzzle = BellPuzzle.new(def.get("order", []), state.has_flag(str(def.get("solved_flag", ""))))
	for e in room.data.entities:
		if str(e.get("kind", "")) != "bell":
			continue
		var b := Bell.new()
		b.bell_id = str(e["id"])
		b.symbol = str(def.get("symbols", {}).get(b.bell_id, ""))
		b.lit = bell_puzzle != null and bell_puzzle.solved
		b.position = room.data.tile_center(Vector2i(int(e["tile"][0]), int(e["tile"][1])))
		b.painted = bool(e.get("painted", false)) and room.is_painted()
		if b.painted and e.get("glow_at") is Array:
			b.glow_offset = room.data.tile_center(Vector2i(int(e["glow_at"][0]), int(e["glow_at"][1]))) - b.position
		b.rung.connect(_on_igris_bell if in_igris else _on_bell_rung)
		add_child(b)
		bells.append(b)


## Spawns Igris in his chamber until his control is broken (seen.t10).
func _build_igris() -> void:
	if not _attempt.is_empty():
		# Left or reset the room mid-fight: that attempt ends here.
		playtest.igris_end(session_time(), "reiniciou" if room_id == str(config.tower.get("igris", {}).get("room", "")) else "saiu da câmara")
	if igris and is_instance_valid(igris):
		igris.queue_free()
	igris = null
	# Leaving the chamber ends the attempt: a later death elsewhere must not
	# roll supplies back to the chamber's snapshot.
	_attempt = {}
	var wiring: Dictionary = config.tower.get("igris", {})
	if str(wiring.get("room", "")) != room_id or state.has_flag("seen.%s" % _igris_end_scene()):
		return
	igris = Igris.new()
	igris.setup(IgrisFight.new(config.encounter(str(wiring.get("encounter", "igris"))), wiring), player, wiring)
	for e in room.data.entities:
		if str(e.get("id", "")) == str(wiring.get("boss", "")):
			igris.position = room.data.tile_center(Vector2i(int(e["tile"][0]), int(e["tile"][1])))
	igris.muffler_opened.connect(func() -> void: hud.toast("O abafador no peito de Igris brilha: use o gancho!", 2.5))
	igris.control_broken.connect(_on_igris_freed)
	add_child(igris)
	enemies.append(igris)
	if state.has_flag("seen.%s" % str(wiring.get("start_scene", "t08"))):
		_start_igris_attempt()


## True for the arena rings that pull Yggnus to themselves
## (torre-akurame.json igris.free_anchors).
func _is_free_anchor(anchor_id: String) -> bool:
	return config.tower.get("igris", {}).get("free_anchors", []).has(anchor_id)


## Scene that plays when Igris's control breaks (torre-akurame.json igris.end_scene).
func _igris_end_scene() -> String:
	return str(config.tower.get("igris", {}).get("end_scene", "t10"))


## The fight starts (after t08, or at once on later attempts): remember
## the flasks and bread so a death gives them back.
func _start_igris_attempt() -> void:
	if igris == null or igris.active:
		return
	_attempt = {"full_flasks": state.full_flasks.duplicate(), "bread": state.item_count("pao_porto"), "life": player.health.current}
	playtest.igris_start(session_time())
	igris.active = true


func _on_igris_freed() -> void:
	playtest.igris_end(session_time(), "vitória")
	# The attempt stays open until the victory scene commits it: a save made
	# while that scene plays (closing the window) still holds the fight's
	# start, so the victory and the supplies spent are saved together
	# (mecanicas-e-dificuldade.md §9).
	dialogue.request(str(config.encounter("igris").get("success_event", "igris_controle_rompido")))


func _on_igris_bell(bell_id: String) -> void:
	if igris == null or not igris.active:
		return
	var before := igris.fight.phase
	if igris.fight.ring(bell_id):
		hud.toast("O regulador se abriu: dois golpes!")
	elif before == IgrisFight.Phase.BELLS and igris.fight.phase == IgrisFight.Phase.BELLS_SHOW:
		hud.toast("Ordem errada. Observe os sinos de novo.")


func _on_bell_rung(bell_id: String) -> void:
	var def: Dictionary = config.tower.get("bells", {})
	match bell_puzzle.ring(bell_id):
		BellPuzzle.Result.SOLVED:
			state.apply([{"op": "set_flag", "flag": str(def.get("solved_flag", "")), "value": true}])
			hud.toast("Os três sinos soam juntos. A porta se abriu.")
		BellPuzzle.Result.WRONG:
			hud.toast("O som se perde. A sequência recomeça.")
	for b in bells:
		var idx: int = bell_puzzle.order.find(b.bell_id)
		b.lit = bell_puzzle.solved or (idx >= 0 and idx < bell_puzzle.progress())
		b.queue_redraw()


## Life the best healing item would restore now: a full flask, else bread.
func _heal_source() -> int:
	if state.full_flask_count() > 0:
		return int(config.data.get("healing", {}).get("life_restored", 3))
	if state.item_count("pao_porto") > 0:
		return int(config.progression.get("recuperacao", {}).get("pao_vida", 1))
	return 0


## Consumes the item [method _heal_source] chose, at the effect frame.
func _heal_commit() -> bool:
	if state.full_flask_count() > 0:
		return state.apply([{"op": "drink_flask"}])
	return state.apply([{"op": "use_item", "item_id": "pao_porto"}])


func _physics_process(delta: float) -> void:
	_tool_cooldown = maxf(0.0, _tool_cooldown - delta)
	if player == null or player.is_dead():
		return
	if _autoattack:
		_autoattack_timer -= delta
		if _autoattack_timer <= 0.0:
			_autoattack_timer = 0.4
			player.request_attack()
	if _autoitem:
		_autoitem_timer -= delta
		if _autoitem_timer <= 0.0:
			_autoitem_timer = 1.2
			use_item()
	if _autointeract:
		_autointeract_timer -= delta
		if _autointeract_timer <= 0.0:
			_autointeract_timer = 0.8
			interact()
	if igris and is_instance_valid(igris) and igris.fight:
		var seq := igris.fight.sequence()
		for b in bells:
			var lit := false
			if igris.fight.phase == IgrisFight.Phase.BELLS_SHOW and igris.fight.showing >= 0:
				lit = str(seq[igris.fight.showing]) == b.bell_id
			if b.lit != lit:
				b.lit = lit
				b.queue_redraw()
	var target := interactable_in_front()
	var highlight := str(target.get("id", ""))
	if highlight != room.highlight_id:
		room.highlight_id = highlight
		room.queue_redraw()
	_pick_up_fragments()
	_check_doors()


func _unhandled_input(event: InputEvent) -> void:
	if player == null or player.is_dead() or dialogue.is_open() or shop_panel.is_open():
		return
	if event.is_action_pressed("map"):
		hud.toggle_inventory(state, config)
		get_tree().paused = hud.is_inventory_open()
		get_viewport().set_input_as_handled()
		return
	if hud.is_inventory_open() or _transitioning:
		return
	if event.is_action_pressed("attack") and not player.has_sword:
		playtest.refuse(session_time(), "espada antes de tê-la")
	if event.is_action_pressed("interact"):
		if interact() == "nothing" and interactable_in_front().is_empty():
			playtest.refuse(session_time(), "examinar sem nada à frente")
	elif event.is_action_pressed("quick_swap"):
		quick_swap()
	elif event.is_action_pressed("reset_room"):
		# Playtest helper: brings the room's enemies back and the player to the entry.
		playtest.reset(session_time(), room.data.display_name)
		load_room(room_id, Vector2i(-1, -1), false)
	for i in SPAWN_KEYS.size():
		if event.is_action_pressed("spawn_%d" % (i + 1)):
			spawn_near_player(SPAWN_KEYS[i])


## The interactable entity in front of the player, or {}.
func interactable_in_front() -> Dictionary:
	var probe := player.global_position + player.motor.facing * INTERACT_REACH
	var best: Dictionary = {}
	var best_d := INTERACT_RADIUS
	for e in room.data.entities:
		if not INTERACTABLE.has(str(e.get("kind", ""))):
			continue
		var t: Array = e.get("tile", [0, 0])
		var d := room.data.tile_center(Vector2i(int(t[0]), int(t[1]))).distance_to(probe)
		if d <= best_d:
			best = e
			best_d = d
	return best


## Uses the entity in front of the player. Returns what happened, for tests:
## "chest", "chest_empty", "scene", "clue", "clue_locked", "checkpoint",
## "shop", "nothing".
func interact() -> String:
	if dialogue.is_open() or shop_panel.is_open() or player.is_busy():
		return "nothing"
	var e := interactable_in_front()
	if e.is_empty():
		return "nothing"
	var trigger := str(e.get("trigger_id", ""))
	var receipt := str(e.get("persistent_receipt", ""))
	match str(e["kind"]):
		"chest":
			if room.is_spent(e):
				hud.toast("Vazio.")
				return "chest_empty"
			var effects := config.reward_effects(trigger)
			if not effects.is_empty() and state.has_receipt(str(effects[0].get("receipt_id", ""))):
				# The reward came from elsewhere in an older version (the bow
				# was in the cellar): the chest opens empty, it never lies.
				state.apply([{"op": "add_receipt", "receipt_id": receipt}])
				hud.toast("Vazio. Você já tem o que estava aqui.")
				return "chest_empty"
			if not effects.is_empty():
				effects.append({"op": "add_receipt", "receipt_id": receipt})
				if state.apply(effects):
					var r: Dictionary = config.rewards[trigger]
					var got := "Recebeu %s" % ("%d Bronze" % int(r["bronze"]) if r.has("bronze") else _amount_text(str(r["item"]), int(r.get("quantity", 1))))
					for x: Variant in r.get("also", []):
						if x is Dictionary:
							got += " e %s" % _amount_text(str(x.get("item", "")), int(x.get("quantity", 1)))
					var tip := _dungeon_item_tip(str(r.get("item", "")))
					if tip.is_empty():
						tip = _take_tool_tip()
					hud.toast(got + ("\n" + tip if not tip.is_empty() else ""), 3.0 if tip.is_empty() else 5.0)
				return "chest"
			var chest_scene := dialogue.blocking_scene_id(trigger)
			if dialogue.request(trigger):
				if not chest_scene.is_empty():
					_pending_chest = {"scene": chest_scene, "receipt": receipt}
				return "scene"
			hud.toast("Está trancado por um mecanismo.")
			return "nothing"
		"mystery_clue":
			if room.is_spent(e):
				hud.toast("Você já anotou esta pista.")
				return "nothing"
			for need in config.clue_requirements(str(e["sets_flag"])):
				if not state.has_flag(str(need)):
					hud.toast("Algo aqui chama atenção, mas ainda não faz sentido.")
					return "clue_locked"
			state.apply([{"op": "set_flag", "flag": str(e["sets_flag"]), "value": true}, {"op": "add_receipt", "receipt_id": receipt}])
			hud.toast("Pista registrada.")
			_on_clue_noted(str(e["sets_flag"]))
			return "clue"
		"refill":
			return _use_refill(e)
		"checkpoint":
			# The marco becomes the safe entry: a load starts beside it.
			_entry_tile = Vector2i(int(e["tile"][0]), int(e["tile"][1]) + 1)
			state.apply([{"op": "set_checkpoint", "room": room_id, "entity_id": str(e["id"])}])
			player.health.reset()
			hud.toast("Marco ativado. Vida restaurada.")
			dialogue.request("ativar_primeiro_marco")
			return "checkpoint"
		_:
			var w: Dictionary = config.tower.get("weight", {})
			if str(e.get("id", "")) == str(w.get("lock", "-")):
				return _use_weight_lock(w)
			var hosted := _use_mystery_host(str(e.get("id", "")))
			if not hosted.is_empty():
				return hosted
			if trigger == SHOP_TRIGGER and state.has_flag("seen.r05"):
				# After the first talk the merchant goes straight to the goods.
				shop_panel.open.call_deferred(shop, state)
				return "shop"
			if not trigger.is_empty() and trigger != "<null>" and dialogue.request(trigger):
				return "scene"
			for later in TRIGGER_FOLLOW_UPS.get(trigger, []):
				if dialogue.request(later):
					return "scene"
			hud.toast(str(FOLLOW_UP_NOTES.get(trigger, "...")))
			return "nothing"


## A needle container: tops the needles up (ferramentas.json refill_amount).
func _use_refill(e: Dictionary) -> String:
	var tool := tools.tool_for_ammo(str(e.get("item", "")))
	if tool.is_empty() or not tools.owns(tool, state):
		hud.toast("Um recipiente com agulhas de fio. Ainda não há com o que dispará-las.")
		return "nothing"
	var effects := tools.top_up_effects(tool, tools.refill_amount, state)
	if effects.is_empty():
		hud.toast("Suas agulhas já estão completas.")
		return "nothing"
	state.apply(effects)
	hud.toast("Agulhas repostas: %d." % tools.ammo_count(tool, state))
	return "refill"


## Plays scene [param scene_id] through its trigger. False if it cannot play now.
func _request_scene(scene_id: String) -> bool:
	var scene: Dictionary = dialogue.db.scenes.get(scene_id, {})
	return not scene.is_empty() and dialogue.request(str(scene.get("trigger_id", "")))


## A clue was noted: if it completes a mystery's set, the comparison plays.
func _on_clue_noted(flag: String) -> void:
	for q: MysteryQuest in mysteries.values():
		if q.clue_flags().has(flag):
			if q.step(state) == MysteryQuest.Step.COMPARE:
				_request_scene(q.scene("comparison"))
			else:
				hud.toast("Pista registrada (%d/%d)." % [q.clues_found(state), q.clue_flags().size()])


## The mystery hosted by entity [param entity_id] takes its next step:
## first talk, comparison, the question, or the reward. Returns "" when it
## has nothing to do, so the entity's own use (the shop, the inscription)
## goes on.
func _use_mystery_host(entity_id: String) -> String:
	for q: MysteryQuest in mysteries.values():
		if str(q.wiring.get("host", "")) != entity_id:
			continue
		match q.step(state):
			MysteryQuest.Step.START:
				return "scene" if _request_scene(q.scene("start")) else ""
			MysteryQuest.Step.COMPARE:
				return "scene" if _request_scene(q.scene("comparison")) else ""
			MysteryQuest.Step.REWARD:
				return "scene" if _request_scene(q.scene("reward")) else ""
			MysteryQuest.Step.ANSWER:
				_ask_mystery(q)
				return "question"
			MysteryQuest.Step.COLLECT:
				hud.toast("Pistas: %d/%d." % [q.clues_found(state), q.clue_flags().size()])
				if not bool(q.wiring.get("host_is_shop", false)):
					# An object host has nothing else to say; keep the count on screen.
					return "nothing"
	return ""


## Shows the mystery's answers by option id, plus a way out.
func _ask_mystery(q: MysteryQuest) -> void:
	var texts: Array[String] = []
	for o: Dictionary in q.options():
		texts.append(str(o.get("text", "")))
	texts.append("Ver as mercadorias." if bool(q.wiring.get("host_is_shop", false)) else "Agora não.")
	dialogue.ask(str(q.wiring.get("question", "")), texts, func(i: int) -> void: answer_mystery(q.id(), i))


## Answers mystery [param mystery_id] with option [param index] (-1 or the
## last, extra option leave it open). Returns the [enum MysteryQuest.Result],
## or -1 when nothing was answered.
func answer_mystery(mystery_id: String, index: int) -> int:
	var q: MysteryQuest = mysteries.get(mystery_id)
	if q == null:
		return -1
	if index < 0 or index >= q.options().size():
		if index == q.options().size() and bool(q.wiring.get("host_is_shop", false)):
			if state.has_flag("seen.%s" % SHOP_SCENE):
				shop_panel.open.call_deferred(shop, state)
			else:
				# First visit: the merchant's own introduction opens the shop.
				dialogue.request.call_deferred(SHOP_TRIGGER)
		return -1
	var result := q.submit(state, str(q.options()[index].get("id", "")))
	match result:
		MysteryQuest.Result.CORRECT:
			_request_scene.call_deferred(q.scene("reward"))
		MysteryQuest.Result.WRONG:
			# Nothing is taken away; Ádally or Igris nudge, then the next hint.
			_pending_hint = {"scene": q.scene("wrong"), "text": "Dica: " + q.hint(state)}
			if not _request_scene(q.scene("wrong")):
				hud.toast(str(_pending_hint["text"]), 5.0)
				_pending_hint = {}
		MysteryQuest.Result.NOT_READY:
			hud.toast("Ainda faltam pistas (%d/%d)." % [q.clues_found(state), q.clue_flags().size()])
	return result


## Inventory lines for the ammo, the relic slot and the mysteries in
## progress. [param effects] adds each relic's effect (the backpack shows
## only the picked relic's, so its panel keeps its size).
func _inventory_lines(effects: bool = true) -> PackedStringArray:
	var lines := PackedStringArray()
	var gear := PackedStringArray()
	for tool in _owned_tools:
		var n := tools.ammo_count(tool, state)
		if n >= 0:
			gear.append("%s %d/%d" % [config.item_name(tools.ammo_of(tool)), n, tools.ammo_cap(tool)])
	if not gear.is_empty():
		lines.append("")
		lines.append("MUNIÇÃO: " + " · ".join(gear))
	if state.has_flag(GameState.RELIC_SLOT_FLAG):
		lines.append("")
		lines.append("RELÍQUIA (uma por vez): %s" % (config.item_name(state.equipped_relic) if not state.equipped_relic.is_empty() else "nenhuma"))
		for relic: String in _owned_relics():
			if effects:
				lines.append("%s %s: %s" % ["»" if relic == state.equipped_relic else "·", config.item_name(relic), _relic_effect_text(relic)])
	var shown := false
	for q: MysteryQuest in mysteries.values():
		var st := q.step(state)
		if st == MysteryQuest.Step.LOCKED or st == MysteryQuest.Step.START:
			continue
		if not shown:
			lines.append("")
			lines.append("MISTÉRIOS")
			shown = true
		var status := "resolvido" if st == MysteryQuest.Step.DONE or st == MysteryQuest.Step.REWARD else "pistas %d/%d" % [q.clues_found(state), q.clue_flags().size()]
		lines.append("%s: %s" % [str(q.def.get("title", q.id())), status])
	return lines


## Relics the player owns, in data order.
func _owned_relics() -> Array[String]:
	var out: Array[String] = []
	for relic: String in relics.relics:
		if state.item_count(relic) > 0:
			out.append(relic)
	return out


## "Preparo do frasco 0,65 → 0,55 s; ..." for [param relic].
func _relic_effect_text(relic: String) -> String:
	var labels: Dictionary = config.mystery_wiring.get("relic_labels", {})
	var parts := PackedStringArray()
	for fx: Dictionary in relics.effects(relic):
		var label: Array = labels.get(fx["key"], [fx["key"], ""])
		parts.append(("%s %s → %s %s" % [label[0], _num(fx["from"]), _num(fx["to"]), label[1]]).strip_edges())
	return "; ".join(parts)


## A number as the kit writes it ("0,55"); "?" when missing.
func _num(v: Variant) -> String:
	if v == null:
		return "?"
	var f := float(v)
	return str(int(f)) if is_equal_approx(f, roundf(f)) else str(snappedf(f, 0.01)).replace(".", ",")


## Puts the next owned relic in the slot (then none); the backpack equips a
## chosen one with [method use_from_backpack]. Not in combat and never
## during a boss attempt. Returns a status line.
func cycle_relic() -> String:
	if not state.has_flag(GameState.RELIC_SLOT_FLAG):
		return "Ainda não há espaço de relíquia."
	var owned := _owned_relics()
	var order: Array[String] = [""]
	order.append_array(owned)
	var next := order[(order.find(state.equipped_relic) + 1) % order.size()]
	# The same path as the backpack: equipping the one in the slot again
	# takes it off.
	return use_from_backpack(next if not next.is_empty() else state.equipped_relic)


## Interact on an item in the backpack (design/gdd/telas-e-mochila.md
## §3.3): a tool, its ammo or a flask goes on the item button; a relic goes
## in the relic slot (or comes out of it), with the same rules as before.
## Returns the status line the backpack shows.
func use_from_backpack(item_id: String) -> String:
	var tool := ""
	for t: String in _owned_tools:
		if tools.item_of(t) == item_id or tools.ammo_of(t) == item_id:
			tool = t
	if item_id.begins_with(GameState.FLASK_PREFIX) and _owned_tools.has(ToolRules.FLASK):
		tool = ToolRules.FLASK
	if not tool.is_empty():
		equipped = tool
		_refresh_story()
		_queue_save()
		return "%s no botão de item (%s)." % [tools.label(tool, state).split(" ")[0], DialogueBox._key("item")]
	if str(config.items.get(item_id, {}).get("type", "")) == "reliquia":
		if not state.has_flag(GameState.RELIC_SLOT_FLAG):
			return "Ainda não há espaço de relíquia."
		if in_combat():
			playtest.refuse(session_time(), "trocar a relíquia em combate")
			return "Não dá para trocar a relíquia em combate."
		var next := "" if state.equipped_relic == item_id else item_id
		if not state.apply([{"op": "equip_relic", "relic_id": next}]):
			return "Não foi possível trocar."
		_queue_save()
		return "Relíquia: %s." % (config.item_name(next) if not next.is_empty() else "nenhuma")
	return ""


## True during a boss attempt or with a living enemy near Yggnus
## (misterios-ligacao.json relic_swap_combat_radius).
func in_combat() -> bool:
	if not _attempt.is_empty():
		return true
	var radius := float(config.mystery_wiring.get("relic_swap_combat_radius", 160))
	for enemy in enemies:
		# Defeated enemies are freed but stay listed: check validity first.
		if not is_instance_valid(enemy) or not (enemy is EnemyBase):
			continue
		if not enemy.is_defeated and enemy.global_position.distance_to(player.global_position) <= radius:
			return true
	return false


## The counterweight lock: with the weight raised, Ádally fixes it (t05)
## and the bridge to the bells stays down for good.
func _use_weight_lock(w: Dictionary) -> String:
	if state.has_flag(str(w.get("solved_flag", ""))):
		hud.toast("A trava segura a ponte.")
		return "nothing"
	if not room.raised.get(str(w.get("block", "")), false):
		hud.toast("O peso está embaixo. Puxe-o com o gancho.")
		return "nothing"
	var trigger := str(w.get("lock_scene_trigger", ""))
	var lock_scene := dialogue.blocking_scene_id(trigger)
	if not lock_scene.is_empty() and dialogue.request(trigger):
		_pending_weight = {"scene": lock_scene, "flag": str(w.get("solved_flag", ""))}
		return "scene"
	# Scene already seen (or skipped before): lock it directly.
	state.apply([{"op": "set_flag", "flag": str(w.get("solved_flag", "")), "value": true}])
	hud.toast("A trava ficou no lugar.")
	return "lock"


func _on_scene_finished(scene_id: String, applied: bool) -> void:
	if str(_pending_hint.get("scene", "")) == scene_id:
		hud.toast(str(_pending_hint["text"]), 5.0)
		_pending_hint = {}
	for q: MysteryQuest in mysteries.values():
		if scene_id == q.scene("start"):
			# Clues found before the first talk: compare right away.
			_request_scene.call_deferred(q.scene("comparison"))
	if str(_pending_weight.get("scene", "")) == scene_id:
		if applied:
			state.apply([{"op": "set_flag", "flag": str(_pending_weight["flag"]), "value": true}])
		_pending_weight = {}
	if str(_pending_chest.get("scene", "")) == scene_id:
		if applied:
			state.apply([{"op": "add_receipt", "receipt_id": str(_pending_chest["receipt"])}])
		_pending_chest = {}
	if scene_id == str(config.tower.get("igris", {}).get("start_scene", "t08")):
		_start_igris_attempt.call_deferred()
	var chained := str(config.tower.get("scene_chain", {}).get(scene_id, ""))
	if not chained.is_empty():
		dialogue.request.call_deferred(chained)
	if scene_id == _igris_end_scene():
		# Victory committed in this same update: the spent supplies stay spent.
		_attempt = {}
		# Igris chooses to leave (chefes.json story_followup); he is gone for good.
		var followup := str(config.encounter("igris").get("story_followup", ""))
		if not followup.is_empty():
			dialogue.request.call_deferred(followup)
		_build_igris.call_deferred()
	if scene_id == SHOP_SCENE:
		shop_panel.open.call_deferred(shop, state)
	var next := prologue.trigger_after(scene_id)
	if not next.is_empty():
		dialogue.request.call_deferred(next)
	_sync_invasion.call_deferred()


func _pick_up_fragments() -> void:
	for e in room.data.entities:
		if str(e.get("kind", "")) != "unique_fragment" or room.is_spent(e):
			continue
		var t: Array = e.get("tile", [0, 0])
		if room.data.tile_center(Vector2i(int(t[0]), int(t[1]))).distance_to(player.global_position) > 10.0:
			continue
		var frag: Dictionary = config.fragments.get(str(e.get("collectible_id", "")), {})
		var need := str(frag.get("requires_item", e.get("requires_item", "")))
		if not need.is_empty() and need != "<null>" and state.item_count(need) == 0:
			continue
		var before := state.life_max()
		state.apply([{"op": "collect_fragment", "fragment_id": str(e["collectible_id"]), "receipt_id": str(e["persistent_receipt"])}])
		if state.life_max() > before:
			player.health.maximum = state.life_max()
			player.health.heal(state.life_max())
			hud.toast("Vida máxima aumentou!")
		else:
			hud.toast("Fragmento de Âncora (%d/4)" % (state.fragments.size() % 4))


## Whether [param door] can be used with the current progress.
func is_door_open(door: Dictionary) -> bool:
	if prologue.blocks_door(state, room_id, str(door.get("id", ""))):
		return false
	var gate: Variant = door.get("gate")
	if gate == null or str(gate).is_empty():
		return true
	if state.has_flag(str(door.get("unlock_persistent_flag", ""))):
		return true
	var g := str(gate)
	if g.begins_with("boss_key:"):
		return dungeons.boss_gate_open(g.trim_prefix("boss_key:"), state)
	if g.begins_with("key:") or g.begins_with("item:"):
		return state.item_count(g.split(":")[1]) > 0
	return state.has_flag(g)


## The door whose zone [param pos] is in: its tile and the ground up to
## its arch in the wall ([method Room.door_zone]).
func _door_at(pos: Vector2) -> String:
	for door in room.data.doors:
		if room.door_zone(door).has_point(pos):
			return str(door["id"])
	return ""


func _check_doors() -> void:
	if _transitioning:
		return
	var here := _door_at(player.global_position)
	if here != _arrival_door:
		_arrival_door = ""
	if here.is_empty() or here == _arrival_door:
		if here.is_empty():
			_locked_notice = ""
		return
	for door in room.data.doors:
		if str(door["id"]) != here:
			continue
		if not is_door_open(door):
			if _locked_notice != here:
				_locked_notice = here
				var scene := str(config.tower.get("locked_door_scenes", {}).get(here, ""))
				if not scene.is_empty() and dialogue.request(scene):
					return
				hud.toast(_locked_text(door, here))
				playtest.refuse(session_time(), "porta fechada (%s)" % here)
			return
		_go_through(door)


## What a closed door says when the player walks into it.
func _locked_text(door: Dictionary, door_id: String) -> String:
	if prologue.blocks_door(state, room_id, door_id):
		return "As amarras de Yame prendem a porta."
	if door.has("locked_text"):
		return str(door["locked_text"])
	if Room.is_cracked(door):
		return "A parede está rachada. Uma explosão a derrubaria."
	var gate := str(door.get("gate", ""))
	if gate.begins_with("boss_key:"):
		return "Uma porta grande com fechadura dourada. Precisa da %s." % config.item_name(gate.trim_prefix("boss_key:"))
	if gate.begins_with("key:"):
		return "Trancada. Precisa de uma chave pequena."
	return "A passagem está fechada."


## "Arco de Fio", or "3 Cargas de Bronze" (itens.json "plural") when more
## than one.
func _amount_text(item: String, n: int) -> String:
	if n <= 1:
		return config.item_name(item)
	return "%d %s" % [n, str(config.items.get(item, {}).get("plural", config.item_name(item)))]


## What a dungeon item does, told when it is found ("" for other items).
func _dungeon_item_tip(item: String) -> String:
	for id: String in dungeons.defs:
		var def: Dictionary = dungeons.defs[id]
		if item == str(def.get("map_item", "")):
			return "Todas as salas aparecem no mapa do inventário (%s)." % DialogueBox._key("map")
		if item == str(def.get("compass_item", "")):
			return "O mapa agora marca os baús fechados e a sala do chefe."
		if item == str(def.get("boss_key", "")):
			return "Ela abre a porta grande de fechadura dourada."
	return ""


## The dungeon map for the inventory ({} outside a dungeon).
func dungeon_map_view() -> Dictionary:
	var d := dungeons.dungeon_of(room_id)
	if d.is_empty():
		return {}
	var v := dungeons.map_view(d, state, room_id)
	v["name"] = str(dungeons.def_of(d).get("name", ""))
	return v


## Keys of the current dungeon for the HUD's counters ({} outside one).
func dungeon_key_view() -> Dictionary:
	var d := dungeons.dungeon_of(room_id)
	if d.is_empty():
		return {}
	var v := dungeons.map_view(d, state, room_id)
	return {"small_keys": int(v["small_keys"]), "boss_key": bool(v["boss_key"])}



func _go_through(door: Dictionary) -> void:
	var gate := str(door.get("gate", ""))
	var flag := str(door.get("unlock_persistent_flag", ""))
	if not state.has_flag(flag) and door.get("gate") != null:
		var effects: Array = [{"op": "set_flag", "flag": flag, "value": true}]
		if gate.begins_with("key:") and str(door.get("key_consumption", "")) == "once_when_first_open":
			effects.push_front({"op": "consume_quest_items_once", "items": {gate.split(":")[1]: 1}, "receipt_id": "key.%s" % door["id"]})
		state.apply(effects)
	_transitioning = true
	get_tree().paused = true
	var t: Array = door.get("target_tile", [1, 1])
	var target := Vector2i(int(t[0]), int(t[1]))
	if _can_slide(door):
		await _slide_to(door, target)
	else:
		var out := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		out.tween_property(_fade, "modulate:a", 1.0, FADE_TIME)
		await out.finished
		load_room(str(door["target_room"]), target, false)
		var back := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		back.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
		await back.finished
	if not is_inside_tree():
		return
	get_tree().paused = false
	_transitioning = false
	_on_room_entered()


## The screen scrolls from the old room to the next one, side by side, as
## if the camera slid across the wall (exploração §1). A copy of the old room
## ("ghost", drawn only) is put next to the new room for the length of the
## slide.
func _slide_to(door: Dictionary, target: Vector2i) -> void:
	var old_data := room.data
	var old_top := room.top_extent()
	var old_door := old_data.tile_center(_door_tile(door))
	var spent := _broken_breakables()
	var cam := player.camera
	var old_center := cam.get_screen_center_position()
	load_room(str(door["target_room"]), target, false)
	var ghost := Room.new()
	ghost.state = state
	ghost.door_open = is_door_open
	ghost.breakable_rules = breakables
	add_child(ghost)
	move_child(ghost, 0)
	ghost.build(old_data)
	ghost.name = "SlideGhost"  # build() names it after the room
	# Drawn only: no walls or pots to hit, the bushes and pots look as the
	# player left them, and one ambient colour and set of lights (the new
	# room's, which must not go over the per-item light limit).
	for c in ghost.get_children():
		if c is Breakable:
			var b := c as Breakable
			b.remove_from_group("breakables")
			b.collision_layer = 0
			if spent.has(b.tile):
				if breakables.stub(b.kind).is_empty():
					ghost.remove_child(b)
					b.queue_free()
				else:
					b.is_broken = true
					b.queue_redraw()
		elif c is Torch:
			(c as Torch).drop_light()
		elif c is PointLight2D or c.name == "Walls" or c.name == "Ambient":
			ghost.remove_child(c)
			c.queue_free()
	var side := str(door.get("side", ""))
	var new_size := Vector2(room.data.pixel_size())
	var old_size := Vector2(old_data.pixel_size())
	var arrive := room.data.tile_center(target)
	var at := arrive - old_door  # lines the two doors up on the other axis
	match side:
		"north":
			at.y = new_size.y + old_top
		"south":
			at.y = -room.top_extent() - old_size.y
		"east":
			at.x = -old_size.x
		"west":
			at.x = new_size.x
	ghost.position = at
	ghost.reset_physics_interpolation()
	# The tree is paused, so no physics frame would move an interpolated
	# camera: it is driven by hand, without interpolation, for the slide.
	var interp := cam.physics_interpolation_mode
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cam.force_update_scroll()
	var new_center := cam.get_screen_center_position()
	var smoothing := cam.position_smoothing_enabled
	cam.position_smoothing_enabled = false
	cam.limit_enabled = false
	cam.offset = Vector2.ZERO
	cam.force_update_scroll()
	# Offsets are measured from where the free camera sits now (node offset
	# and drag margin included), so the slide starts and ends without a jump.
	var base := cam.get_screen_center_position()
	var from := old_center + at - base
	var to := new_center - base
	var move := func(o: Vector2) -> void:
		cam.offset = o
		cam.force_update_scroll()
	move.call(from)
	var slide := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	slide.tween_method(move, from, to, breakables.slide_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await slide.finished
	if is_instance_valid(ghost):
		ghost.queue_free()
	if not is_instance_valid(cam):
		return
	cam.offset = Vector2.ZERO
	cam.limit_enabled = true
	cam.position_smoothing_enabled = smoothing
	cam.reset_smoothing()
	cam.force_update_scroll()
	cam.physics_interpolation_mode = interp
	cam.reset_physics_interpolation()


## Tiles of the current room's bushes and pots already broken this visit.
func _broken_breakables() -> Dictionary:
	var out := {}
	if room == null or room.data == null:
		return out
	var standing := {}
	for c in room.get_children():
		if c is Breakable and not (c as Breakable).is_broken and not c.is_queued_for_deletion():
			standing[(c as Breakable).tile] = true
	for kind: String in room.data.breakables:
		for at: Vector2i in room.data.breakables[kind]:
			if not standing.has(at):
				out[at] = true
	return out


## Whether [param door] slides the screen: it has a side and the door it
## leads to is on the opposite side of the next room, so the two rooms can
## sit edge to edge. Other doors fade.
func _can_slide(door: Dictionary) -> bool:
	var side := str(door.get("side", ""))
	if not SLIDE_DIRS.has(side) or room == null or room.data == null:
		return false
	var next := RoomData.load_room(str(door.get("target_room", "")))
	if next == null:
		return false
	var opposite: String = SLIDE_DIRS[SLIDE_DIRS.find(side) ^ 1]
	for d: Dictionary in next.doors:
		if str(d.get("target_room", "")) == room.data.id and str(d.get("side", "")) == opposite:
			return true
	return false


## Tile of [param door] in the room it leaves.
func _door_tile(door: Dictionary) -> Vector2i:
	var t: Array = door.get("tile", [0, 0])
	return Vector2i(int(t[0]), int(t[1]))


func _exit_tree() -> void:
	# Leaving mid-transition (back to the title, a test tearing down) must
	# not leave the whole tree paused.
	if _transitioning and is_inside_tree():
		get_tree().paused = false
		_transitioning = false


## Playtest helper: spawns [param kind] about five tiles from the player,
## on the first free floor tile found to the right, left, below or above.
func spawn_near_player(kind: String) -> Node:
	var data := room.data
	var here := Vector2i(player.global_position / data.tile_size)
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var tile: Vector2i = here + dir * 5
		if data.is_walkable(tile):
			return spawn_enemy(kind, tile)
	return null


func _on_player_died() -> void:
	playtest.death(session_time(), room.data.display_name, death_cause())
	if not _attempt.is_empty():
		playtest.igris_end(session_time(), "morte")
		state.apply([{"op": "restore_supplies", "full_flasks": _attempt["full_flasks"], "bread": _attempt["bread"]}])
		_attempt = {}
	if hud:
		hud.show_banner("Yggnus caiu")
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if hud:
		hud.show_banner("")
	# Death keeps progress; return to the last checkpoint (or this room's entry)
	# with full life; the room's common enemies reset (mecanicas §9).
	if state.checkpoint.is_empty():
		load_room(room_id)
		return
	var cp_room := str(state.checkpoint["room"])
	var data := RoomData.load_room(cp_room)
	if data == null:
		load_room(room_id)
		return
	var moved := cp_room != room_id
	var tile := data.entry_default
	for e in data.entities:
		if str(e.get("id", "")) == str(state.checkpoint["entity_id"]):
			tile = Vector2i(int(e["tile"][0]), int(e["tile"][1]) + 1)
	load_room(cp_room, tile)
	if moved:
		# Arriving somewhere new by respawn counts as entering it.
		_on_room_entered()


func _arg(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
