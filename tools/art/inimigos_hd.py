"""Inimigos, Yame Black e Igris no nível detalhado: volumes sombreados com
luz vinda do alto à esquerda, brilho especular, contorno escuro e detalhes
pequenos (botões, costuras, dobras do papel). Mesmos nomes de quadro da
primeira versão, para o jogo não mudar.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixel import Canvas  # noqa: E402

K = "#1b1420"
W, H, FY = 32, 48, 44

C = {
    "ink": "#2c2858", "ink_hi": "#4a46a0", "ink_lo": "#18153a", "ink_spec": "#9a98e0",
    "eye": "#ffd25a", "eye_hi": "#fff2b0",
    "paper": "#ebe2c9", "paper_lo": "#c4b796", "paper_dk": "#948866", "fold": "#a89a78",
    "red": "#a8343a", "red_hi": "#d0505a", "red_lo": "#6e2228",
    "toy": "#c99a62", "toy_hi": "#e0b880", "toy_lo": "#9a7044", "cheek": "#e07a70",
    "gold": "#d9ad4f", "gold_hi": "#f6dc8a", "gold_lo": "#9c7530",
    "brass": "#b8873a", "brass_hi": "#e0b555", "brass_lo": "#7d5a26", "brass_dk": "#5a3e18",
    "stone": "#6e6878", "stone_hi": "#8a8494", "stone_lo": "#4e4858", "stone_dk": "#38323f",
    "white": "#f4ecdc", "lamp": "#ffd27a", "lamp_hi": "#fff2c0",
    "pd": "#1e181c", "pp": "#2e2529", "ph": "#4a3c43", "pf": "#655560",
    "ember": "#f5a83a", "ember_hi": "#ffe0a0", "rust": "#9a3a2c", "rust_hi": "#c05a40",
    "leather": "#7d4d31", "leather_lo": "#4f2f20",
    "robe": "#4a3566", "robe_hi": "#6a4f8e", "robe_lo": "#2e2044",
    "skin": "#c49070", "skin_lo": "#9a6a50", "hair": "#c8c4cc", "hair_lo": "#8e8a96",
    "wood": "#7b5236", "wood_lo": "#523522",
}


def col(k):
    return C.get(k, k)


def put(c, x, y, k):
    c.put(x, y, col(k))


def ball(c, cx, cy, rx, ry, base, hi, lo, spec=None):
    """Elipse com luz do alto à esquerda."""
    for j in range(-ry, ry + 1):
        for i in range(-rx, rx + 1):
            d = (i * i) / max(rx * rx, 0.3) + (j * j) / max(ry * ry, 0.3)
            if d > 1.0:
                continue
            side = i / max(rx, 1) + j / max(ry, 1)
            k = base
            if side < -0.75 and d > 0.35:
                k = hi
            elif side > 0.7 and d > 0.3:
                k = lo
            put(c, cx + i, cy + j, k)
    if spec:
        put(c, cx - rx // 2, cy - ry // 2, spec)
        put(c, cx - rx // 2 + 1, cy - ry // 2, spec)


def box(c, x, y, w, h, base, hi, lo):
    for j in range(y, y + h):
        for i in range(x, x + w):
            put(c, i, j, base)
    for i in range(x, x + w):
        put(c, i, y, hi)
        put(c, i, y + h - 1, lo)
    for j in range(y, y + h):
        put(c, x, j, hi)
        put(c, x + w - 1, j, lo)


def line(c, x0, y0, x1, y1, k):
    c.line(x0, y0, x1, y1, col(k))


def shadow(c, w=7, y=FY, cx=16):
    for i in range(-w, w + 1):
        c.put(cx + i, y, "#0000004a" if abs(i) < w - 1 else "#00000030")
    for i in range(-w + 2, w - 1):
        c.put(cx + i, y + 1, "#00000030")


def finish(c):
    c.outline(K)
    return c


# ------------------------------------------------------------ Rastejo de Tinta

def rastejo(pose):
    c = Canvas(W, H)
    shadow(c, 10)
    sq = {"idle0": 0, "idle1": 1, "telegraph": -2, "charge": 0}[pose]
    stretch = 3 if pose == "charge" else 0
    top = 32 - sq
    # poça e corpo em gota
    ball(c, 16, 40, 10 + stretch + max(sq, 0), 4, "ink", "ink_hi", "ink_lo")
    ball(c, 16 - stretch // 2, top + 4, 8 + stretch, 6 + (1 if sq < 0 else 0) - max(sq, 0), "ink", "ink_hi", "ink_lo", "ink_spec")
    ball(c, 10 - stretch, 37, 3, 3, "ink", "ink_hi", "ink_lo")
    ball(c, 22 + stretch, 37, 3, 3, "ink", "ink_hi", "ink_lo")
    # penas de escrever espetadas no dorso
    bristle = -3 if pose == "telegraph" else 0
    for x0, x1, y1 in ((12, 7, top - 9 + bristle), (16, 16, top - 11 + bristle), (20, 25, top - 8 + bristle)):
        line(c, x0, top - 1, x1, y1, "paper")
        line(c, x0 + 1, top - 1, x1 + 1, y1, "paper_lo")
        put(c, x1, y1, "red_hi")
        put(c, x0, top, "gold")
    # olhos e boca
    eye = "white" if pose == "telegraph" else "eye"
    for ex in (12 - stretch // 2, 18 - stretch // 2):
        c.rect(ex, top + 2, 3, 3, col(eye))
        put(c, ex + 1, top + 3, K)
        put(c, ex, top + 2, "eye_hi" if pose != "telegraph" else "white")
    line(c, 13 - stretch // 2, top + 7, 19 - stretch // 2, top + 7, "ink_lo")
    if pose == "telegraph":
        for x in (14, 16, 18):
            put(c, x, top + 7, "white")
    # gotas que pingam
    for x, y in ((4, 42), (28, 41), (26, 44), (7, 44)):
        put(c, x, y, "ink")
        put(c, x, y - 1, "ink_hi")
    if pose == "charge":
        for y, x0 in ((34, 0), (38, 1), (42, 2)):
            line(c, x0, y, x0 + 3, y, "ink_lo")
    return finish(c)


# ------------------------------------------------------------ Mariposa de Papel

def wing(c, cx, cy, side, up, big=True):
    span = 11 if big else 8
    for i in range(span):
        h = (6 if big else 4) - abs(i - span // 3) // 2
        x = cx + side * (2 + i)
        y0 = cy - h - (up * (i + 1)) // span
        for y in range(y0, cy + (2 if big else 4)):
            put(c, x, y, "paper")
        put(c, x, y0, "white")
        put(c, x, cy + (1 if big else 3), "paper_lo")
    # dobras do origami
    line(c, cx + side * 2, cy, cx + side * (span - 1), cy - 4 - up // 2, "fold")
    line(c, cx + side * 3, cy + 1, cx + side * (span - 2), cy - 1 - up // 3, "paper_lo")


def mariposa(pose):
    if pose == "land":
        return mariposa_land()
    c = Canvas(W, H)
    shadow(c, 6, FY, 16)
    cy = 29
    up = {"fly0": 6, "fly1": -2, "dive": -4}[pose]
    for side in (-1, 1):
        wing(c, 16, cy + 4, side, up // 2, big=False)
        wing(c, 16, cy, side, up)
        ball(c, 16 + side * 7, cy - 3 - up // 3, 2, 2, "red", "red_hi", "red_lo")
        put(c, 16 + side * 7, cy - 3 - up // 3, "white")
        put(c, 16 + side * 9, cy + 5, "red")
    # corpo de brinquedo em gomos
    for i, y in enumerate(range(cy - 4, cy + 7, 2)):
        box(c, 15, y, 3, 2, "toy", "toy_hi", "toy_lo")
    ball(c, 16, cy - 6, 2, 2, "toy", "toy_hi", "toy_lo")
    put(c, 15, cy - 6, "eye")
    put(c, 17, cy - 6, "eye")
    line(c, 15, cy - 8, 12, cy - 12, "red")
    line(c, 17, cy - 8, 20, cy - 12, "red")
    put(c, 12, cy - 13, "gold")
    put(c, 20, cy - 13, "gold")
    return finish(c)


def mariposa_land():
    """Pousada, asas erguidas e juntas: vai mergulhar."""
    c = Canvas(W, H)
    shadow(c, 6)
    cy = 37
    for side in (-1, 1):
        for i in range(13):
            w = 1 + (i if i < 7 else 12 - i) // 2
            for x in range(1, w + 1):
                put(c, 16 + side * x, cy - 2 - i, "paper" if x < w else "paper_lo")
        line(c, 16 + side, cy - 3, 16 + side * 3, cy - 10, "fold")
        ball(c, 16 + side * 3, cy - 8, 1, 1, "red", "red_hi", "red_lo")
    for y in range(cy - 4, cy + 3, 2):
        box(c, 15, y, 3, 2, "toy", "toy_hi", "toy_lo")
    put(c, 15, cy - 5, "eye")
    put(c, 17, cy - 5, "eye")
    for x in (13, 19):
        line(c, x, cy + 2, x - (1 if x < 16 else -1), cy + 6, "toy_lo")
    return finish(c)


# ------------------------------------------------------------ Soldado de Corda

def soldado(pose):
    c = Canvas(W, H)
    shadow(c, 7)
    lean = {"idle": 0, "windup": -1, "strike": 1}[pose]
    x = 11 + lean
    # pernas de madeira com botas pretas
    for lx in (x + 1, x + 6):
        box(c, lx, 36, 4, 6, "white", "white", "paper_lo")
        box(c, lx, 41, 4, 3, "pd", "ph", "pd")
    # chave de corda nas costas
    box(c, x - 4, 27, 4, 2, "gold", "gold_hi", "gold_lo")
    ball(c, x - 5, 25, 1, 2, "gold", "gold_hi", "gold_lo")
    ball(c, x - 5, 31, 1, 2, "gold", "gold_hi", "gold_lo")
    # farda vermelha
    box(c, x, 25, 11, 12, "red", "red_hi", "red_lo")
    line(c, x + 1, 26, x + 9, 34, "white")
    line(c, x + 9, 26, x + 1, 34, "white")
    for by in (27, 30, 33):
        put(c, x + 5, by, "gold_hi")
    box(c, x, 35, 11, 2, "leather", "leather", "leather_lo")
    put(c, x + 5, 35, "gold")
    for ex in (x - 1, x + 10):       # dragonas
        box(c, ex, 24, 3, 2, "gold", "gold_hi", "gold_lo")
        put(c, ex + 1, 26, "gold_lo")
    # cabeça de madeira pintada
    box(c, x + 2, 17, 7, 8, "toy", "toy_hi", "toy_lo")
    put(c, x + 3, 20, K)
    put(c, x + 7, 20, K)
    put(c, x + 3, 22, "cheek")
    put(c, x + 7, 22, "cheek")
    line(c, x + 4, 23, x + 6, 23, "red_lo")
    for j in range(25, 27):
        put(c, x + 3, j, "toy_lo")
        put(c, x + 7, j, "toy_lo")
    # barretina alta com engrenagem e pluma
    box(c, x + 1, 8, 9, 9, "pd", "ph", "pd")
    line(c, x, 16, x + 10, 16, "gold")
    ball(c, x + 5, 12, 2, 2, "gold", "gold_hi", "gold_lo")
    put(c, x + 5, 12, "pd")
    for j, k in ((4, "white"), (5, "red_hi"), (6, "red"), (7, "red")):
        put(c, x + 8, j, k)
        put(c, x + 9, j + 1, k)
    # braço e sabre de madeira
    if pose == "idle":
        box(c, x + 11, 26, 3, 7, "red", "red_hi", "red_lo")
        put(c, x + 12, 33, "white")
        line(c, x + 13, 33, x + 13, 21, "paper")
        line(c, x + 14, 33, x + 14, 21, "paper_lo")
        line(c, x + 11, 33, x + 15, 33, "gold")
    elif pose == "windup":
        box(c, x + 11, 20, 3, 7, "red", "red_hi", "red_lo")
        put(c, x + 12, 19, "white")
        line(c, x + 12, 19, x + 18, 9, "paper")
        line(c, x + 13, 19, x + 19, 9, "paper_lo")
        line(c, x + 10, 18, x + 14, 20, "gold")
    else:
        box(c, x + 11, 29, 5, 3, "red", "red_hi", "red_lo")
        put(c, x + 16, 30, "white")
        line(c, x + 17, 30, x + 27, 30, "paper")
        line(c, x + 17, 31, x + 27, 31, "paper_lo")
        line(c, x + 16, 28, x + 16, 32, "gold")
        for i in range(3):          # risco do golpe
            put(c, x + 19 + i * 3, 27, "white")
    return finish(c)


# ------------------------------------------------------------ Guarda de Contrapeso

def guarda(pose):
    c = Canvas(W, H)
    shadow(c, 11)
    for lx in (8, 18):
        box(c, lx, 36, 6, 6, "brass_lo", "brass", "brass_dk")
        box(c, lx - 1, 41, 8, 3, "stone_dk", "stone_lo", "stone_dk")
    # tronco de latão com rebites e o fole/peito
    box(c, 6, 21, 20, 16, "brass", "brass_hi", "brass_lo")
    for rx, ry in ((8, 23), (23, 23), (8, 34), (23, 34)):
        put(c, rx, ry, "gold_hi")
    ball(c, 16, 27, 3, 3, "brass_lo", "brass", "brass_dk")
    ball(c, 16, 27, 1, 1, "lamp", "lamp_hi", "lamp")
    box(c, 12, 31, 8, 6, "red", "red_hi", "red_lo")
    for i in range(3):
        put(c, 14 + i * 2, 33, "gold")
    # contrapeso pendurado nas costas
    box(c, 26, 26, 4, 8, "stone_dk", "stone_lo", "stone_dk")
    line(c, 28, 21, 28, 26, "brass_dk")
    # elmo com visor aceso
    box(c, 10, 11, 12, 10, "brass", "brass_hi", "brass_lo")
    line(c, 11, 16, 20, 16, K)
    put(c, 13, 16, "lamp")
    put(c, 14, 16, "lamp_hi")
    put(c, 18, 16, "lamp")
    put(c, 19, 16, "lamp_hi")
    line(c, 16, 11, 16, 15, "brass_lo")
    ball(c, 16, 9, 3, 2, "red", "red_hi", "red_lo")
    for ox in (3, 23):               # ombreiras
        ball(c, ox + 3, 22, 3, 2, "brass_hi", "gold_hi", "brass")
    if pose == "open":
        box(c, 27, 22, 4, 18, "stone", "stone_hi", "stone_dk")   # escudo afastado
        put(c, 28, 30, "gold")
    else:
        box(c, 2, 22, 13, 19, "stone", "stone_hi", "stone_dk")
        line(c, 3, 26, 13, 26, "stone_lo")
        line(c, 3, 36, 13, 36, "stone_lo")
        box(c, 6, 29, 5, 5, "gold", "gold_hi", "gold_lo")
        ball(c, 8, 28, 2, 2, "gold_lo", "gold", "brass_dk")
        put(c, 8, 28, "stone")
        put(c, 8, 31, K)
        put(c, 8, 32, K)
        for rx, ry in ((3, 23), (13, 23), (3, 39), (13, 39)):
            put(c, rx, ry, "stone_hi")
    if pose == "raise":
        box(c, 24, 8, 5, 14, "brass", "brass_hi", "brass_lo")
        box(c, 22, 3, 9, 6, "stone_dk", "stone_lo", "stone_dk")
    return finish(c)


# ------------------------------------------------------------ Yame Black

def yame(pose):
    c = Canvas(W, H)
    shadow(c, 8)
    bright = pose == "telegraph"
    # manto de papel preto em dobras
    for i in range(13):
        w = 4 + i // 2
        for x in range(16 - w, 16 + w):
            k = "pp"
            if (x - (16 - w)) % 4 == 0:
                k = "ph"
            elif x >= 16 + w - 2:
                k = "pd"
            put(c, x, 29 + i, k)
    line(c, 9, 41, 22, 41, "pd")
    box(c, 11, 42, 3, 2, "pd", "ph", "pd")
    box(c, 18, 42, 3, 2, "pd", "ph", "pd")
    # bolsa e lanterna
    box(c, 19, 33, 5, 5, "leather", "leather", "leather_lo")
    put(c, 21, 34, "gold")
    box(c, 7, 33, 4, 5, "brass", "brass_hi", "brass_lo")
    put(c, 8, 35, "lamp_hi")
    put(c, 9, 35, "lamp")
    line(c, 9, 31, 9, 33, "brass_lo")
    # cabeça redonda e olhos de brasa
    ball(c, 16, 24, 6, 5, "pd", "ph", "pd")
    ek, eh = ("ember_hi", "white") if bright else ("ember", "ember_hi")
    for ex in (12, 18):
        c.rect(ex, 23, 3, 3 if bright else 2, col(ek))
        put(c, ex, 23, eh)
    # chapéu pontudo de papel dobrado, ponta enrolada
    for i in range(7):
        for x in range(10 + i, 22 - i // 2):
            put(c, x, 19 - i, "pp" if (x + i) % 5 else "pf")
    line(c, 8, 19, 23, 19, "pf")
    line(c, 17, 12, 21, 8, "pp")
    put(c, 22, 8, "pp")
    put(c, 22, 9, "pf")
    put(c, 21, 10, "pp")
    # cachecol vermelho esvoaçando
    line(c, 10, 29, 22, 29, "rust")
    line(c, 10, 30, 22, 30, "rust_hi")
    line(c, 10, 31, 6, 36, "rust")
    line(c, 11, 31, 7, 36, "rust_hi")
    if bright:
        line(c, 23, 27, 27, 22, "pd")        # braço erguido lançando
        box(c, 26, 18, 4, 4, "paper", "white", "paper_lo")
        for x, y in ((25, 16), (30, 17), (29, 23)):
            put(c, x, y, "ember_hi")
    return finish(c)


# ------------------------------------------------------------ Igris

IW, IH, IFY = 48, 64, 60


def igris(pose):
    c = Canvas(IW, IH)
    shadow(c, 13, IFY, 24)
    # pernas mecânicas com pistões
    for lx in (16, 26):
        box(c, lx, 46, 6, 12, "brass_lo", "brass", "brass_dk")
        line(c, lx + 2, 47, lx + 2, 56, "brass_hi")
        box(c, lx - 1, 56, 8, 4, "brass", "brass_hi", "brass_dk")
    # manto roxo rasgado
    box(c, 12, 35, 24, 15, "robe", "robe_hi", "robe_lo")
    for x in range(12, 36, 3):
        put(c, x, 50, "robe")
        put(c, x + 1, 51, "robe_lo")
    for x in (16, 32):
        line(c, x, 37, x, 49, "robe_lo")
    line(c, 24, 37, 24, 49, "gold_lo")
    for y in (40, 44, 48):
        put(c, 24, y, "gold")
    # tronco de latão com tubos de órgão
    box(c, 13, 21, 22, 15, "brass", "brass_hi", "brass_lo")
    for i, x in enumerate((18, 21, 24, 27, 30)):
        lit = pose == "free"
        line(c, x, 23 + i % 2, x, 33, "lamp" if lit else "brass_dk")
        put(c, x, 23 + i % 2, "gold_hi")
        put(c, x + 1, 25, "brass_hi")
    for rx, ry in ((15, 23), (33, 23), (15, 34), (33, 34)):
        put(c, rx, ry, "gold_hi")
    # sinos nos ombros
    for sx in (9, 39):
        ball(c, sx, 22, 5, 5, "brass_hi", "gold_hi", "brass")
        line(c, sx - 5, 27, sx + 5, 27, "brass_lo")
        put(c, sx, 28, "brass_dk")
    # cabeça humana cansada: cabelo grisalho e barba
    box(c, 19, 9, 10, 11, "skin", "skin", "skin_lo")
    box(c, 18, 5, 12, 5, "hair", "white", "hair_lo")
    line(c, 18, 9, 18, 15, "hair")
    line(c, 29, 9, 29, 14, "hair_lo")
    put(c, 21, 13, K)
    put(c, 26, 13, K)
    line(c, 20, 12, 22, 12, "hair_lo")
    line(c, 25, 12, 27, 12, "hair_lo")
    line(c, 21, 17, 26, 17, "hair")
    line(c, 22, 18, 25, 18, "hair_lo")
    put(c, 23, 15, "skin_lo")
    line(c, 17, 20, 31, 20, "robe_hi")
    # cajado com sino
    line(c, 41, 12, 41, 58, "wood")
    line(c, 42, 12, 42, 58, "wood_lo")
    ball(c, 42, 9, 3, 3, "brass", "brass_hi", "brass_lo")
    put(c, 42, 12, "brass_dk")
    if pose == "muffler":
        box(c, 17, 24, 14, 8, "wood", "wood", "wood_lo")    # abafador exposto
        line(c, 17, 24, 30, 24, "lamp")
        for x in range(19, 30, 3):
            put(c, x, 28, "wood_lo")
    if pose in ("regulator", "free"):
        ball(c, 24, 29, 4, 4, "gold", "gold_hi", "gold_lo")
        ball(c, 24, 29, 2, 2, "white" if pose == "regulator" else "lamp_hi", "white", "lamp")
    return finish(c)
