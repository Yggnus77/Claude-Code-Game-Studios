"""Cenário modular 16×16 e objetos do mundo.

tiles.png: uma linha por tema (oficina, praca, estrada, torre), colunas em
cenario_detalhado.HD_COLS (parede alta de 3 ladrilhos, piso com variações,
móveis, vão, decalques e tapete em 9 peças). decor.png: uma linha por tema,
quadros 16×32 pendurados na parede alta (nomes em "decor" por tema).
objetos.png: quadros 16×32 (pivô [8,24]), colunas em OBJ_COLS.
Guia: design/art/art-bible.md, Seções 6 e 8.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixel import Canvas, sheet  # noqa: E402
import cenario_detalhado as oficina  # noqa: E402
import cenario_estrada as estrada  # noqa: E402
import cenario_praca as praca  # noqa: E402
import cenario_torre as torre  # noqa: E402
import objetos_hd  # noqa: E402

T = 16
THEMES = ["oficina", "praca", "estrada", "torre"]
OBJ_W, OBJ_H = 16, 32
OBJ_PIVOT = (8, 24)
OBJ_COLS = [
    "door_open", "door_closed", "chest", "chest_open", "clue", "npc", "interact",
    "marco", "marco_active", "anchor", "push_block", "fragment", "bell", "bell_lit",
]

def obj(name):
    """Desenho de cada objeto: objetos_hd.py."""
    return objetos_hd.OBJECTS[name]()


# Luz de cada tema: cor ambiente (CanvasModulate) e as luzes que a
# decoração acende: [cor, energia, raio em px, altura da chama no quadro,
# se tremula como chama];
# "motes": [cor, quantidade] da poeira (ou vaga-lumes) flutuando na sala.
LIGHTING = {
    "oficina": {"ambient": "#a49cb4", "decor_lights": {"lamp": ["#ffc074", 1.1, 96, 17, True], "window": ["#8fb0ff", 0.55, 72, 14, False]},
                "furn_light": ["#ffc074", 0.8, 64], "motes": ["#ffe8b0a0", 26]},
    "praca": {"ambient": "#8a94bc", "decor_lights": {"lantern": ["#ffc074", 1.2, 110, 23, True], "window": ["#ffb860", 0.6, 64, 22, False],
                                                      "flowerbox": ["#ffb860", 0.6, 64, 22, False]}, "furn_light": None,
              "motes": ["#c8d8ff60", 14]},
    "estrada": {"ambient": "#7c8ab4", "decor_lights": {"lantern": ["#ffc074", 1.25, 120, 8, True], "fireflies": ["#d8f8a0", 0.4, 40, 18, True]},
                "furn_light": None, "motes": ["#e8f8a0d0", 22]},
    "torre": {"ambient": "#968aae", "decor_lights": {"torch": ["#ffa850", 1.15, 96, 13, True], "brazier": ["#ffa850", 1.25, 110, 15, True],
                                                      "slit": ["#8fb0ff", 0.5, 64, 16, False]}, "furn_light": ["#ffa850", 1.0, 80],
              "motes": ["#ffd0a090", 24]},
}
# Brilho das coisas que se pegam ou ativam: [cor, energia, raio em px].
PICKUP_LIGHTS = {"unique_fragment": ["#6fe0e0", 0.6, 40], "checkpoint": ["#f2c14e", 0.6, 40],
                 "mystery_clue": ["#ffe8a0", 0.5, 30]}
THEME_MODULES = {"oficina": oficina, "praca": praca, "estrada": estrada, "torre": torre}

def theme_tiles(th):
    return oficina.tiles_oficina_hd() if th == "oficina" else THEME_MODULES[th].tiles()

def theme_decor(th):
    if th == "oficina":
        return oficina.OFICINA_DECOR, [oficina.decor(k) for k in oficina.OFICINA_DECOR]
    m = THEME_MODULES[th]
    return m.DECOR, [m.decor(k) for k in m.DECOR]

def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out = os.path.join(root, "assets", "art", "cenario")
    os.makedirs(out, exist_ok=True)
    tiles = []
    decor_frames = []
    decor_names = {}
    for th in THEMES:
        row = theme_tiles(th)
        assert len(row) == len(oficina.HD_COLS), th
        tiles += row
        names, frames = theme_decor(th)
        decor_names[th] = names
        decor_frames += frames
    sheet(tiles, len(oficina.HD_COLS)).save(os.path.join(out, "tiles.png"))
    sheet(decor_frames, len(decor_names["oficina"])).save(os.path.join(out, "decor.png"))
    objs = [obj(n) for n in OBJ_COLS]
    sheet(objs, len(OBJ_COLS)).save(os.path.join(out, "objetos.png"))
    meta = {
        "tile_size": T, "themes": THEMES, "tile_cols": oficina.HD_COLS, "wall_rows": 3,
        "theme_by_room_prefix": {"v00": "oficina", "v": "praca", "r": "estrada", "t": "torre"},
        "decor_size": [T, 32], "decor": decor_names, "lighting": LIGHTING, "pickup_lights": PICKUP_LIGHTS,
        "object_size": [OBJ_W, OBJ_H], "object_pivot": list(OBJ_PIVOT), "object_cols": OBJ_COLS,
    }
    with open(os.path.join(out, "cenario.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    print("tiles", len(tiles), "decor", len(decor_frames), "objetos", len(objs))

if __name__ == "__main__":
    main()
