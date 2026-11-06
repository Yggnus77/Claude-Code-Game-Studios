class_name Prologue
extends RefCounted
## Rules of the Versalhes stretch (design/kit/plano-implementacao.md, Etapa 4;
## roteiro-jogo-completo.md "Prólogo"). Pure: it reads a [GameState] and
## answers which scene comes next, what the current objective is and whether
## the invasion is running. The nodes in main.gd only follow these answers.
##
## Order: p00 (new game) → p01 (examine the clock) → walk to the square →
## p02 → back to the workshop → p03 → p04 (Matrix) → p05 (sword and shield)
## → cut the three bindings while Yame Black throws paper → p07 → the
## Versalhes marco (p08) → the road east.

const WORKSHOP := "v00_oficina"
const SQUARE := "v01_praca"

## Encounter definition (chefes.json "yame_oficina").
var encounter: Dictionary


func _init(encounter_def: Dictionary = {}) -> void:
	encounter = encounter_def


## Trigger to raise when the player arrives in [param room_id], or "".
func trigger_on_enter(state: GameState, room_id: String) -> String:
	if room_id == SQUARE and state.has_flag("seen.p01") and not state.has_flag("seen.p02"):
		return "decima_terceira_badalada"
	if room_id == WORKSHOP and state.has_flag("seen.p02") and not state.has_flag("seen.p03"):
		return "adally_apresentada"
	return ""


## Trigger that follows scene [param scene_id] directly, or "".
## p03 → p04 → p05 play back to back, like one conversation in the workshop.
func trigger_after(scene_id: String) -> String:
	match scene_id:
		"p03":
			return "exodia_abre_relogio"
		"p04":
			return "yame_entra"
	return ""


## True from the end of p05 until p07: Yame Black is in the workshop.
func invasion_active(state: GameState) -> bool:
	return state.has_flag(str(encounter.get("start_after", "seen.p05"))) and not state.has_flag("seen.p07")


## Receipt that records binding [param binding_id] as cut.
static func binding_receipt(binding_id: String) -> String:
	return "unique.%s" % binding_id


## Binding ids still holding the exit.
func bindings_left(state: GameState) -> Array:
	var left := []
	for id in encounter.get("bindings", []):
		if not state.has_receipt(binding_receipt(str(id))):
			left.append(str(id))
	return left


## True when the invasion is over: every binding has its receipt.
func all_bindings_cut(state: GameState) -> bool:
	return bindings_left(state).is_empty()


## Whether door [param door_id], seen from [param room_id], is held shut by
## the invasion. Only the workshop side is tied: coming back in from the
## square (after a death at the marco) stays possible.
func blocks_door(state: GameState, room_id: String, door_id: String) -> bool:
	return room_id == WORKSHOP and invasion_active(state) and door_id == str(encounter.get("blocks_exit", ""))


## Seconds between paper throws, faster with each cut binding.
func throw_interval(state: GameState) -> float:
	var steps: Array = encounter.get("projectile_interval", [1.6])
	var cut: int = encounter.get("bindings", []).size() - bindings_left(state).size()
	return float(steps[clampi(cut, 0, steps.size() - 1)])


## Short objective for the HUD, so the goal reads without narration.
func objective(state: GameState) -> String:
	if not state.has_flag("seen.p00"):
		return ""
	if not state.has_flag("seen.p01"):
		return "Examine o relógio na bancada."
	if not state.has_flag("seen.p02"):
		return "Saia para a praça e veja o que aconteceu."
	if not state.has_flag("seen.p05"):
		return "Volte à oficina."
	if not state.has_flag("seen.p07"):
		var total: int = encounter.get("bindings", []).size()
		return "Corte as amarras da porta (%d/%d). Defenda os papéis com o escudo." % [total - bindings_left(state).size(), total]
	if not state.has_flag("seen.p08"):
		return "Ative o Marco de Memória na praça."
	if not state.has_flag("visited.t00_base"):
		return "Siga pela estrada a leste, rumo à Torre Akurame."
	# Torre Akurame (Etapa 6): one line per mechanism, in the order met.
	if not state.has_flag("world.guards_clear"):
		return "Passe pelos guardas: ataque quando a arma bater no chão."
	if not state.has_flag("seen.t03"):
		return "Procure a oficina atrás dos guardas."
	if not state.has_flag("world.weight_locked"):
		return "Atravesse o vão com o gancho e prenda o contrapeso."
	if not state.has_flag("world.bells_solved"):
		return "Toque os sinos na ordem da inscrição."
	if not state.has_flag("seen.t11"):
		return "Suba até a câmara de Igris."
	return ""
