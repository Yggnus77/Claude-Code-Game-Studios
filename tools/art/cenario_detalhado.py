"""Cenário detalhado (segunda versão): ladrilhos 16×16 com sombreado,
variações e decoração de parede. Uma folha por tema, colunas nomeadas em
COLS; o jogo escolhe a variação pela posição.

Tema desta etapa: oficina de Exódia (tábuas, papel de parede, bancadas).
"""

import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixel import Canvas  # noqa: E402

T = 16

# Paleta da oficina: madeira quente, papel de parede verde-petróleo, latão.
O = {
    "plank": "#93643f", "plank_mid": "#8b5d3a", "plank_dk": "#835736", "plank_top": "#a2714a",
    "plank_hi": "#b47e52", "plank_lo": "#7e5434", "plank_gap": "#5a3a24",
    "grain": "#86593a", "nail": "#3a2618",
    "beam": "#3a2618", "beam_hi": "#523722", "beam_lo": "#24170f",
    "paper": "#2f4a48", "paper_hi": "#3f5f5a", "paper_dot": "#6b7f5a",
    "rail": "#b88a58", "panel": "#6e4a2e", "panel_hi": "#8a5e3a", "panel_lo": "#4e331f", "base": "#2a1a10",
    "glass": "#22325e", "glass_hi": "#4a6aa8", "moon": "#c9d8f0",
    "brass": "#c8963e", "brass_hi": "#f0c870", "brass_lo": "#7d5a26",
    "cream": "#ebe2c9", "cream_lo": "#bfb196",
    "bench": "#8a5a36", "bench_hi": "#a87048", "bench_lo": "#5e3c22",
    "red": "#9a3a34", "green": "#4f7a4a", "blue": "#3a5a9a", "paper_w": "#e8dfc8",
    "flame": "#ffd27a", "flame_hi": "#fff2c0", "ink": "#1b1420",
}


def rgba_put(c, x, y, key):
    c.put(x, y, O.get(key, key))


def floor(variant):
    """Tábuas longas: 4 fileiras de 4 px com o mesmo tom em todo ladrilho
    (as tábuas continuam de um ladrilho ao outro); só veios e emendas variam."""
    c = Canvas(T, T)
    rnd = random.Random(f"tabua-{variant}")
    tones = ["plank", "plank_mid", "plank", "plank_dk"]
    for i in range(4):
        y0 = i * 4
        for y in range(y0, y0 + 4):
            for x in range(T):
                rgba_put(c, x, y, tones[i])
        for x in range(T):
            rgba_put(c, x, y0, "plank_top")
            rgba_put(c, x, y0 + 3, "plank_gap")
        for _ in range(2):
            gx, gy = rnd.randrange(T - 5), y0 + 1 + rnd.randrange(2)
            for k in range(rnd.randrange(3, 7)):
                rgba_put(c, gx + k, gy, "grain")
    if variant >= 2:          # emenda numa das tábuas, com dois pregos
        i = (variant * 3 + 1) % 4
        jx = 4 + variant * 3
        for y in range(i * 4, i * 4 + 3):
            rgba_put(c, jx, y, "plank_gap")
        rgba_put(c, jx - 1, i * 4 + 1, "nail")
        rgba_put(c, jx + 1, i * 4 + 1, "nail")
    return c


def wall_top():
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            rgba_put(c, x, y, "beam")
    for y in (0, 8):
        for x in range(T):
            rgba_put(c, x, y, "beam_hi")
    for y in (7, 15):
        for x in range(T):
            rgba_put(c, x, y, "beam_lo")
    for x, y in ((3, 3), (11, 11), (7, 5), (13, 2)):
        rgba_put(c, x, y, "beam_lo")
    return c


def wall_base(c):
    """Papel de parede em cima, lambri de madeira embaixo."""
    for y in range(T):
        for x in range(T):
            rgba_put(c, x, y, "paper")
    for x in range(T):
        rgba_put(c, x, 0, "beam")
        rgba_put(c, x, 1, "beam_hi")
    for y in range(2, 9):
        for x in range(T):
            if (x + y * 2) % 6 == 0:
                rgba_put(c, x, y, "paper_dot")
            elif (x + y) % 6 == 3:
                rgba_put(c, x, y, "paper_hi")
    for x in range(T):
        rgba_put(c, x, 9, "rail")
        for y in range(10, 15):
            rgba_put(c, x, y, "panel")
        rgba_put(c, x, 10, "panel_hi")
        rgba_put(c, x, 15, "base")
    for x in (0, 8):
        for y in range(10, 15):
            rgba_put(c, x, y, "panel_lo")
        rgba_put(c, x + 1, 11, "panel_hi")


