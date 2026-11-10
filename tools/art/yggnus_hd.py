"""Yggnus detalhado nas três vistas, desenhado à mão linha a linha.

A frente vem de yggnus_frente.py; aqui ficam as costas, o perfil (virado
para a direita) e a montagem das poses: o corpo é feito de peças (cabeça,
cachecol, tronco, braços, pernas) que as animações deslocam, e a espada, o
broquel e a ferramenta são desenhados por cima, com contorno próprio.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixel import Canvas  # noqa: E402
import yggnus_frente as F  # noqa: E402

L = F.LEGENDA
W, H, FOOT_Y = 32, 48, 44

# ------------------------------------------------------------------ costas
CABECA_COSTAS = {
    6: (12, "KK.KKK.KK"),
    7: (10, "KKhhKhhhKhhKK"),
    8: (9, "KhhjhhhhhjhhhK"),
    9: (9, "KhjjhhhjhhjhhK"),
    10: (9, "KhhhhjhhhhhhhK"),
    11: (9, "KhHhhhhhjhhhHK"),
    12: (9, "KHhhjhhhhhhhHK"),
    13: (9, "KHhhhhHhhjhhHK"),
    14: (9, "KShhHhhhhhhHsK"),
    15: (9, "KShHhhhHhhHhsK"),
    16: (9, "KHHhHhhhHhhHHK"),
    17: (9, "KHHHhHHHHhHHHK"),
    18: (10, "KHHsSSSSsHHK"),
    19: (11, "KsSSSSSSsK"),
}
CACHECOL_COSTAS = {
    20: (10, "KFFFFFFFFFFK"),
    21: (9, "KFFfFFFFFfFFFK"),
    22: (9, "KfFFffFFFffffK"),
    23: (7, "KKCCfFFfvfffCCccKK"),
}
PONTA_COSTAS = {24: (11, "KFfK"), 25: (11, "KFfK"), 26: (11, "KFfK"), 27: (11, "KfvK"), 28: (11, "KvvK"), 29: (12, "KK")}
TRONCO_COSTAS = {   # x 9..22; farol bordado em dourado no meio das costas
    24: "CCCBCCCCCCCCcc",
    25: "CCBCCCCGCCCCcc",
    26: "CCBCCCGgGCCCcc",
    27: "CCBCCCCGCCCCcc",
    28: "CCBCCCCGCCCCcc",
    29: "CCBCCCGGGCCCcc",
    30: "TTTTTTTRTTTTTt",
    31: "CCBCCCCKCCCCcc",
    32: "CCBCCCCKCCCCcc",
    33: "CCBCCCcKcCCCcc",
    34: "CCBCCCcKcCCccD",
    35: "CCCCCccKccCccD",
    36: "GGGgGGGKGGGgGg",
}

# ------------------------------------------------------------------ perfil
CABECA_LADO = {
    6: (12, "KKK.KK"),
    7: (11, "KhhKKhhK"),
    8: (10, "KhjhhhhhhK"),
    9: (9, "KhjjhhhhhjhK"),
    10: (9, "KhhhhhhhhhhK"),
    11: (9, "KHhhHhhhhHhK"),
    12: (9, "KHHhhHHSSSHK"),
    13: (9, "KHHHhSLSSSSK"),
    14: (9, "KHHsSSSSHHSK"),
    15: (9, "KHHSsSSSSESSK"),
    16: (9, "KHHHSSSSSESSK"),
    17: (9, "KHHHSSSSSSsK"),
    18: (10, "KHHSSSSssK"),
    19: (11, "KsSSSSsK"),
}
CACHECOL_LADO = {
    20: (11, "KFFFFFFFFK"),
    21: (10, "KFFFfFFFffK"),
    22: (8, "KFfKfFFffffK"),
    23: (7, "KFfK"),
    24: (6, "KfvK"),
    25: (6, "KvK"),
}
TRONCO_LADO = {     # x 10..21; a frente (direita) é aberta e mostra a camisa
    24: "KcCCCCCCBNK.",
    25: "KcCCCCCCBNK.",
    26: "KcCCCCCCBNnK",
    27: "KcCCCCCCBNnK",
    28: "KcCCCCCCBGNK",
    29: "KcCCCCCCBGNK",
    30: "KtTTTTTTTRTK",
    31: "KcCCCCCCBGPK",
    32: "KcCCCCCCBGPK",
    33: "KDcCCCCCBGpK",
    34: "KDcCCCCCCGK.",
    35: "KDccCCCCCGK.",
    36: "KgGGGGGGGgK.",
}
BRACO_LADO = {24: "KBCcK", 25: "KBCcK", 26: "KBCcK", 27: "KBCcK", 28: "KBCcK", 29: "KBccK",
              30: "KFffK", 31: "KSSsK", 32: "KSssK", 33: ".KKK."}
PERNA_LADO = {37: "KqPPpK", 38: "KqPPpK", 39: "KFFFfK", 40: "KOooOK", 41: "KOoOOOK", 42: "KOOOOOK", 43: "KbbbbbK"}
ESCURO = {"P": "p", "q": "P", "O": "b", "o": "O", "F": "f", "B": "c", "C": "c"}

# ------------------------------------------------------------------ caído
DEITADO = {
    36: (5, "KKKK"),
    37: (4, "KhhjhK....KKKKKKKKKKKKK"),
    38: (3, "KhhhhSSK.KFFKCCCCCCCGKKqK"),
    39: (3, "KHhhSESKKFFfKCBCCCCCGPPpKKK"),
    40: (3, "KHHSSSSKFfvKCCCCCCcGPPpKOOK"),
    41: (4, "KHSSssKKKKKCcccccGgPPpKOOK"),
    42: (5, "KKKKK....KKKKKKKKKKKKKbbK"),
}


def _row(c, y, x0, txt, remap=None):
    for i, ch in enumerate(txt):
        if remap:
            ch = remap.get(ch, ch)
        col = L.get(ch)
        if col:
            c.put(x0 + i, y, col)


def _part(c, rows, dx=0, dy=0, x0=None, remap=None):
    for y, v in rows.items():
        x, txt = (x0, v) if x0 is not None else v
        _row(c, y + dy, x + dx, txt, remap)


def shadow(c, wide=False):
    w = 7 if wide else 6
    for i in range(-w, w + 1):
        a = "#0000004a" if abs(i) < w - 1 else "#00000030"
        c.put(16 + i, FOOT_Y, a)
    for i in range(-w + 2, w - 1):
        c.put(16 + i, FOOT_Y + 1, "#00000030")


def _legs(c, p, x_l=10, x_r=17, rows=None):
    rows = rows or F.PERNA_E
    for x, (fx, fy) in ((x_l, p["lf"]), (x_r, p["rf"])):
        _part(c, rows, fx, fy, x0=x)


# ------------------------------------------------------------- acessórios

def sword(c, hx, hy, dx, dy, length=12):
    """Espada saindo da mão (hx, hy) na direção (dx, dy) — passos inteiros."""
    s = Canvas(W, H)
    px, py = -dy, dx                 # perpendicular (guarda)
    for i in (-2, -1, 1, 2):
        s.put(hx + px * i, hy + py * i, "#d9ad4f")
    s.put(hx + px * 2, hy + py * 2, "#9c7530")
    s.put(hx - dx, hy - dy, "#7d4d31")          # cabo
    s.put(hx - 2 * dx, hy - 2 * dy, "#d9ad4f")  # pomo
    for i in range(1, length):
        x, y = hx + dx * i, hy + dy * i
        s.put(x, y, "#dfe5ec")
        s.put(x + px, y + py, "#8f99a6")
        if i % 4 == 2:
            s.put(x, y, "#ffffff")
    s.put(hx + dx * length, hy + dy * length, "#8f99a6")
    s.outline("#1b1420")
    c.img.alpha_composite(s.img)


def buckler(c, cx, cy, edge=False):
    s = Canvas(W, H)
    if edge:
        s.rect(cx - 1, cy - 6, 3, 12, "#b8873a")
        s.vline(cx, cy - 5, cy + 5, "#e0b555")
        s.put(cx + 1, cy, "#7d5a26")
    else:
        s.ellipse(cx, cy, 6, 6, "#7d5a26")
        s.ellipse(cx, cy, 5, 5, "#b8873a")
        s.ellipse(cx - 1, cy - 1, 3, 3, "#e0b555")
        s.ellipse(cx, cy, 2, 2, "#b8873a")
        s.put(cx, cy, "#f6dc8a")
        for ox, oy in ((0, -4), (4, 0), (0, 4), (-4, 0)):
            s.put(cx + ox, cy + oy, "#5a3e18")
    s.outline("#1b1420")
    c.img.alpha_composite(s.img)


def tool(c, x, y):
    s = Canvas(W, H)
    s.rect(x, y, 5, 4, "#b8873a")
    s.hline(x, x + 4, y, "#e0b555")
    s.put(x + 2, y + 1, "#5ee6e0")
    s.vline(x + 2, y + 4, y + 8, "#8f99a6")
    s.put(x + 1, y + 9, "#dfe5ec")
    s.put(x + 3, y + 9, "#dfe5ec")
    s.outline("#1b1420")
    c.img.alpha_composite(s.img)


# ------------------------------------------------------------------ vistas

def front(p):
    c = Canvas(W, H)
    shadow(c)
    b = p["bob"]
    _legs(c, p)
    _part(c, {y: t for y, t in F.TRONCO.items()}, dy=b, x0=9)
    k = p["blade"]
    raised = k == "wind_up"
    if not raised:
        _part(c, F.BRACO_E, p["la"][0], b + p["la"][1], x0=6)
        _part(c, F.BRACO_D, p["ra"][0], b + p["ra"][1], x0=23)
    for i in range(7):               # bainha no quadril esquerdo
        c.put(8 - i // 3, 32 + b + i, "#4f2f20")
    c.put(8, 31 + b, "#d9ad4f")
    _part(c, F.CACHECOL, dy=b)
    head = dict(F.CABECA)
    if p["hurt"]:
        head[15] = (9, "KHSSKSSSSKSsHK")
        head[16] = (9, "KHSKSSSSSSKsHK")
    _part(c, head, dy=b)
    if raised:
        _part(c, F.BRACO_E, 2, b - 7, x0=6)
        _part(c, F.BRACO_D, -2, b - 7, x0=23)
        sword(c, 16, 17 + b, 0, -1, 13)
    elif k == "wind_r":
        sword(c, 25 + p["ra"][0], 31 + b + p["ra"][1], 1, -1, 9)
    elif k == "hit_r":
        sword(c, 24 + p["ra"][0], 33 + b + p["ra"][1], -1, 1, 9)
    elif k == "wind_l":
        sword(c, 7 + p["la"][0], 31 + b + p["la"][1], -1, -1, 9)
    elif k == "hit_l":
        sword(c, 8 + p["la"][0], 33 + b + p["la"][1], 1, 1, 9)
    elif k in ("hit_down", "rest"):
        sword(c, 16, 33 + b, 0, 1, 12 if k == "hit_down" else 10)
    if p["shield"]:
        buckler(c, 16, 30 + b)
    if p["tool"]:
        tool(c, 22, 31 + b)
    return c


def back(p):
    c = Canvas(W, H)
    shadow(c)
    b = p["bob"]
    k = p["blade"]
    if k in ("hit_r", "hit_l", "hit_down", "rest"):   # a lâmina à frente aparece embaixo
        sword(c, 16, 34 + b, 0, 1, 10)
    _legs(c, p)
    _part(c, TRONCO_COSTAS, dy=b, x0=9)
    _part(c, PONTA_COSTAS, dy=b)
    raised = k == "wind_up"
    if raised:
        _part(c, F.BRACO_E, 2, b - 7, x0=6)
        _part(c, F.BRACO_D, -2, b - 7, x0=23)
    else:
        _part(c, F.BRACO_E, p["la"][0], b + p["la"][1], x0=6)
        _part(c, F.BRACO_D, p["ra"][0], b + p["ra"][1], x0=23)
    _part(c, CACHECOL_COSTAS, dy=b)
    _part(c, CABECA_COSTAS, dy=b)
    if k is None or k in ("hit_r", "hit_l", "hit_down", "rest", "arm"):
        for i in range(7):           # bainha cruzando as costas
            c.put(19 + i // 2, 31 + b + i, "#4f2f20")
    if raised:
        sword(c, 16, 15 + b, 0, -1, 12)
    elif k == "wind_r":
        sword(c, 24, 27 + b, 1, -1, 9)
    elif k == "wind_l":
        sword(c, 7, 27 + b, -1, -1, 9)
    if p["shield"]:
        buckler(c, 23, 27 + b, edge=True)
    return c


def side(p):
    c = Canvas(W, H)
    shadow(c)
    b = p["bob"]
    st = p["stride"]
    lb, lf = (-1 if st < 0 else 0), (-1 if st > 0 else 0)
    _part(c, PERNA_LADO, -st, lb, x0=12, remap=ESCURO)
    k = p["blade"]
    if k in ("wind_r", "wind_l", "wind_up"):          # braço de trás erguido com a espada
        sword(c, 12, 18 + b, -1, -1, 9)
    _part(c, PERNA_LADO, st, lf, x0=15)
    for i in range(8):               # bainha atrás do quadril
        c.put(11 - i // 2, 31 + b + i, "#4f2f20")
    c.put(11, 30 + b, "#d9ad4f")
    _part(c, TRONCO_LADO, dy=b, x0=10)
    _part(c, CACHECOL_LADO, dy=b)
    head = dict(CABECA_LADO)
    if p["hurt"]:
        head[15] = (9, "KHHSsSSSKKSSK")
        head[16] = (9, "KHHHSSSSSSSSK")
    _part(c, head, dy=b)
    if k in ("hit_r", "hit_l", "hit_down", "rest", "arm"):
        arm = {26: "KBCCCCcK", 27: "KBCCCcFK", 28: "KccccfSK", 29: ".KKKKKK."}
        _part(c, arm, 0, b, x0=14)
        if k != "arm":               # "arm": o jogo desenha a lâmina grande
            sword(c, 22, 27 + b, 1, 0, 9)
    elif k in ("wind_r", "wind_l", "wind_up"):
        _part(c, {20: "KSSK", 21: "KSsK", 22: "KCcK", 23: "KCcK", 24: "KCcK", 25: "KBcK", 26: "KBcK", 27: ".KK."}, 0, b, x0=12)
    else:
        _part(c, BRACO_LADO, p["ra"][0], b + p["ra"][1], x0=14)
    if p["shield"]:
        buckler(c, 21, 28 + b, edge=True)
    if p["tool"]:
        tool(c, 19, 27 + b)
    return c


def lying():
    c = Canvas(W, H)
    shadow(c, wide=True)
    _part(c, DEITADO)
    return c


VIEWS = {"down": front, "up": back, "side": side}
