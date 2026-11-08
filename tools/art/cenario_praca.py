"""Praça de Exódia, à noite: calçamento de pedra, fachadas de enxaimel com
telhado de ardósia, canteiros de flores e um mosaico no chão.
Colunas em cenario_detalhado.HD_COLS; decoração 16×32 em DECOR.
"""

import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from cenario_detalhado import RUG_PARTS, T, P  # noqa: E402

PAL = {
    "stone": "#77706a", "stone_hi": "#7f7871", "stone_lo": "#6d6761", "mortar": "#57514c", "stone_top": "#8a827a",
    "moss": "#4f6a3e", "moss_hi": "#6b8a4a",
    "plaster": "#cdbb98", "plaster_hi": "#e0d2b0", "plaster_lo": "#a8956f",
    "timber": "#4a3020", "timber_hi": "#6a4630", "timber_lo": "#2e1d13",
    "slate": "#3e4660", "slate_hi": "#56607e", "slate_lo": "#2a3045", "gutter": "#7a5a3a",
    "base": "#5a534c", "base_hi": "#736a60", "base_lo": "#3e3934",
    "hedge": "#3c5a34", "hedge_hi": "#557a45", "hedge_lo": "#2a4024", "hedge_dk": "#1e2e1a",
    "soil": "#4a3424", "soil_lo": "#33231a",
    "red": "#c0443c", "red_hi": "#e86a5a", "yellow": "#e8c050", "white": "#f0ead8", "blue": "#6a8ad0", "pink": "#d07aa0",
    "glass": "#f2c060", "glass_hi": "#ffe8a0", "glass_lo": "#c88a34", "glass_dark": "#2a3450",
    "iron": "#2a2630", "iron_hi": "#4a4452",
    "flame": "#ffd27a", "flame_hi": "#fff2c0",
    "water": "#22405a", "water_hi": "#3a6688", "water_lo": "#16293c", "foam": "#8ab0c8",
    "wood": "#7a5236", "wood_hi": "#9c6c45", "wood_lo": "#523522", "paper": "#e8dfc8",
    "leaf": "#a8743a", "leaf_hi": "#c89048", "puddle": "#3a5068", "puddle_hi": "#6a88a8",
    "mosaic_a": "#958b7c", "mosaic_b": "#5e5850", "mosaic_c": "#b89a5a", "mosaic_d": "#6a86a0", "fringe": "#8a827a",
}


def floor(variant):
    """Paralelepípedos arredondados em fileiras desencontradas."""
    t = P(PAL)
    t.r(0, 0, T, T, "mortar")
    rnd = random.Random(f"pedra-{variant}")
    for row in range(4):
        y0 = row * 4
        off = 0 if row % 2 == 0 else 4
        x = -off
        while x < T:
            w = 8
            tone = rnd.choice(["stone", "stone", "stone_hi", "stone_lo"])
            for yy in range(y0, y0 + 3):
                for xx in range(x, x + w - 1):
                    corner = (xx in (x, x + w - 2)) and (yy in (y0, y0 + 2))
                    if 0 <= xx < T and not corner:
                        t.p(xx, yy, tone)
            for xx in range(x + 1, x + w - 2):
                if 0 <= xx < T:
                    t.p(xx, y0, "stone_top" if tone != "stone_lo" else "stone")
            x += w
    if variant == 1:   # musgo entre as pedras
        for x, y in ((2, 7), (3, 7), (9, 11), (10, 11), (11, 3)):
            t.p(x, y, "moss")
        t.p(3, 6, "moss_hi")
    elif variant == 2:  # pedra rachada
        t.line(5, 4, 8, 6, "mortar")
        t.p(9, 6, "mortar")
    elif variant == 3:  # tampa de bueiro de ferro, redonda
        t.disc(8, 8, 5, "base_lo", 4)
        t.disc(8, 8, 4, "base", 3)
        for x in range(5, 12, 2):
            t.vl(x, 6, 10, "base_lo")
        t.hl(5, 10, 5, "base_hi")
    return t.c