def wall_front(kind):
    c = Canvas(T, T)
    wall_base(c)
    if kind == "window":
        for y in range(2, 9):
            for x in range(3, 13):
                rgba_put(c, x, y, "glass")
        for x in range(3, 13):
            rgba_put(c, x, 2, "beam")
        for y in range(2, 9):
            rgba_put(c, 2, y, "beam")
            rgba_put(c, 13, y, "beam")
            rgba_put(c, 8, y, "beam_hi")
        rgba_put(c, 10, 4, "moon")
        rgba_put(c, 11, 4, "moon")
        rgba_put(c, 10, 3, "moon")
        rgba_put(c, 4, 7, "glass_hi")
        rgba_put(c, 5, 6, "glass_hi")
        for x in range(2, 14):
            rgba_put(c, x, 9, "rail")
    elif kind == "shelf":
        for x in range(1, 15):
            rgba_put(c, x, 7, "panel_hi")
            rgba_put(c, x, 8, "panel_lo")
        # frascos e livros
        for x, col, h in ((2, "red", 3), (4, "green", 4), (6, "blue", 3), (9, "brass", 2), (11, "red", 4), (12, "paper_w", 4), (13, "green", 3)):
            for y in range(7 - h, 7):
                rgba_put(c, x, y, col)
            rgba_put(c, x, 7 - h, "flame_hi" if col in ("green", "blue") else col)
    elif kind == "clock":
        cx, cy = 8, 5
        for y in range(-4, 5):
            for x in range(-4, 5):
                d = x * x + y * y
                if d <= 16:
                    rgba_put(c, cx + x, cy + y, "brass" if d > 9 else "cream")
        rgba_put(c, cx, cy, "ink")
        rgba_put(c, cx, cy - 1, "ink")
        rgba_put(c, cx, cy - 2, "ink")
        rgba_put(c, cx + 1, cy, "ink")
        rgba_put(c, cx - 3, cy - 3, "brass_hi")
        rgba_put(c, cx, cy - 3, "brass_lo")
        rgba_put(c, cx + 3, cy, "brass_lo")
    elif kind == "tools":
        for y in range(3, 9):
            for x in range(2, 14):
                rgba_put(c, x, y, "panel_lo")
        # chave inglesa, engrenagem, compasso
        for y in range(3, 8):
            rgba_put(c, 4, y, "cream_lo")
        rgba_put(c, 3, 3, "cream_lo")
        rgba_put(c, 5, 3, "cream_lo")
        for (x, y) in ((8, 4), (9, 4), (10, 4), (8, 6), (10, 6), (9, 7), (7, 5), (11, 5)):
            rgba_put(c, x, y, "brass")
        rgba_put(c, 9, 5, "brass_lo")
        rgba_put(c, 12, 3, "cream")
        rgba_put(c, 12, 4, "cream")
        rgba_put(c, 11, 6, "cream")
        rgba_put(c, 13, 6, "cream")
    elif kind == "lamp":
        rgba_put(c, 8, 7, "brass_lo")
        rgba_put(c, 7, 8, "brass")
        rgba_put(c, 8, 8, "brass")
        rgba_put(c, 9, 8, "brass")
        for y in range(3, 7):
            rgba_put(c, 7, y, "brass_lo")
            rgba_put(c, 9, y, "brass_lo")
        rgba_put(c, 8, 4, "flame")
        rgba_put(c, 8, 5, "flame_hi")
        rgba_put(c, 8, 3, "flame")
        rgba_put(c, 8, 2, "brass")
    return c


def wall_upper():
    """Topo da parede alta: sanca de madeira e papel de parede."""
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            rgba_put(c, x, y, "paper")
            if (x + y * 2) % 6 == 0:
                rgba_put(c, x, y, "paper_dot")
            elif (x + y) % 6 == 3:
                rgba_put(c, x, y, "paper_hi")
    for x in range(T):
        rgba_put(c, x, 0, "beam_lo")
        rgba_put(c, x, 1, "beam")
        rgba_put(c, x, 2, "beam_hi")
        rgba_put(c, x, 3, "beam_lo")
    return c


def wall_mid():
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            rgba_put(c, x, y, "paper")
            if (x + y * 2) % 6 == 0:
                rgba_put(c, x, y, "paper_dot")
            elif (x + y) % 6 == 3:
                rgba_put(c, x, y, "paper_hi")
    return c


