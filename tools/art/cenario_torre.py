"""Torre do Relógio: lajes de pedra, muralha de blocos com cornija,
blocos de pedra com latão, braseiros, estandartes roxos de Igris e um
abismo com bordas quebradas. Colunas em cenario_detalhado.HD_COLS.
"""

import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from cenario_detalhado import RUG_PARTS, T, P, rug_piece  # noqa: E402

PAL = {
    "slab": "#57505f", "slab_hi": "#5e5667", "slab_lo": "#4d4655", "joint": "#3a3443", "slab_top": "#665e70",
    "brick": "#4e4559", "brick_hi": "#645a70", "brick_lo": "#3a3344", "brick_dk": "#28222f",
    "cornice": "#6e6479", "cornice_hi": "#8a809a",
    "moss": "#4a5e46", "moss_hi": "#647a5a",
    "brass": "#b8873a", "brass_hi": "#e0b555", "brass_lo": "#7d5a26",
    "robe": "#4a3566", "robe_hi": "#634a85", "robe_lo": "#33244a", "gold": "#d4a849",
    "iron": "#2a2630", "iron_hi": "#4a4452",
    "flame": "#ffb84a", "flame_hi": "#fff0b0", "ember": "#e0603a", "coal": "#3a2020",
    "void": "#09080e", "void_lo": "#14111c",
    "glass": "#22325e", "glass_hi": "#4a6aa8", "moon": "#c9d8f0",
    "bone": "#d8ccb4", "fringe": "#d4a849",
}


def floor(variant):
    """Lajes 8×8 desencontradas, cantos gastos."""
    t = P(PAL)
    t.r(0, 0, T, T, "slab")
    rnd = random.Random(f"laje-{variant}")
    for by in (0, 8):
        off = 0 if by == 0 else 4
        t.hl(0, 15, by, "joint")
        for x in range(off, T + 8, 8):
            t.vl(x % T, by, by + 7, "joint")
            t.hl(x % T + 1, x % T + 6, by + 1, "slab_top")
            t.vl(x % T + 1, by + 2, by + 6, "slab_hi")
            t.hl(x % T + 1, x % T + 7, by + 7, "slab_lo")
    for _ in range(6):
        t.p(rnd.randrange(T), rnd.randrange(T), rnd.choice(["slab_lo", "slab_hi"]))
    if variant == 1:     # rachadura
        t.line(3, 3, 6, 6, "joint")
        t.line(6, 6, 6, 9, "joint")
    elif variant == 2:   # musgo nas juntas
        for x, y in ((4, 8), (5, 8), (12, 0), (12, 1), (0, 12)):
            t.p(x, y, "moss")
        t.p(5, 9, "moss_hi")
    elif variant == 3:   # runa de latão incrustada
        t.disc(8, 8, 3, "brass_lo")
        t.disc(8, 8, 2, "slab")
        t.p(8, 8, "brass")
        for dx, dy in ((0, -3), (3, 0), (0, 3), (-3, 0)):
            t.p(8 + dx, 8 + dy, "slab_lo")
    return t.c


def bricks(t, y0, y1, seed):
    for y in range(y0, y1):
        for x in range(T):
            t.p(x, y, "brick")
    rnd = random.Random(seed)
    for row, y in enumerate(range(y0, y1, 5)):
        t.hl(0, 15, y, "brick_dk")
        if y + 1 < y1:
            t.hl(0, 15, y + 1, "brick_hi")
        off = 0 if row % 2 == 0 else 4
        for x in range(off, T, 8):
            t.vl(x, y, min(y + 4, y1 - 1), "brick_dk")
            t.vl(x + 1, y + 1, min(y + 4, y1 - 1), "brick_hi")
        for _ in range(3):
            t.p(rnd.randrange(T), rnd.randrange(y, min(y + 5, y1)), "brick_lo")


def wall_upper():
    """Cornija de pedra no alto da muralha."""
    t = P(PAL)
    bricks(t, 6, T, "alto")
    t.r(0, 0, T, 5, "cornice")
    t.hl(0, 15, 0, "cornice_hi")
    t.hl(0, 15, 4, "brick_dk")
    for x in range(1, T, 4):
        t.r(x, 5, 2, 1, "cornice")
        t.p(x, 6, "brick_dk")
    return t.c