def wall_upper():
    """Beiral: telhas de ardósia em escamas e a calha de madeira."""
    t = P(PAL)
    t.r(0, 0, T, T, "slate")
    for row in range(3):
        y = row * 4
        off = (row % 2) * 2
        for x in range(-off, T, 4):
            t.hl(x, x + 3, y + 3, "slate_lo")
            t.p(x + 1, y + 1, "slate_hi")
            t.p(x + 3, y + 2, "slate_lo")
    t.hl(0, 15, 12, "gutter")
    t.hl(0, 15, 13, "timber")
    t.hl(0, 15, 14, "timber_lo")
    t.hl(0, 15, 15, "#00000060")
    return t.c


def plaster(t, y0=0, y1=T):
    for y in range(y0, y1):
        for x in range(T):
            t.p(x, y, "plaster")
    rnd = random.Random(y0)
    for _ in range(5):
        t.p(rnd.randrange(T), rnd.randrange(y0, y1), "plaster_lo")
    for _ in range(3):
        t.p(rnd.randrange(T), rnd.randrange(y0, y1), "plaster_hi")


def wall_mid():
    """Enxaimel: reboco claro entre vigas escuras."""
    t = P(PAL)
    plaster(t)
    t.vl(0, 0, 15, "timber")
    t.vl(1, 0, 15, "timber_lo")
    t.line(2, 15, 13, 3, "timber")
    t.line(3, 15, 14, 3, "timber_lo")
    t.hl(0, 15, 0, "#00000040")
    return t.c


def wall_lower():
    """Base de pedra com soleira."""
    t = P(PAL)
    plaster(t, 0, 4)
    t.hl(0, 15, 4, "timber")
    t.hl(0, 15, 5, "timber_lo")
    t.r(0, 6, T, 10, "base")
    for y in (6, 11):
        off = 0 if y == 6 else 4
        for x in range(off, T, 8):
            t.vl(x, y, y + 4, "base_lo")
        t.hl(0, 15, y, "base_hi")
    t.hl(0, 15, 15, "base_lo")
    return t.c


def wall_top():
    """Sebe aparada (bordas laterais e de baixo da praça)."""
    t = P(PAL)
    t.r(0, 0, T, T, "hedge")
    rnd = random.Random("sebe")
    for _ in range(40):
        x, y = rnd.randrange(T), rnd.randrange(T)
        t.p(x, y, rnd.choice(["hedge_hi", "hedge_lo", "hedge_hi"]))
    for _ in range(10):
        x, y = rnd.randrange(T), rnd.randrange(T)
        t.p(x, y, "hedge_dk")
    for x in (3, 11):
        t.p(x, 6, "white")
    return t.c


def furn_top(variant):
    """Canteiro de flores visto de cima."""
    t = P(PAL)
    t.r(0, 0, T, T, "soil")
    t.hl(0, 15, 0, "stone_top")
    t.hl(0, 15, 1, "stone_hi")
    rnd = random.Random(f"flor-{variant}")
    colors = [["red", "red_hi"], ["yellow", "white"], ["blue", "white"], ["pink", "red_hi"]][variant]
    for _ in range(12):
        x, y = rnd.randrange(1, 15), rnd.randrange(3, 15)
        t.p(x, y, "hedge")
        t.p(x, y - 1, "hedge_hi")
    for _ in range(7):
        x, y = rnd.randrange(2, 14), rnd.randrange(3, 14)
        col = rnd.choice(colors)
        for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 0), (0, -1)):
            t.p(x + dx, y + dy, col if (dx, dy) != (0, 0) else "yellow")
    for _ in range(5):
        t.p(rnd.randrange(T), rnd.randrange(3, T), "soil_lo")
    return t.c