def wall_lower():
    """Base da parede: friso, lambri com almofadas e rodapé."""
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            rgba_put(c, x, y, "panel")
    for x in range(T):
        rgba_put(c, x, 0, "rail")
        rgba_put(c, x, 1, "panel_lo")
        rgba_put(c, x, 14, "base")
        rgba_put(c, x, 15, "base")
    for x0 in (1, 9):
        for y in range(3, 12):
            rgba_put(c, x0, y, "panel_hi")
            rgba_put(c, x0 + 5, y, "panel_lo")
        for x in range(x0, x0 + 6):
            rgba_put(c, x, 3, "panel_hi")
            rgba_put(c, x, 12, "panel_lo")
    return c


def decor(kind):
    """Decoração de parede 16×32 (cobre a parte de cima e do meio)."""
    c = Canvas(T, 32)
    if kind == "window":
        for y in range(6, 28):
            for x in range(2, 14):
                rgba_put(c, x, y, "glass")
        for y in range(6, 28):
            rgba_put(c, 1, y, "beam")
            rgba_put(c, 14, y, "beam")
            rgba_put(c, 8, y, "beam_hi")
        for x in range(1, 15):
            rgba_put(c, x, 5, "beam_hi")
            rgba_put(c, x, 17, "beam_hi")
            rgba_put(c, x, 28, "rail")
        for x, y in ((10, 9), (11, 9), (10, 10), (11, 10), (12, 10), (11, 11)):
            rgba_put(c, x, y, "moon")
        for x, y in ((3, 25), (4, 24), (5, 23), (3, 14), (4, 13)):
            rgba_put(c, x, y, "glass_hi")
    elif kind == "shelf":
        for y in range(4, 30):
            rgba_put(c, 0, y, "beam")
            rgba_put(c, 15, y, "beam")
        for y in range(4, 30):
            for x in range(1, 15):
                rgba_put(c, x, y, "beam_lo")
        for sy in (13, 22, 29):
            for x in range(1, 15):
                rgba_put(c, x, sy, "panel_hi")
        items = [(2, "red", 5), (3, "red", 5), (5, "green", 4), (7, "blue", 6), (8, "blue", 6), (10, "brass", 3), (12, "paper_w", 5), (13, "cream_lo", 5)]
        for sy, shift in ((13, 0), (22, 1), (29, 2)):
            for x, col, h in items[shift:] + items[:shift]:
                for y in range(sy - h, sy):
                    rgba_put(c, x, y, col)
                rgba_put(c, x, sy - h, "flame_hi" if col in ("green", "blue") else col)
    elif kind == "clock":
        for y in range(4, 30):
            for x in range(3, 13):
                rgba_put(c, x, y, "beam")
            rgba_put(c, 3, y, "beam_hi")
            rgba_put(c, 12, y, "beam_lo")
        cx, cy = 8, 10
        for y in range(-4, 5):
            for x in range(-4, 5):
                d = x * x + y * y
                if d <= 17:
                    rgba_put(c, cx + x, cy + y, "brass" if d > 9 else "cream")
        for y in range(cy - 3, cy + 1):
            rgba_put(c, cx, y, "ink")
        rgba_put(c, cx + 1, cy, "ink")
        rgba_put(c, cx + 2, cy, "ink")
        for y in range(17, 27):
            rgba_put(c, 8, y, "brass_lo")
        for y in range(25, 28):
            for x in range(7, 10):
                rgba_put(c, x, y, "brass")
        rgba_put(c, 7, 25, "brass_hi")
    elif kind == "tools":
        for y in range(8, 26):
            for x in range(1, 15):
                rgba_put(c, x, y, "panel_lo")
            rgba_put(c, 1, y, "panel")
        for y in range(10, 20):
            rgba_put(c, 4, y, "cream_lo")
        for x in (3, 5):
            rgba_put(c, x, 10, "cream_lo")
        for (x, y) in ((9, 11), (10, 11), (11, 11), (8, 12), (12, 12), (8, 13), (12, 13), (9, 14), (10, 14), (11, 14)):
            rgba_put(c, x, y, "brass")
        rgba_put(c, 10, 12, "brass_hi")
        for y in range(17, 24):
            rgba_put(c, 11, y, "cream")
        rgba_put(c, 10, 23, "cream")
        rgba_put(c, 12, 23, "cream")
        for x in range(6, 9):
            rgba_put(c, x, 21, "red")
            rgba_put(c, x, 22, "red")
    elif kind == "lamp":
        rgba_put(c, 8, 20, "brass_lo")
        for x in (6, 7, 8, 9, 10):
            rgba_put(c, x, 21, "brass")
        for y in range(14, 20):
            rgba_put(c, 6, y, "brass_lo")
            rgba_put(c, 10, y, "brass_lo")
        for y in range(15, 20):
            for x in range(7, 10):
                rgba_put(c, x, y, "flame")
        rgba_put(c, 8, 16, "flame_hi")
        rgba_put(c, 8, 17, "flame_hi")
        for x in range(6, 11):
            rgba_put(c, x, 13, "brass")
        rgba_put(c, 8, 12, "brass_hi")
    elif kind == "picture":
        for y in range(8, 22):
            for x in range(2, 14):
                rgba_put(c, x, y, "brass")
        for y in range(10, 20):
            for x in range(4, 12):
                rgba_put(c, x, y, "glass")
        for x in range(4, 12):
            rgba_put(c, x, 17, "plank")
            rgba_put(c, x, 18, "plank_dk")
        for y in range(12, 17):
            rgba_put(c, 9, y, "cream")
        rgba_put(c, 9, 11, "flame")
    return c


