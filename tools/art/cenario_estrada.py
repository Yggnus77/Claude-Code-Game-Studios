"""Estrada fora da vila, à noite: capim, trilha de terra batida, a orla da
mata (copas, troncos e arbustos), pedras grandes e um barranco escuro.
Colunas em cenario_detalhado.HD_COLS; decoração 16×32 em DECOR.
"""

import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from cenario_detalhado import RUG_PARTS, T, P  # noqa: E402

PAL = {
    "grass": "#3f5a33", "grass_hi": "#557540", "grass_lo": "#30472a", "grass_tip": "#6f9050",
    "dirt": "#7a5e44", "dirt_hi": "#94765a", "dirt_lo": "#5e4734", "pebble": "#a39886",
    "leaf": "#2c4428", "leaf_hi": "#40603a", "leaf_lo": "#1e3020", "leaf_dk": "#14201a", "leaf_top": "#58784a",
    "bark": "#4a3426", "bark_hi": "#644636", "bark_lo": "#2e2018",
    "rock": "#6a6670", "rock_hi": "#868290", "rock_lo": "#4a4652", "rock_dk": "#33303a",
    "moss": "#4f6a3e", "moss_hi": "#6b8a4a",
    "void": "#0c0d14", "void_lo": "#151722", "root": "#3a2a20",
    "white": "#ece6d4", "yellow": "#e8c050", "blue": "#7a9ad8", "red": "#c0443c", "mush": "#c8a07a",
    "iron": "#2a2630", "iron_hi": "#4a4452", "flame": "#ffd27a", "flame_hi": "#fff2c0",
    "wood": "#7a5236", "wood_hi": "#9c6c45", "wood_lo": "#523522",
    "firefly": "#e8f8a0",
}


def floor(variant):
    t = P(PAL)
    t.r(0, 0, T, T, "grass")
    rnd = random.Random(f"capim-{variant}")
    for _ in range(14):
        x, y = rnd.randrange(T), rnd.randrange(T)
        t.p(x, y, rnd.choice(["grass_hi", "grass_lo", "grass_lo"]))
    for _ in range(2 + variant):
        x, y = rnd.randrange(T), rnd.randrange(2, T)
        t.p(x, y, "grass_hi")
        t.p(x, y - 1, "grass_tip")
    if variant == 2:     # chão batido
        for x, y in ((6, 9), (7, 9), (8, 10), (9, 10), (7, 10)):
            t.p(x, y, "grass_lo")
        t.p(8, 9, "dirt_lo")
    elif variant == 3:   # florzinhas
        for x, y, col in ((4, 5, "white"), (11, 9, "yellow"), (7, 13, "white")):
            t.p(x, y, col)
            t.p(x, y + 1, "grass_tip")
    return t.c


def canopy(t, y0, y1, seed):
    rnd = random.Random(seed)
    for y in range(y0, y1):
        for x in range(T):
            t.p(x, y, "leaf")
    for _ in range(int((y1 - y0) * 4)):
        x, y = rnd.randrange(T), rnd.randrange(y0, y1)
        cx = rnd.randrange(2, 4)
        t.disc(x, y, cx, "leaf_hi", 1)
        t.p(x, y - 1, "leaf_top")
    for _ in range(int((y1 - y0) * 2)):
        t.p(rnd.randrange(T), rnd.randrange(y0, y1), "leaf_lo")


def wall_upper():
    """Copas das árvores."""
    t = P(PAL)
    canopy(t, 0, T, "copa")
    return t.c


def wall_mid():
    """Base das copas e troncos."""
    t = P(PAL)
    t.r(0, 0, T, T, "leaf_dk")
    for x0 in (2, 10):
        t.r(x0, 6, 4, 10, "bark")
        t.vl(x0, 6, 15, "bark_hi")
        t.vl(x0 + 3, 6, 15, "bark_lo")
        t.p(x0 + 1, 10, "bark_lo")
    canopy(t, 0, 7, "copa-baixa")
    for x in range(0, T, 3):
        t.p(x, 7, "leaf_lo")
    return t.c


