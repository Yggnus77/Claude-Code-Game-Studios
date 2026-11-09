"""Objetos do mundo no nível detalhado (16×32, pivô [8,24] = centro do
ladrilho). Mesmos nomes e sinais da primeira versão: a placa de examinar
tem o losango azul, o bloco de puxar tem uma argola simples e a argola de
gancho é dupla.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixel import Canvas  # noqa: E402
from inimigos_hd import C, K, ball, box, line, put  # noqa: E402

C.update({
    "night": "#141a2e", "granite": "#b4aca0", "granite_hi": "#d4ccc0", "granite_lo": "#857d72",
    "crystal": "#5ee6e0", "crystal_hi": "#c8fffb", "crystal_lo": "#2e9a9e",
    "safe": "#7ee0ff", "safe_lo": "#3a90c0", "wood_hi": "#9c6c45", "boot": "#3e2a22",
    "npc_coat": "#5a7a5a", "npc_coat_hi": "#78986e", "npc_coat_lo": "#3e5640", "npc_hair": "#8a8a90",
    "apron": "#d8ccb0", "apron_lo": "#a89a7c",
    "bush": "#3f6a34", "bush_hi": "#5f8c46", "bush_lo": "#2a4a26", "bush_dk": "#1a3020", "bush_tip": "#86b060",
    "flower": "#e8d070", "flower_hi": "#fff4b8", "berry": "#c0485a",
    "clay": "#b0643c", "clay_hi": "#d88a58", "clay_lo": "#7a4028", "clay_dk": "#4e2818",
    "glaze": "#3a6a8a", "glaze_hi": "#5a92b0",
})
OW, OH, PY = 16, 32, 24


def door(open_):
    c = Canvas(OW, OH)
    y0 = PY - 16
    # arco de pedra
    box(c, 0, y0 + 3, 16, 21, "stone", "stone_hi", "stone_dk")
    ball(c, 8, y0 + 4, 8, 4, "stone", "stone_hi", "stone_dk")
    for y in range(y0 + 7, PY + 7, 4):
        put(c, 0, y, "stone_dk")
        put(c, 15, y, "stone_dk")
    put(c, 8, y0, "gold")
    if open_:
        box(c, 3, y0 + 5, 10, 18, "night", "night", "night")
        ball(c, 8, y0 + 5, 5, 3, "night", "night", "night")
        for y in range(PY + 2, PY + 7):
            line(c, 3, y, 12, y, "lamp" if y > PY + 4 else "lamp_hi")
        put(c, 5, PY, "lamp")
        put(c, 10, PY + 1, "lamp")
    else:
        box(c, 3, y0 + 5, 10, 18, "wood", "wood_hi", "wood_lo")
        ball(c, 8, y0 + 5, 5, 3, "wood", "wood_hi", "wood_lo")
        for x in (5, 8, 11):
            line(c, x, y0 + 4, x, PY + 6, "wood_lo")
        for y in (y0 + 8, PY + 2):
            line(c, 3, y, 12, y, "brass_lo")
            put(c, 4, y, "brass_hi")
            put(c, 11, y, "brass_hi")
        ball(c, 10, PY - 3, 1, 1, "brass", "brass_hi", "brass_lo")
    c.outline(K)
    return c


def chest(open_):
    c = Canvas(OW, OH)
    box(c, 1, PY - 4, 14, 9, "wood", "wood_hi", "wood_lo")
    for x in (1, 14):
        line(c, x, PY - 4, x, PY + 4, "brass")
    line(c, 1, PY, 14, PY, "brass_lo")
    line(c, 2, PY + 4, 13, PY + 4, "wood_lo")
    if open_:
        box(c, 1, PY - 13, 14, 6, "wood_lo", "wood", "wood_lo")     # tampa erguida
        line(c, 1, PY - 8, 14, PY - 8, "brass")
        box(c, 2, PY - 5, 12, 3, "pd", "pd", "pd")
        put(c, 5, PY - 4, "gold_lo")
        put(c, 10, PY - 5, "gold_lo")
    else:
        box(c, 1, PY - 10, 14, 6, "wood_hi", "toy_hi", "wood")
        ball(c, 8, PY - 10, 6, 2, "wood_hi", "toy_hi", "wood")
        line(c, 1, PY - 5, 14, PY - 5, "brass_hi")
        for x in (4, 11):
            line(c, x, PY - 11, x, PY - 5, "brass")
        box(c, 6, PY - 4, 4, 4, "gold", "gold_hi", "gold_lo")
        put(c, 8, PY - 2, K)
        put(c, 3, PY - 9, "white")
    c.outline(K)
    return c


def clue():
    c = Canvas(OW, OH)
    box(c, 3, PY - 3, 10, 7, "paper", "white", "paper_lo")
    line(c, 5, PY - 1, 10, PY - 1, "fold")
    line(c, 5, PY + 1, 9, PY + 1, "fold")
    put(c, 12, PY - 3, "paper_lo")
    put(c, 4, PY + 2, "red")
    for x, y in ((6, PY - 14), (7, PY - 15), (8, PY - 15), (9, PY - 14), (9, PY - 13), (8, PY - 12), (7, PY - 11), (7, PY - 9)):
        put(c, x, y, "lamp_hi")
        put(c, x + 1, y + 1, "gold_lo")
    c.outline(K)
    return c


def npc():
    """Velho relojoeiro de avental."""
    c = Canvas(OW, OH)
    for x in (5, 9):
        box(c, x, PY + 2, 3, 3, "boot", "boot", "pd")
    box(c, 3, PY - 10, 10, 13, "npc_coat", "npc_coat_hi", "npc_coat_lo")
    box(c, 5, PY - 8, 6, 11, "apron", "white", "apron_lo")
    put(c, 7, PY - 3, "brass")
    put(c, 8, PY - 3, "brass_hi")
    box(c, 4, PY - 18, 8, 8, "skin", "skin", "skin_lo")
    box(c, 3, PY - 20, 10, 3, "npc_hair", "white", "hair_lo")
    line(c, 3, PY - 17, 3, PY - 13, "npc_hair")
    line(c, 12, PY - 17, 12, PY - 14, "hair_lo")
    for x in (6, 9):
        put(c, x, PY - 14, K)
    line(c, 5, PY - 15, 10, PY - 15, "brass_lo")   # óculos
    put(c, 7, PY - 15, "brass")
    line(c, 6, PY - 11, 9, PY - 11, "npc_hair")    # bigode
    c.outline(K)
    return c


def interact():
    c = Canvas(OW, OH)
    box(c, 3, PY - 9, 10, 13, "granite", "granite_hi", "granite_lo")
    box(c, 2, PY + 2, 12, 3, "granite_lo", "granite", "stone_lo")
    for i in range(4):
        line(c, 8 - i, PY - 7 + i, 7 + i, PY - 7 + i, "safe")
        line(c, 8 - i, PY - i, 7 + i, PY - i, "safe")
    line(c, 8, PY - 6, 10, PY - 4, "safe_lo")
    put(c, 7, PY - 5, "white")
    c.outline(K)
    return c


def marco(active):
    c = Canvas(OW, OH)
    box(c, 2, PY + 1, 12, 4, "granite_lo", "granite", "stone_lo")
    box(c, 4, PY - 14, 8, 16, "granite", "granite_hi", "granite_lo")
    box(c, 3, PY - 16, 10, 3, "granite_hi", "white", "granite")
    line(c, 5, PY - 3, 10, PY - 3, "gold_lo")
    line(c, 5, PY - 12, 10, PY - 12, "gold_lo")
    if active:
        box(c, 6, PY - 10, 4, 6, "crystal", "crystal_hi", "crystal_lo")
        put(c, 7, PY - 9, "white")
        for x, y in ((2, PY - 18), (13, PY - 17), (8, PY - 21), (11, PY - 20)):
            put(c, x, y, "crystal_hi")
    else:
        box(c, 6, PY - 10, 4, 6, "stone_dk", "stone_lo", "stone_dk")
        put(c, 7, PY - 9, "stone_lo")
    c.outline(K)
    return c


def anchor():
    c = Canvas(OW, OH)
    box(c, 5, PY - 1, 6, 5, "stone_lo", "stone", "stone_dk")
    ball(c, 8, PY - 6, 5, 5, "brass", "brass_hi", "brass_lo")
    for j in range(-3, 4):
        for i in range(-3, 4):
            if i * i + j * j <= 9:
                c.put(8 + i, PY - 6 + j, "#00000000")
    ball(c, 8, PY - 6, 1, 1, "brass_hi", "gold_hi", "brass")
    put(c, 6, PY - 10, "gold_hi")
    c.outline(K)
    return c


def push_block():
    c = Canvas(OW, OH)
    box(c, 1, PY - 9, 14, 14, "granite", "granite_hi", "granite_lo")
    box(c, 1, PY + 1, 14, 4, "granite_lo", "granite", "stone_lo")
    line(c, 1, PY - 4, 14, PY - 4, "brass")
    line(c, 1, PY - 3, 14, PY - 3, "brass_lo")
    line(c, 7, PY - 8, 7, PY - 5, "granite_lo")
    for x, y in ((3, PY - 7), (12, PY - 1)):
        put(c, x, y, "granite_lo")
    ball(c, 8, PY - 12, 2, 2, "brass", "brass_hi", "brass_lo")
    c.put(8, PY - 12, "#00000000")
    c.outline(K)
    return c


def fragment():
    c = Canvas(OW, OH)
    for i in range(5):
        line(c, 8 - i, PY - 8 + i, 7 + i, PY - 8 + i, "crystal")
        line(c, 8 - i, PY + 2 - i, 7 + i, PY + 2 - i, "crystal_lo" if i < 3 else "crystal")
    line(c, 7, PY - 7, 7, PY + 1, "crystal_hi")
    put(c, 6, PY - 5, "white")
    for x, y in ((2, PY - 9), (13, PY - 6), (11, PY + 2)):
        put(c, x, y, "crystal_hi")
    c.outline(K)
    return c


def bell(lit):
    c = Canvas(OW, OH)
    box(c, 1, PY - 17, 14, 2, "wood", "wood_hi", "wood_lo")
    line(c, 8, PY - 15, 8, PY - 13, "brass_lo")
    for i in range(10):
        w = 2 + i * 5 // 10
        for x in range(8 - w, 8 + w):
            k = "brass_hi" if lit else "brass"
            if x == 8 - w:
                k = "gold_hi" if lit else "brass_hi"
            elif x >= 8 + w - 2:
                k = "brass_lo"
            put(c, x, PY - 13 + i, k)
    line(c, 2, PY - 3, 13, PY - 3, "brass_lo")
    ball(c, 8, PY - 1, 1, 1, "brass_lo", "brass", "brass_dk")
    if lit:
        for x, y in ((1, PY - 12), (14, PY - 10), (2, PY - 6), (13, PY - 4)):
            put(c, x, y, "lamp_hi")
    c.outline(K)
    return c


def bush():
    """Arbusto que a espada corta: tufos sobrepostos, luz do alto à esquerda."""
    c = Canvas(OW, OH)
    for cx, cy, r in ((5, PY - 1, 4), (11, PY - 1, 4), (8, PY - 5, 5), (4, PY - 5, 3), (12, PY - 5, 3)):
        ball(c, cx, cy, r, r - 1, "bush", "bush_hi", "bush_lo")
    for x, y in ((3, PY - 6), (7, PY - 9), (10, PY - 8), (5, PY - 3), (12, PY - 4), (9, PY - 2)):
        put(c, x, y, "bush_tip")
        put(c, x + 1, y + 1, "bush_hi")
    for x, y in ((6, PY + 1), (10, PY + 2), (13, PY), (2, PY + 1)):
        put(c, x, y, "bush_dk")
    for x, y in ((6, PY - 7), (11, PY - 3)):
        put(c, x, y, "flower")
        put(c, x, y - 1, "flower_hi")
    put(c, 4, PY - 1, "berry")
    c.outline(K)
    return c


def bush_cut():
    """Toco que fica depois do corte."""
    c = Canvas(OW, OH)
    for x in (4, 6, 8, 10, 12):
        h = 2 + (x * 7) % 3
        line(c, x, PY + 3 - h, x, PY + 3, "bush_lo")
        put(c, x, PY + 3 - h, "bush_tip")
    line(c, 3, PY + 4, 13, PY + 4, "bush_dk")
    c.outline(K)
    return c


def pot():
    """Pote de barro com faixa azul vidrada."""
    c = Canvas(OW, OH)
    ball(c, 8, PY - 1, 6, 6, "clay", "clay_hi", "clay_lo")
    box(c, 4, PY - 9, 8, 2, "clay_lo", "clay_hi", "clay_dk")
    line(c, 5, PY - 7, 10, PY - 7, "clay_dk")
    for x in range(3, 14):
        put(c, x, PY - 2, "glaze" if x % 3 else "glaze_hi")
    line(c, 3, PY - 1, 13, PY - 1, "clay_lo")
    for x in (5, 8, 11):
        put(c, x, PY - 2, "gold_hi")
    put(c, 5, PY - 5, "clay_hi")
    put(c, 4, PY - 4, "white")
    line(c, 6, PY + 4, 10, PY + 4, "clay_dk")
    c.outline(K)
    return c


OBJECTS = {
    "door_open": lambda: door(True), "door_closed": lambda: door(False),
    "chest": lambda: chest(False), "chest_open": lambda: chest(True), "clue": clue, "npc": npc,
    "interact": interact, "marco": lambda: marco(False), "marco_active": lambda: marco(True),
    "anchor": anchor, "push_block": push_block, "fragment": fragment,
    "bell": lambda: bell(False), "bell_lit": lambda: bell(True),
    "bush": bush, "bush_cut": bush_cut, "pot": pot,
}