def wall_mid():
    t = P(PAL)
    bricks(t, 0, T, "meio")
    return t.c


def wall_lower():
    """Rodapé de blocos grandes e musgo."""
    t = P(PAL)
    bricks(t, 0, 7, "baixo")
    t.r(0, 7, T, 9, "brick_lo")
    t.hl(0, 15, 7, "cornice")
    t.hl(0, 15, 8, "brick_hi")
    t.vl(7, 9, 15, "brick_dk")
    t.hl(0, 15, 15, "brick_dk")
    for x, y in ((2, 14), (3, 14), (11, 13), (12, 14)):
        t.p(x, y, "moss")
    t.p(3, 13, "moss_hi")
    return t.c


def wall_top():
    """Topo do parapeito visto de cima (laterais e base)."""
    t = P(PAL)
    t.r(0, 0, T, T, "brick_lo")
    for y in (0, 8):
        t.hl(0, 15, y, "brick_dk")
        t.hl(0, 15, y + 1, "brick")
        off = 0 if y == 0 else 8
        t.vl(off, y, y + 7, "brick_dk")
    t.p(4, 4, "brick")
    t.p(12, 12, "brick")
    return t.c


def furn_top(variant):
    """Bloco de pedra com friso de latão; d tem um braseiro aceso."""
    t = P(PAL)
    t.r(0, 0, T, T, "slab_hi")
    t.hl(0, 15, 0, "cornice_hi")
    t.hl(0, 15, 15, "slab_lo")
    t.r(2, 2, 12, 12, "slab")
    t.hl(2, 13, 2, "slab_top")
    rnd = random.Random(f"bloco-{variant}")
    if variant == 0:
        t.hl(1, 14, 1, "brass")
        t.hl(1, 14, 14, "brass_lo")
    elif variant == 1:
        for x in (4, 11):
            t.p(x, 4, "brass_hi")
            t.p(x, 11, "brass")
    elif variant == 2:
        t.line(4, 5, 10, 11, "joint")
        t.p(5, 11, "moss")
        t.p(6, 11, "moss_hi")
    else:
        t.disc(8, 8, 5, "iron")
        t.disc(8, 8, 4, "coal")
        t.disc(8, 8, 3, "ember")
        t.disc(8, 7, 2, "flame")
        t.p(8, 7, "flame_hi")
        t.p(7, 6, "flame_hi")
    for _ in range(3):
        t.p(rnd.randrange(3, 13), rnd.randrange(3, 13), "slab_lo")
    return t.c


def furn_front():
    t = P(PAL)
    t.r(0, 0, T, T, "brick_lo")
    t.hl(0, 15, 0, "slab_hi")
    t.hl(0, 15, 1, "brass")
    t.hl(0, 15, 2, "brass_lo")
    for x in (3, 12):
        t.vl(x, 4, 13, "brick_dk")
        t.vl(x + 1, 4, 13, "brick")
    t.disc(8, 8, 2, "brass_lo")
    t.p(8, 8, "brass_hi")
    t.hl(0, 15, 15, "brick_dk")
    return t.c


def gap(edge):
    """Abismo: escuridão com névoa roxa subindo de longe."""
    t = P(PAL)
    t.r(0, 0, T, T, "void")
    for y in range(T):
        for x in range(T):
            if (x * 7 + y * 3) % 11 == 0 and y > 5:
                t.p(x, y, "void_lo")
            if (x * 5 + y * 13) % 29 == 0:
                t.p(x, y, "#231c30")
    if edge:
        t.r(0, 0, T, 3, "slab_lo")
        t.hl(0, 15, 0, "slab")
        for x in range(0, T, 5):
            t.r(x + 1, 3, 2, 2, "brick_dk")
        t.hl(0, 15, 3, "joint")
        for y in range(5, 9):          # a face de pedra sumindo no escuro
            for x in range(0, T, 2 if y < 7 else 4):
                t.p(x + (y % 2), y, "brick_dk")
    return t.c


