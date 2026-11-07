"""Cenário modular 16×16 e objetos do mundo.

tiles.png: uma linha por tema (oficina, praca, estrada, torre), colunas em
TILE_COLS. objetos.png: quadros 16×32 (pivô [8,24]), colunas em OBJ_COLS.
Guia: design/art/art-bible.md, Seções 6 e 8.
"""

import json
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixel import Canvas, sheet  # noqa: E402

T = 16
THEMES = ["oficina", "praca", "estrada", "torre"]
TILE_COLS = ["floor_a", "floor_b", "floor_c", "wall_top", "wall_front", "gap", "gap_edge"]

THEME_COLORS = {
    # piso (base, claro, escuro), parede (topo, topo claro, face, face escura), vão
    "oficina": {"floor": ("plank", "wood_hi", "plank_lo"), "wall": ("wood_lo", "wood", "wood", "wood_lo"), "gap": "night"},
    "praca": {"floor": ("cobble", "cobble_hi", "cobble_lo"), "wall": ("stone_lo", "stone", "stone_hi", "stone_lo"), "gap": "water"},
    "estrada": {"floor": ("grass", "grass_hi", "grass_lo"), "wall": ("grass_lo", "grass", "dirt_lo", "wood_lo"), "gap": "night"},
    "torre": {"floor": ("stone", "stone_hi", "stone_lo"), "wall": ("stone_dk", "stone_lo", "stone_lo", "stone_dk"), "gap": "night"},
}