def wall_lower():
    """Arbustos e raízes na beira da mata."""
    t = P(PAL)
    t.r(0, 0, T, T, "leaf_dk")
    for x0 in (2, 10):
        t.r(x0, 0, 4, 9, "bark")
        t.vl(x0, 0, 8, "bark_hi")
        t.vl(x0 + 3, 0, 8, "bark_lo")
        t.line(x0, 8, x0 - 2, 11, "root")
        t.line(x0 + 3, 8, x0 + 5, 11, "root")
    rnd = random.Random("arbusto")
    for _ in range(14):
        x, y = rnd.randrange(T), rnd.randrange(8, 15)
        t.disc(x, y, 2, rnd.choice(["leaf", "leaf_hi"]), 1)
    t.hl(0, 15, 15, "leaf_dk")
    t.p(4, 12, "white")
    t.p(12, 11, "yellow")
    return t.c


def wall_top():
    """Moita fechada vista de cima (bordas laterais e de baixo)."""
    t = P(PAL)
    canopy(t, 0, T, "moita")
    for x, y in ((3, 4), (12, 11)):
        t.p(x, y, "leaf_dk")
    return t.c


def furn_top(variant):
    """Pedra grande vista de cima, com musgo."""
    t = P(PAL)
    t.r(0, 0, T, T, "rock")
    rnd = random.Random(f"rocha-{variant}")
    for _ in range(14):
        t.p(rnd.randrange(T), rnd.randrange(T), rnd.choice(["rock_hi", "rock_lo"]))
    t.hl(0, 15, 0, "rock_hi")
    t.line(rnd.randrange(3, 8), 3, rnd.randrange(8, 13), 9, "rock_lo")
    for _ in range(4 + variant * 2):
        x, y = rnd.randrange(T), rnd.randrange(T)
        t.p(x, y, "moss")
        t.p(x + 1, y, "moss_hi")
    if variant == 3:
        t.p(7, 6, "mush")
        t.p(8, 6, "red")
    return t.c


def furn_front():
    t = P(PAL)
    t.r(0, 0, T, T, "rock_lo")
    t.hl(0, 15, 0, "rock")
    t.hl(0, 15, 1, "rock")
    for x, y in ((3, 4), (9, 7), (13, 3), (6, 10)):
        t.line(x, y, x + 2, y + 2, "rock_dk")
    t.r(0, 12, T, 4, "rock_dk")
    for x in range(0, T, 4):
        t.vl(x + 1, 12, 15, "grass_lo")
        t.p(x + 2, 12, "grass_hi")
    return t.c


def gap(edge):
    """Barranco escuro."""
    t = P(PAL)
    t.r(0, 0, T, T, "void")
    rnd = random.Random("vao")
    for _ in range(4):
        t.p(rnd.randrange(T), rnd.randrange(T), "void_lo")
    if edge:
        t.r(0, 0, T, 4, "dirt_lo")
        t.hl(0, 15, 0, "grass")
        t.hl(0, 15, 1, "grass_lo")
        for x in range(1, T, 4):
            t.vl(x, 4, 6, "root")
        t.hl(0, 15, 4, "#00000080")
    return t.c


def decals():
    out = []
    d = P(PAL)
    for x, y, k in ((5, 6, "pebble"), (6, 6, "rock_lo"), (10, 10, "pebble"), (8, 12, "pebble")):
        d.p(x, y, k)
    out.append(d.c)
    d = P(PAL)                      # cogumelos
    for x in (6, 9):
        d.hl(x - 1, x + 1, 8, "red" if x == 6 else "mush")
        d.p(x, 9, "white")
        d.p(x, 10, "white")
    d.p(6, 8, "white")
    out.append(d.c)
    d = P(PAL)                      # flores do campo
    for x, y, k in ((4, 6, "blue"), (7, 9, "white"), (11, 5, "yellow"), (10, 11, "blue")):
        d.p(x, y, k)
        d.p(x, y + 1, "grass_tip")
    out.append(d.c)
    d = P(PAL)                      # galho caído
    d.line(3, 10, 12, 7, "bark")
    d.line(3, 11, 12, 8, "bark_lo")
    d.line(8, 9, 10, 12, "bark")
    out.append(d.c)
    return out


