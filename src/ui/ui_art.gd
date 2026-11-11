class_name UiArt
extends RefCounted
## The interface art made by tools/art/gerar_interface.py
## (design/gdd/telas-e-mochila.md): the title background and name, the
## backpack and one 24×24 icon per item, plus the panel colours and styles
## shared by every screen. Loaded once and shared. Every
## getter returns null (or a plain style) when the files are missing, so
## screens still work without the art.

const DIR := "res://assets/art/ui/"
## Colours of the user's reference screens.
const PANEL := Color(0.05, 0.08, 0.14, 0.88)
const EDGE := Color("46546e")
const ACCENT := Color("5cc8e0")
const CREAM := Color("f2e6c8")
const TEXT := Color("e8e4da")
const DIM := Color("9ba6b6")
const GOLD := Color("e0b85a")
const LIFE := Color("e8606a")
const LIFE_EMPTY := Color("3a2a34")
const META := DIR + "interface.json"

static var _meta: Dictionary = {}
static var _loaded := false
static var _textures: Dictionary = {}
static var _icons: Dictionary = {}


## interface.json (the backpack grid, icon index...).
static func meta() -> Dictionary:
	if not _loaded:
		_loaded = true
		var f := FileAccess.open(META, FileAccess.READ)
		if f:
			var json := JSON.new()
			if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
				_meta = json.data
	return _meta


## The texture [param file_name] of the UI folder, or null.
static func texture(file_name: String) -> Texture2D:
	if not _textures.has(file_name):
		var path := DIR + file_name
		_textures[file_name] = load(path) if ResourceLoader.exists(path) else null
	return _textures[file_name]


## The game's panel: dark navy, a thin slate edge (the user's screens,
## design/art/referencias/telas-usuario.png).
static func panel_style(padding: float = 10.0) -> StyleBoxFlat:
	var flat := StyleBoxFlat.new()
	flat.bg_color = PANEL
	flat.border_color = EDGE
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(3)
	flat.set_content_margin_all(padding)
	return flat


## The highlight of a picked row or pocket: a teal edge and a faint fill.
static func select_style(padding: float = 2.0) -> StyleBoxFlat:
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(ACCENT, 0.16)
	flat.border_color = ACCENT
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(2)
	flat.set_content_margin_all(padding)
	flat.content_margin_left = padding + 4.0
	return flat


## The 24×24 icon of [param item_id] (a pouch when it has none), or null.
static func icon(item_id: String) -> Texture2D:
	if _icons.has(item_id):
		return _icons[item_id]
	var sheet := texture("itens.png")
	var info: Dictionary = meta().get("itens", {})
	var index: Dictionary = info.get("index", {})
	var out: AtlasTexture = null
	if sheet != null and not index.is_empty():
		var i := int(index.get(item_id, index.get("_generico", 0)))
		var size := int(info.get("size", 24))
		var cols := int(info.get("cols", 8))
		out = AtlasTexture.new()
		out.atlas = sheet
		out.region = Rect2((i % cols) * size, (i / cols) * size, size, size)
	_icons[item_id] = out
	return out