def floor(theme, variant):
    c = Canvas(T, T)
    base, hi, lo = THEME_COLORS[theme]["floor"]
    rnd = random.Random(f"{theme}-{variant}")
    c.rect(0, 0, T, T, base)
    if theme == "oficina":
        # tábuas horizontais de 4 px com juntas desencontradas
        for row in range(4):
            y = row * 4
            c.hline(0, 15, y + 3, lo)
            c.hline(0, 15, y, hi) if row == 0 else None
            j = (row * 5 + variant * 3) % 16
            c.vline(j, y, y + 2, lo)
        if variant == 2:
            c.put(5, 6, "wood_lo")
            c.put(11, 13, "wood_lo")
    elif theme in ("praca", "torre"):
        # pedras em fileiras
        h = 5 if theme == "praca" else 8
        for row in range(0, T, h):
            c.hline(0, 15, row, lo)
            off = (row // h + variant) % 2 * (h // 2 + 2)
            for x in range(off, T, 8 if theme == "praca" else 16):
                c.vline(x, row, row + h - 1, lo)
            for x in range(T):
                if rnd.random() < 0.08:
                    c.put(x, row + 1, hi)
        if theme == "torre" and variant == 2:
            c.rect(6, 10, 3, 2, "stone_lo")
    else:
        # grama com tufos e terra batida
        for _ in range(10 + variant * 3):
            x, y = rnd.randrange(T), rnd.randrange(1, T)
            c.put(x, y, hi)
            c.put(x, y - 1, hi) if rnd.random() < 0.5 else None
        for _ in range(6):
            c.put(rnd.randrange(T), rnd.randrange(T), lo)
        if variant == 2:
            c.rect(3, 9, 9, 4, "dirt")
            c.hline(4, 10, 9, "dirt_hi")
            c.put(6, 11, "dirt_lo")
    return c


def wall_top(theme):
    c = Canvas(T, T)
    top, hi, _, _ = THEME_COLORS[theme]["wall"]
    c.rect(0, 0, T, T, top)
    if theme == "estrada":
        rnd = random.Random("arbusto")
        for _ in range(26):
            x, y = rnd.randrange(T), rnd.randrange(T)
            c.put(x, y, "grass")
        for _ in range(10):
            c.put(rnd.randrange(T), rnd.randrange(T), "grass_hi")
    elif theme == "oficina":
        for x in range(0, T, 4):
            c.vline(x, 0, 15, "wood_lo")
        c.hline(0, 15, 0, hi)
    else:
        c.hline(0, 15, 0, hi)
        c.hline(0, 15, 8, hi)
        c.vline(4, 0, 7, "stone_dk")
        c.vline(12, 8, 15, "stone_dk")
    return c


def wall_front(theme):
    c = Canvas(T, T)
    top, hi, face, dark = THEME_COLORS[theme]["wall"]
    c.rect(0, 0, T, T, face)
    c.hline(0, 15, 0, hi)
    if theme == "oficina":
        for x in range(0, T, 4):
            c.vline(x, 1, 15, dark)
        c.hline(0, 15, 12, "wood_lo")
        c.hline(0, 15, 15, "outline")
    elif theme == "estrada":
        # barranco de terra com raízes
        c.rect(0, 0, T, 3, "grass")
        c.hline(0, 15, 3, "grass_lo")
        c.rect(0, 4, T, 12, "dirt_lo")
        for x in (2, 7, 12):
            c.vline(x, 5, 9, "wood_lo")
        c.hline(0, 15, 15, "outline")
    else:
        for row in (1, 6, 11):
            c.hline(0, 15, row + 4, dark)
            off = 0 if row % 2 else 4
            for x in range(off, T, 8):
                c.vline(x, row, row + 3, dark)
        c.hline(0, 15, 15, "outline")
        if theme == "torre":
            c.put(3, 3, "stone_hi")
            c.put(11, 8, "stone_hi")
    return c


def gap(theme, edge):
    c = Canvas(T, T)
    col = THEME_COLORS[theme]["gap"]
    c.rect(0, 0, T, T, col)
    if theme == "praca":
        rnd = random.Random("agua")
        for _ in range(5):
            x, y = rnd.randrange(T - 3), rnd.randrange(T)
            c.hline(x, x + 2, y, "water_hi")
    else:
        rnd = random.Random("vazio")
        for _ in range(3):
            c.put(rnd.randrange(T), rnd.randrange(T), "stone_dk")
    if edge:
        base, hi, lo = THEME_COLORS[theme]["floor"]
        c.rect(0, 0, T, 4, lo)
        c.hline(0, 15, 4, "outline")
        c.hline(0, 15, 5, "#00000080")
    return c


# ---------------------------------------------------------------- objetos

OBJ_W, OBJ_H = 16, 32
OBJ_PIVOT = (8, 24)
OBJ_COLS = [
    "door_open", "door_closed", "chest", "chest_open", "clue", "npc", "interact",
    "marco", "marco_active", "anchor", "push_block", "fragment", "bell", "bell_lit",
]


def obj(name):
    c = Canvas(OBJ_W, OBJ_H)
    py = OBJ_PIVOT[1]          # centro do ladrilho
    if name.startswith("door"):
        c.rect(1, py - 15, 14, 22, "wood_lo")
        c.rect(2, py - 14, 12, 21, "stone_dk" if name == "door_open" else "wood")
        if name == "door_closed":
            for x in (5, 9):
                c.vline(x, py - 14, py + 6, "wood_lo")
            c.hline(2, 13, py - 9, "brass_lo")
            c.hline(2, 13, py + 1, "brass_lo")
            c.put(11, py - 4, "brass_hi")
        else:
            c.rect(3, py - 13, 10, 19, "night")
            c.hline(3, 12, py + 6, "lamp")             # luz do outro lado
        c.ellipse(7, py - 15, 6, 2, "wood_lo")
    elif name.startswith("chest"):
        c.rect(1, py - 5, 14, 10, "wood")
        c.hline(1, 14, py - 1, "brass")
        c.vline(1, py - 5, py + 4, "brass_lo")
        c.vline(14, py - 5, py + 4, "brass_lo")
        c.hline(2, 13, py + 4, "wood_lo")
        if name == "chest":
            c.rect(1, py - 9, 14, 4, "wood_hi")
            c.hline(1, 14, py - 9, "brass_hi")
            c.rect(7, py - 3, 2, 3, "brass_hi")
        else:
            c.rect(1, py - 13, 14, 4, "wood_lo")       # tampa aberta para trás
            c.rect(2, py - 5, 12, 3, "outline")
    elif name == "clue":
        c.rect(4, py - 3, 8, 7, "cloth")
        c.hline(5, 10, py - 1, "cloth_lo")
        c.hline(5, 9, py + 1, "cloth_lo")
        c.put(11, py - 3, "cloth_lo")
        # "?" dourado sobre o papel: pista de mistério
        for x, y in ((6, py - 14), (7, py - 15), (8, py - 15), (9, py - 14), (9, py - 13), (8, py - 12), (7, py - 11), (7, py - 9)):
            c.put(x, y, "lamp_hi")
    elif name == "npc":
        c.rect(4, py - 10, 8, 13, "robe")
        c.vline(4, py - 10, py + 2, "robe_hi")
        c.rect(5, py - 17, 6, 7, "skin")
        c.rect(4, py - 19, 8, 3, "hair_hi")
        c.put(6, py - 14, "outline")
        c.put(9, py - 14, "outline")
        c.rect(5, py + 3, 2, 2, "boot")
        c.rect(9, py + 3, 2, 2, "boot")
    elif name == "interact":
        # placa de pedra clara com losango azul: "examine aqui"
        c.rect(3, py - 9, 10, 13, "cobble_hi")
        c.vline(12, py - 9, py + 3, "cobble_lo")
        c.hline(3, 12, py + 3, "cobble_lo")
        for i in range(4):
            c.hline(8 - i, 7 + i, py - 7 + i, "safe")
            c.hline(8 - i, 7 + i, py - 0 - i, "safe")
        c.put(7, py - 5, "white")
    elif name.startswith("marco"):
        # Marco de Memória: pilar de pedra clara com cristal
        c.rect(4, py - 14, 8, 18, "cobble_hi")
        c.vline(4, py - 14, py + 3, "white")
        c.vline(11, py - 14, py + 3, "cobble_lo")
        c.rect(2, py + 2, 12, 3, "cobble_lo")
        c.hline(4, 11, py - 14, "white")
        lit = name == "marco_active"
        c.rect(6, py - 10, 4, 6, "crystal" if lit else "stone_dk")
        c.rect(7, py - 9, 1, 3, "crystal_hi" if lit else "stone_lo")
        c.hline(5, 10, py - 3, "gold_lo")
        if lit:
            for x, y in ((3, py - 17), (12, py - 16), (8, py - 20)):
                c.put(x, y, "crystal_hi")
    elif name == "anchor":
        # argola de gancho: anel duplo de latão na parede
        c.rect(6, py - 2, 4, 6, "stone_dk")
        c.ellipse(7, py - 5, 5, 5, "brass")
        c.ellipse(7, py - 5, 3, 3, "#00000000")
        c.ellipse(7, py - 5, 1, 1, "brass_hi")
        c.put(7, py - 10, "brass_hi")
    elif name == "push_block":
        # bloco de granito claro com cintas de latão (contrasta com todo piso)
        c.rect(1, py - 9, 14, 14, "cobble_hi")
        c.hline(1, 14, py - 9, "white")
        c.rect(1, py + 1, 14, 4, "cobble_lo")
        c.hline(1, 14, py - 4, "brass")
        c.vline(7, py - 8, py, "cobble")
        c.ellipse(7, py - 12, 2, 2, "brass")           # argola de puxar
        c.put(7, py - 12, "#00000000")
    elif name == "fragment":
        for i in range(5):
            c.hline(8 - i, 7 + i, py - 8 + i, "crystal")
            c.hline(8 - i, 7 + i, py + 2 - i, "crystal")
        c.vline(7, py - 7, py + 1, "crystal_hi")
    elif name.startswith("bell"):
        lit = name == "bell_lit"
        c.hline(2, 13, py - 16, "wood_lo")
        c.vline(7, py - 15, py - 13, "brass_lo")
        for i in range(10):
            w = 2 + i * 5 // 10
            c.hline(8 - w, 7 + w, py - 13 + i, "brass_hi" if lit else "brass")
        c.hline(2, 13, py - 3, "brass_lo")
        c.ellipse(7, py - 1, 1, 1, "brass_lo")
        c.vline(5, py - 11, py - 6, "lamp_hi" if lit else "brass_hi")
    c.outline()
    return c


def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out = os.path.join(root, "assets", "art", "cenario")
    os.makedirs(out, exist_ok=True)
    tiles = []
    for th in THEMES:
        tiles += [floor(th, 0), floor(th, 1), floor(th, 2), wall_top(th), wall_front(th), gap(th, False), gap(th, True)]
    sheet(tiles, len(TILE_COLS)).save(os.path.join(out, "tiles.png"))
    objs = [obj(n) for n in OBJ_COLS]
    sheet(objs, len(OBJ_COLS)).save(os.path.join(out, "objetos.png"))
    meta = {
        "tile_size": T, "themes": THEMES, "tile_cols": TILE_COLS,
        "theme_by_room_prefix": {"v00": "oficina", "v": "praca", "r": "estrada", "t": "torre"},
        "object_size": [OBJ_W, OBJ_H], "object_pivot": list(OBJ_PIVOT), "object_cols": OBJ_COLS,
    }
    with open(os.path.join(out, "cenario.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    print("tiles", len(tiles), "objetos", len(objs))


if __name__ == "__main__":
    main()