def decals():
    out = []
    d = P(PAL)                      # cascalho
    for x, y in ((4, 7), (5, 8), (11, 10), (9, 5)):
        d.p(x, y, "slab_hi")
        d.p(x + 1, y, "joint")
    out.append(d.c)
    d = P(PAL)                      # musgo entre as lajes
    for x, y in ((5, 8), (6, 8), (7, 9), (10, 7), (11, 8)):
        d.p(x, y, "moss")
    d.p(6, 7, "moss_hi")
    d.p(10, 6, "moss_hi")
    out.append(d.c)
    d = P(PAL)                      # mancha de cera de vela
    d.disc(8, 9, 2, "bone", 1)
    d.p(8, 8, "flame_hi")
    out.append(d.c)
    d = P(PAL)                      # corrente partida
    for i, x in enumerate(range(3, 13, 2)):
        d.p(x, 8 + (i % 2), "iron_hi")
        d.p(x + 1, 8 + (i % 2), "iron")
    out.append(d.c)
    return out


def tiles():
    out = [wall_upper(), wall_mid(), wall_lower(), floor(0), floor(1), floor(2), floor(3), wall_top(),
           furn_top(0), furn_top(1), furn_top(2), furn_top(3), furn_front(), gap(False), gap(True)]
    out += decals()
    for part in RUG_PARTS:          # passadeira roxa com bordas douradas
        out.append(rug_piece(part, PAL, "robe_lo", "robe", "gold", "robe_hi"))
    return out


DECOR = ["torch", "banner", "slit", "gears", "chains", "brazier"]


def decor(kind):
    """Muralha, 16×32: y 0–15 parte alta, 16–31 parte do meio."""
    t = P(PAL, T, 32)
    if kind == "torch":
        t.r(6, 20, 4, 2, "iron")
        t.r(7, 16, 2, 4, "brass_lo")
        t.p(6, 16, "brass")
        t.p(9, 16, "brass")
        t.disc(8, 13, 2, "flame", 3)
        t.p(8, 13, "flame_hi")
        t.p(8, 14, "flame_hi")
        t.p(7, 10, "ember")
        t.vl(8, 22, 24, "iron_hi")
    elif kind == "banner":
        t.hl(1, 14, 5, "brass")
        t.p(0, 5, "brass_hi")
        t.p(15, 5, "brass_hi")
        t.r(3, 6, 10, 22, "robe")
        t.vl(3, 6, 27, "robe_hi")
        t.vl(12, 6, 27, "robe_lo")
        for x in range(3, 13):      # ponta em V
            dy = abs(x - 7.5)
            t.p(x, int(28 - (5 - dy)), "robe")
        t.hl(3, 12, 8, "gold")
        t.disc(8, 16, 3, "gold")    # relógio bordado
        t.disc(8, 16, 2, "robe_lo")
        t.vl(8, 14, 16, "gold")
        t.hl(8, 9, 16, "gold")
    elif kind == "slit":            # seteira com luar
        t.r(6, 8, 4, 20, "brick_dk")
        t.r(7, 9, 2, 18, "glass")
        t.p(7, 12, "moon")
        t.p(8, 13, "glass_hi")
        t.hl(5, 10, 7, "cornice")
        t.hl(5, 10, 28, "cornice")
    elif kind == "gears":
        t.disc(6, 14, 5, "brass_lo")
        t.disc(6, 14, 4, "brass")
        t.disc(6, 14, 1, "iron")
        t.disc(11, 22, 3, "brass_lo")
        t.disc(11, 22, 2, "brass_hi")
        t.p(11, 22, "iron")
        for dx, dy in ((0, -6), (6, 0), (0, 6), (-6, 0), (4, -4), (-4, 4), (4, 4), (-4, -4)):
            t.p(6 + dx, 14 + dy, "brass_lo")
        t.p(3, 11, "brass_hi")
    elif kind == "chains":
        for x in (4, 11):
            for y in range(4, 26):
                t.p(x + (y % 2), y, "iron_hi" if y % 3 else "iron")
        t.r(3, 26, 3, 2, "iron")
        t.r(10, 22, 3, 2, "iron")
    elif kind == "brazier":         # braseiro de pé encostado na parede
        t.vl(8, 24, 31, "iron")
        t.hl(5, 11, 31, "iron")
        t.r(4, 20, 9, 4, "iron")
        t.hl(4, 12, 20, "iron_hi")
        t.r(5, 18, 7, 2, "ember")
        t.disc(8, 15, 3, "flame", 4)
        t.disc(8, 16, 1, "flame_hi", 2)
        t.p(6, 11, "ember")
    return t.c