def furn_front():
    t = P(PAL)
    t.r(0, 0, T, T, "base")
    t.hl(0, 15, 0, "stone_top")
    t.hl(0, 15, 1, "base_hi")
    for y in (5, 10):
        t.hl(0, 15, y, "base_lo")
        off = 0 if y == 5 else 4
        for x in range(off, T, 8):
            t.vl(x, y - 4 if y == 5 else y, y if y == 5 else y + 4, "base_lo")
    t.hl(0, 15, 14, "base_lo")
    t.hl(0, 15, 15, "#1b1420")
    for x in (2, 7, 12):         # trepadeira caindo da borda
        t.vl(x, 1, 3 + x % 3, "hedge")
        t.p(x + 1, 2, "hedge_hi")
    return t.c


def gap(edge):
    """Canal de água escura com reflexos."""
    t = P(PAL)
    t.r(0, 0, T, T, "water")
    rnd = random.Random("agua")
    for _ in range(5):
        x, y = rnd.randrange(T - 3), rnd.randrange(T)
        t.hl(x, x + 2, y, "water_hi")
    for _ in range(4):
        t.p(rnd.randrange(T), rnd.randrange(T), "water_lo")
    if edge:
        t.r(0, 0, T, 3, "base")
        t.hl(0, 15, 0, "stone_top")
        t.hl(0, 15, 3, "#1b1420")
        t.hl(0, 15, 4, "water_lo")
        t.hl(2, 5, 5, "foam")
        t.hl(10, 12, 5, "foam")
    return t.c


def decals():
    out = []
    d = P(PAL)                 # folhas caídas
    for x, y in ((4, 6), (5, 6), (5, 7)):
        d.p(x, y, "leaf")
    d.p(4, 7, "leaf_hi")
    for x, y in ((11, 11), (12, 11), (12, 10)):
        d.p(x, y, "leaf_hi")
    d.p(11, 10, "leaf")
    out.append(d.c)
    d = P(PAL)                 # poça refletindo a lua
    d.disc(8, 9, 5, "#3a506880", 2)
    d.hl(6, 8, 8, "#6a88a880")
    d.p(10, 10, "puddle_hi")
    out.append(d.c)
    d = P(PAL)                 # cartaz rasgado no chão
    d.r(5, 6, 6, 5, "plaster_lo")
    d.hl(6, 9, 7, "stone_lo")
    d.hl(6, 8, 9, "stone_lo")
    d.p(10, 10, "plaster_lo")
    out.append(d.c)
    d = P(PAL)                 # tufo de capim entre as pedras
    for x, h in ((6, 3), (7, 4), (8, 2), (9, 3)):
        d.vl(x, 11 - h, 11, "moss" if x % 2 else "moss_hi")
    d.p(7, 7, "yellow")
    out.append(d.c)
    return out