def path_piece(part):
    """Trilha de terra batida com bordas de capim irregulares."""
    t = P(PAL)
    t.r(0, 0, T, T, "dirt")
    rnd = random.Random(f"trilha-{part}")
    for _ in range(12):
        t.p(rnd.randrange(T), rnd.randrange(T), rnd.choice(["dirt_hi", "dirt_lo", "pebble"]))
    for y in (5, 10):               # marcas de roda
        for x in range(T):
            if (x + y) % 5:
                t.p(x, y, "dirt_lo")
    top, bot = part.startswith("t"), part.startswith("b")
    left, right = part.endswith("l"), part.endswith("r")
    for i in range(T):
        j = 1 + (i * 7) % 3
        if top:
            t.vl(i, 0, j, "grass")
            t.p(i, j + 1, "grass_lo")
        if bot:
            t.vl(i, 15 - j, 15, "grass")
            t.p(i, 15 - j - 1, "dirt_hi")
        if left:
            t.hl(0, j, i, "grass")
        if right:
            t.hl(15 - j, 15, i, "grass")
    return t.c


def tiles():
    out = [wall_upper(), wall_mid(), wall_lower(), floor(0), floor(1), floor(2), floor(3), wall_top(),
           furn_top(0), furn_top(1), furn_top(2), furn_top(3), furn_front(), gap(False), gap(True)]
    out += decals()
    out += [path_piece(p) for p in RUG_PARTS]
    return out


DECOR = ["lantern", "sign", "tree", "fireflies", "fence", "stone"]


def decor(kind):
    """Coisas na orla da mata, 16×32: y 0–15 copas, 16–31 troncos."""
    t = P(PAL, T, 32)
    if kind == "lantern":           # poste de lampião da estrada
        t.r(7, 12, 3, 20, "wood")
        t.vl(7, 12, 31, "wood_hi")
        t.vl(9, 12, 31, "wood_lo")
        t.hl(5, 11, 11, "iron")
        t.r(5, 5, 7, 6, "iron")
        t.r(6, 6, 5, 4, "flame")
        t.p(8, 7, "flame_hi")
        t.p(8, 8, "flame_hi")
        t.hl(5, 11, 4, "iron_hi")
        t.p(8, 3, "iron")
    elif kind == "sign":            # placa indicando a vila
        t.r(7, 18, 2, 14, "wood_lo")
        t.r(2, 18, 12, 5, "wood")
        t.hl(2, 13, 18, "wood_hi")
        t.p(14, 20, "wood")
        t.p(15, 20, "wood")
        t.hl(4, 11, 20, "wood_lo")
    elif kind == "tree":            # tronco grosso com galho
        t.r(4, 14, 8, 18, "bark")
        t.vl(4, 14, 31, "bark_hi")
        t.vl(11, 14, 31, "bark_lo")
        for y in (17, 22, 27):
            t.hl(6, 9, y, "bark_lo")
        t.line(11, 18, 15, 14, "bark")
        t.disc(8, 8, 7, "leaf_hi", 6)
        t.disc(8, 7, 5, "leaf_top", 3)
        t.p(5, 25, "moss")
        t.p(6, 26, "moss_hi")
    elif kind == "fireflies":
        for x, y in ((3, 18), (9, 14), (12, 22), (6, 26), (13, 12)):
            t.p(x, y, "firefly")
    elif kind == "fence":
        for x in (2, 13):
            t.r(x, 20, 2, 12, "wood")
            t.p(x, 20, "wood_hi")
        for y in (23, 27):
            t.hl(1, 15, y, "wood")
            t.hl(1, 15, y + 1, "wood_lo")
    elif kind == "stone":           # marco de pedra antigo
        t.r(4, 18, 8, 14, "rock")
        t.hl(5, 10, 17, "rock_hi")
        t.vl(4, 18, 31, "rock_hi")
        t.vl(11, 18, 31, "rock_lo")
        t.vl(8, 21, 26, "rock_dk")
        t.hl(6, 10, 23, "rock_dk")
        t.p(5, 30, "moss")
        t.p(10, 29, "moss_hi")
    return t.c