DECOR = ["window", "shelf", "clock", "tools", "lamp", "picture"]


def bench_top(variant):
    """Tampo de bancada visto de cima, com coisas de relojoeiro."""
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            rgba_put(c, x, y, "bench")
    for x in range(T):
        rgba_put(c, x, 0, "bench_hi")
    for y in range(T):
        if y % 5 == 4:
            for x in range(T):
                rgba_put(c, x, y, "bench_lo")
    rnd = random.Random(f"bancada-{variant}")
    if variant == 0:      # engrenagens
        for cx, cy, r in ((5, 6, 3), (11, 10, 2)):
            for y in range(-r, r + 1):
                for x in range(-r, r + 1):
                    if x * x + y * y <= r * r:
                        rgba_put(c, cx + x, cy + y, "brass")
            rgba_put(c, cx, cy, "bench_lo")
            rgba_put(c, cx - 1, cy - r, "brass_hi")
    elif variant == 1:    # papel com desenho e tinteiro
        for y in range(3, 12):
            for x in range(2, 11):
                rgba_put(c, x, y, "paper_w")
        for x in range(3, 10):
            rgba_put(c, x, 6, "cream_lo")
        rgba_put(c, 5, 9, "blue")
        rgba_put(c, 6, 8, "blue")
        rgba_put(c, 12, 4, "ink")
        rgba_put(c, 13, 4, "ink")
        rgba_put(c, 12, 5, "ink")
        rgba_put(c, 13, 5, "ink")
    elif variant == 2:    # ferramentas
        for x in range(2, 10):
            rgba_put(c, x, 5, "cream_lo")
        rgba_put(c, 10, 4, "cream_lo")
        rgba_put(c, 10, 6, "cream_lo")
        for x in range(4, 12):
            rgba_put(c, x, 10, "panel_lo")
        rgba_put(c, 12, 10, "cream")
        rgba_put(c, 13, 10, "cream")
    else:                 # lamparina
        for y in range(4, 11):
            for x in range(6, 11):
                rgba_put(c, x, y, "brass_lo")
        for y in range(5, 10):
            for x in range(7, 10):
                rgba_put(c, x, y, "flame")
        rgba_put(c, 8, 7, "flame_hi")
    for _ in range(2):
        rgba_put(c, rnd.randrange(T), rnd.randrange(T), "bench_hi")
    return c


def bench_front():
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            rgba_put(c, x, y, "bench_lo")
    for x in range(T):
        rgba_put(c, x, 0, "bench_hi")
        rgba_put(c, x, 1, "bench")
        rgba_put(c, x, 15, "base")
    for x0 in (1, 9):
        for y in range(3, 13):
            for x in range(x0, x0 + 6):
                rgba_put(c, x, y, "bench")
        for x in range(x0, x0 + 6):
            rgba_put(c, x, 3, "bench_hi")
        rgba_put(c, x0 + 2, 7, "brass")
        rgba_put(c, x0 + 3, 7, "brass_hi")
    return c


def gap(edge):
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            rgba_put(c, x, y, "beam_lo")
    if edge:
        for y in range(4):
            for x in range(T):
                rgba_put(c, x, y, "plank_lo")
        for x in range(T):
            rgba_put(c, x, 4, "ink")
    return c


COLS = ["wall_upper", "wall_mid", "wall_lower", "floor_a", "floor_b", "floor_c", "floor_d", "wall_top", "wall_front", "wall_window",
        "wall_shelf", "wall_clock", "wall_tools", "wall_lamp", "furn_top_a", "furn_top_b",
        "furn_top_c", "furn_top_d", "furn_front", "gap", "gap_edge"]


def tiles_oficina():
    return [wall_upper(), wall_mid(), wall_lower(), floor(0), floor(1), floor(2), floor(3), wall_top(), wall_front(""), wall_front("window"),
            wall_front("shelf"), wall_front("clock"), wall_front("tools"), wall_front("lamp"),
            bench_top(0), bench_top(1), bench_top(2), bench_top(3), bench_front(), gap(False), gap(True)]