def mosaic(part):
    """Mosaico de pastilhas: losangos azuis, cercadura escura e friso de latão."""
    t = P(PAL)
    for y in range(T):
        for x in range(T):
            t.p(x, y, "mosaic_a" if ((x // 2) + (y // 2)) % 2 == 0 else "stone_top")
    for y in range(T):          # losango azul no meio de cada peça
        for x in range(T):
            d = abs(x - 7.5) + abs(y - 7.5)
            if d < 3:
                t.p(x, y, "mosaic_d")
            elif d < 4:
                t.p(x, y, "mosaic_c")
    top, bot = part.startswith("t"), part.startswith("b")
    left, right = part.endswith("l"), part.endswith("r")
    if top:
        t.r(0, 0, T, 3, "mosaic_b")
        t.hl(0, 15, 3, "mosaic_c")
    if bot:
        t.r(0, 13, T, 3, "mosaic_b")
        t.hl(0, 15, 12, "mosaic_c")
    if left:
        t.r(0, 0, 3, T, "mosaic_b")
        t.vl(3, 3 if top else 0, 12 if bot else 15, "mosaic_c")
    if right:
        t.r(13, 0, 3, T, "mosaic_b")
        t.vl(12, 3 if top else 0, 12 if bot else 15, "mosaic_c")
    return t.c


def tiles():
    out = [wall_upper(), wall_mid(), wall_lower(), floor(0), floor(1), floor(2), floor(3), wall_top(),
           furn_top(0), furn_top(1), furn_top(2), furn_top(3), furn_front(), gap(False), gap(True)]
    out += decals()
    for part in RUG_PARTS:     # mosaico de pedras claras
        out.append(mosaic(part))
    return out


DECOR = ["window", "lantern", "sign", "ivy", "window_dark", "flowerbox"]


def decor(kind):
    """Decoração da fachada, 16×32: y 0–15 é o beiral, 16–31 a parede."""
    t = P(PAL, T, 32)
    if kind in ("window", "window_dark", "flowerbox"):
        lit = kind != "window_dark"
        t.r(3, 17, 10, 11, "timber")
        t.r(4, 18, 8, 9, "glass" if lit else "glass_dark")
        t.vl(8, 18, 26, "timber")
        t.hl(4, 11, 22, "timber")
        if lit:
            t.p(5, 19, "glass_hi")
            t.p(6, 19, "glass_hi")
            t.p(5, 20, "glass_hi")
            t.hl(4, 11, 26, "glass_lo")
            t.p(10, 24, "glass_lo")
        else:
            t.p(5, 19, "slate_hi")
        for x in (1, 2):       # venezianas
            t.vl(x, 17, 27, "wood")
        t.vl(13, 17, 27, "wood")
        t.vl(14, 17, 27, "wood_lo")
        t.hl(2, 13, 28, "timber_lo")
        if kind == "flowerbox":
            t.r(3, 28, 10, 3, "wood")
            t.hl(3, 12, 28, "wood_hi")
            for x, col in ((4, "red"), (6, "red_hi"), (8, "yellow"), (10, "red"), (11, "pink")):
                t.p(x, 27, col)
                t.p(x, 26, "hedge_hi")
    elif kind == "lantern":
        t.hl(4, 12, 17, "iron")             # braço de ferro
        t.p(12, 18, "iron")
        t.vl(4, 16, 18, "iron_hi")
        t.p(9, 18, "iron")
        t.r(7, 19, 5, 1, "iron")
        t.r(7, 20, 5, 6, "iron")
        t.r(8, 21, 3, 4, "flame")
        t.p(9, 22, "flame_hi")
        t.p(9, 23, "flame_hi")
        t.hl(6, 12, 26, "iron")
        t.p(9, 27, "iron_hi")
    elif kind == "sign":
        t.hl(2, 12, 18, "iron")             # tabuleta da loja pendurada
        t.vl(2, 17, 19, "iron_hi")
        t.vl(5, 19, 20, "iron")
        t.vl(11, 19, 20, "iron")
        t.r(3, 21, 11, 7, "wood")
        t.hl(3, 13, 21, "wood_hi")
        t.hl(3, 13, 27, "wood_lo")
        t.disc(8, 24, 2, "yellow")           # engrenagem pintada (relojoaria)
        t.p(8, 24, "wood_lo")
        for x, y in ((8, 21), (8, 27), (5, 24), (11, 24)):
            t.p(x, y, "yellow")
    elif kind == "ivy":
        rnd = random.Random("hera")
        for y in range(10, 31):
            x = 6 + int(2 * ((y * 7) % 5) / 4)
            t.p(x, y, "hedge_lo")
            if rnd.random() < 0.7:
                t.p(x + rnd.choice((-2, -1, 1, 2)), y, rnd.choice(["hedge", "hedge_hi"]))
            if rnd.random() < 0.4:
                t.p(x + rnd.choice((-3, 3)), y, "hedge")
        t.p(5, 20, "pink")
        t.p(8, 26, "pink")
    return t.c
