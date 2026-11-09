class_name Breakables
extends RefCounted
## Rules for bushes and pots (design/gdd/exploracao.md §2), read from
## assets/data/exploracao.json: which kinds exist, whether they block the
## way, what is left behind and the weighted drop table.

const PATH := "res://assets/data/exploracao.json"

## kind -> definition ({"solid", "stub", "fx_color", "drops"}).
var kinds: Dictionary = {}
## Seconds a dropped life drop stays before fading.
var life_lifetime := 12.0
## Seconds the screen takes to slide between rooms (exploração §1).
var slide_time := 0.55


## Loads [param path]; a missing or broken file gives no breakable kinds.
static func load_from(path: String = PATH) -> Breakables:
	var b := Breakables.new()
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if parsed is Dictionary:
		var kinds_in: Variant = (parsed as Dictionary).get("breakables", {})
		if kinds_in is Dictionary:
			b.kinds = kinds_in
		var life: Variant = (parsed as Dictionary).get("life_drop", {})
		if life is Dictionary:
			b.life_lifetime = float((life as Dictionary).get("lifetime", b.life_lifetime))
		var slide: Variant = (parsed as Dictionary).get("slide_time", b.slide_time)
		if slide is float or slide is int:
			b.slide_time = clampf(float(slide), 0.05, 2.0)
	return b


func has_kind(kind: String) -> bool:
	return kinds.has(kind)


func is_solid(kind: String) -> bool:
	return bool((kinds.get(kind, {}) as Dictionary).get("solid", true))


## Object column left on the ground after breaking ("" none).
func stub(kind: String) -> String:
	return str((kinds.get(kind, {}) as Dictionary).get("stub", ""))


func fx_color(kind: String) -> Color:
	return Color.from_string(str((kinds.get(kind, {}) as Dictionary).get("fx_color", "#ffffff")), Color.WHITE)


## Picks a drop id ("none", "vida_1", "bronze_5"…) by weight, using
## [param roll] in [0, 1) so tests can choose the outcome.
func drop_for(kind: String, roll: float) -> String:
	var table: Variant = (kinds.get(kind, {}) as Dictionary).get("drops", [])
	if not table is Array:
		return "none"
	var total := 0.0
	for row: Variant in table:
		if row is Array and (row as Array).size() == 2:
			total += maxf(0.0, float(row[1]))
	if total <= 0.0:
		return "none"
	var at := clampf(roll, 0.0, 0.999999) * total
	for row: Variant in table:
		if row is Array and (row as Array).size() == 2:
			at -= maxf(0.0, float(row[1]))
			if at < 0.0:
				return str(row[0])
	return "none"


## Life restored by a drop id like "vida_1" (0 when it is not life).
static func life_amount(drop_id: String) -> int:
	if not drop_id.begins_with("vida_"):
		return 0
	return maxi(0, int(drop_id.trim_prefix("vida_")))
