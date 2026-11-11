class_name PlaytestLog
extends RefCounted
## What the playtest of Etapa 10 needs written down, recorded by the game
## itself (design/kit/plano-implementacao.md, Etapa 10;
## mecanicas-e-dificuldade.md §13): deaths per room and their cause, time
## to learn sword, guard and hook, Igris attempts and their length, commands
## that did nothing, room resets, and the time to finish the slice.
##
## Pure: the game passes the clock in. [method summary] is the text the
## person running the test reads after the session; [method to_dict] the
## same data as JSON.

## First-time skills timed from the session start (§13).
const SKILLS := {
	"espada": "Primeiro golpe de espada que acertou",
	"defesa": "Primeira defesa (escudo segurou um golpe)",
	"giro": "Primeiro giro da espada (segurar e soltar)",
	"gancho": "Primeira travessia com o gancho",
}

var started_at := ""
var events: Array = []
var deaths: Dictionary = {}
var firsts: Dictionary = {}
var refused: Dictionary = {}
var resets: Dictionary = {}
var rooms_seen: Array = []
## Every room entry in order: [{"room", "t"}] (time per room, backtracking).
var room_visits: Array = []
## Hits that did damage without killing, per cause.
var hits: Dictionary = {}
var igris_attempts: Array = []
var finished_at := -1.0
var _attempt_started := -1.0


func _init(start_stamp: String = "") -> void:
	started_at = start_stamp


## Yggnus entered [param room_id] at [param t] seconds (every entry).
func room(t: float, room_id: String) -> void:
	room_visits.append({"room": room_id, "t": snappedf(t, 0.1)})
	if not rooms_seen.has(room_id):
		rooms_seen.append(room_id)
	_event(t, "sala", room_id)


## Yggnus took damage from [param cause] and survived.
func hit(t: float, cause: String) -> void:
	hits[cause] = int(hits.get(cause, 0)) + 1
	_event(t, "golpe", cause)


## Yggnus died in [param room_id]; [param cause] names what hit last.
func death(t: float, room_id: String, cause: String) -> void:
	var per_room: Dictionary = deaths.get(room_id, {})
	per_room[cause] = int(per_room.get(cause, 0)) + 1
	deaths[room_id] = per_room
	_event(t, "morte", "%s (%s)" % [room_id, cause])


## First use of [param skill] (a key of [constant SKILLS]); later ones are ignored.
func first(t: float, skill: String) -> void:
	if not firsts.has(skill):
		firsts[skill] = t
		_event(t, "aprendeu", skill)


## A command that did nothing: [param what] is what the player tried.
func refuse(t: float, what: String) -> void:
	refused[what] = int(refused.get(what, 0)) + 1
	_event(t, "sem efeito", what)


## The room reset key was used (often a sign of being stuck).
func reset(t: float, room_id: String) -> void:
	resets[room_id] = int(resets.get(room_id, 0)) + 1
	_event(t, "reiniciou", room_id)


func igris_start(t: float) -> void:
	_attempt_started = t
	_event(t, "Igris", "tentativa %d" % (igris_attempts.size() + 1))


## The Igris attempt ended: [param result] is "vitória", "morte" or "saiu".
func igris_end(t: float, result: String) -> void:
	if _attempt_started < 0.0:
		return
	igris_attempts.append({"result": result, "seconds": snappedf(t - _attempt_started, 0.1)})
	_attempt_started = -1.0
	_event(t, "Igris", result)


## The slice ended (back in Exódia's workshop after Igris).
func finish(t: float) -> void:
	if finished_at < 0.0:
		finished_at = t
		_event(t, "fim", "fatia concluída")


func _event(t: float, kind: String, detail: String) -> void:
	events.append({"t": snappedf(t, 0.1), "kind": kind, "detail": detail})


func to_dict() -> Dictionary:
	return {
		"started_at": started_at, "finished_at": finished_at, "deaths": deaths, "firsts": firsts,
		"refused": refused, "resets": resets, "rooms_seen": rooms_seen,
		"igris_attempts": igris_attempts, "room_visits": room_visits, "hits": hits, "events": events,
	}


## The session in plain Portuguese, for the observer's sheet.
func summary(t: float) -> String:
	var out := PackedStringArray()
	out.append("SESSÃO DE TESTE — %s" % started_at)
	out.append("Duração: %s" % clock(t))
	out.append("Fatia concluída: %s" % (clock(finished_at) if finished_at >= 0.0 else "não"))
	out.append("")
	out.append("APRENDIZADO (tempo desde o início)")
	for skill in SKILLS:
		out.append("- %s: %s" % [SKILLS[skill], clock(firsts[skill]) if firsts.has(skill) else "não aconteceu"])
	out.append("")
	var total := 0
	for r in deaths:
		for c in deaths[r]:
			total += int(deaths[r][c])
	out.append("MORTES: %d" % total)
	for r in deaths:
		var parts := PackedStringArray()
		for c in deaths[r]:
			parts.append("%s ×%d" % [c, deaths[r][c]])
		out.append("- %s: %s" % [r, ", ".join(parts)])
	out.append("")
	out.append("GOLPES RECEBIDOS (sem morrer)")
	if hits.is_empty():
		out.append("- nenhum")
	for c in hits:
		out.append("- %s: %d" % [c, hits[c]])
	out.append("")
	out.append("IGRIS: %d tentativa(s)" % igris_attempts.size())
	for i in igris_attempts.size():
		var a: Dictionary = igris_attempts[i]
		out.append("- %d: %s em %s" % [i + 1, a["result"], clock(float(a["seconds"]))])
	if _attempt_started >= 0.0:
		out.append("- %d: em andamento há %s" % [igris_attempts.size() + 1, clock(t - _attempt_started)])
	out.append("")
	out.append("COMANDOS SEM EFEITO")
	if refused.is_empty():
		out.append("- nenhum")
	for what in refused:
		out.append("- %s: %d vez(es)" % [what, refused[what]])
	if not resets.is_empty():
		out.append("")
		out.append("SALA REINICIADA (R)")
		for r in resets:
			out.append("- %s: %d vez(es)" % [r, resets[r]])
	out.append("")
	out.append("SALAS (chegada e tempo em cada uma)")
	for i in room_visits.size():
		var v: Dictionary = room_visits[i]
		var until: float = float(room_visits[i + 1]["t"]) if i + 1 < room_visits.size() else t
		out.append("- %s %s: %s" % [clock(float(v["t"])), v["room"], clock(until - float(v["t"]))])
	return "\n".join(out)


## 125.4 → "2 min 05 s".
static func clock(seconds: float) -> String:
	var s := floori(seconds)
	return "%d min %02d s" % [floori(s / 60.0), s % 60]
