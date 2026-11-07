"""Yggnus, roupa inicial: folha de quadros 32×48, pivô [16,44].

Linhas: 0 = de frente (baixo), 1 = de costas (cima), 2 = de lado (direita;
o jogo espelha para a esquerda). Colunas: ver ANIMS. Fonte de cores e
proporções: design/art/art-bible.md (Seções 4, 5 e 8) e a ilustração
yggnus.png do kit.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixel import Canvas, sheet  # noqa: E402

W, H = 32, 48
FOOT_Y = 44

# Pose: bob (corpo sobe/desce), pés (dx, dy), braços (dx, dy), extras.
BASE = {"bob": 0, "lf": (0, 0), "rf": (0, 0), "la": (0, 0), "ra": (0, 0),
        "blade": None, "shield": False, "hurt": False, "tool": False, "crouch": 0,
        "stride": 0}


def pose(**kw):
    p = dict(BASE)
    p.update(kw)
    return p


# Ordem das colunas e quantos quadros cada animação usa.
POSES = [
    ("idle", pose()),
    ("idle", pose(bob=1)),
    ("walk", pose(lf=(0, -2), rf=(0, 0), la=(0, 1), ra=(0, -1), bob=-1, stride=2)),
    ("walk", pose(lf=(0, 0), rf=(0, 0), bob=0)),
    ("walk", pose(lf=(0, 0), rf=(0, -2), la=(0, -1), ra=(0, 1), bob=-1, stride=-2)),
    ("walk", pose(lf=(0, 0), rf=(0, 0), bob=0)),
    ("slash1", pose(ra=(1, -4), blade="wind_r", bob=0)),
    ("slash1", pose(ra=(0, 2), blade="hit_r", bob=1, lf=(0, 0))),
    ("slash2", pose(la=(-1, -4), blade="wind_l", bob=0)),
    ("slash2", pose(la=(0, 2), blade="hit_l", bob=1)),
    ("slash3", pose(ra=(0, -6), la=(0, -6), blade="wind_up", bob=-1)),
    ("slash3", pose(ra=(0, 3), la=(0, 3), blade="hit_down", bob=2, crouch=1)),
    ("slash3", pose(ra=(0, 2), la=(0, 2), blade="rest", bob=2, crouch=1)),
    ("guard", pose(shield=True, bob=1)),
    ("guard", pose(shield=True, bob=0)),
    ("dodge", pose(bob=3, crouch=2, la=(-1, 2), ra=(1, 2))),
    ("dodge", pose(bob=6, crouch=4, la=(0, 3), ra=(0, 3))),
    ("hurt", pose(hurt=True, bob=-1, la=(-2, -2), ra=(2, -2))),
    ("fall", pose(bob=5, crouch=3, la=(0, 4), ra=(0, 4))),
    ("fall", "lying"),
    ("tool", pose(tool=True, ra=(1, -1))),
]


def anims():
    out = {}
    for i, (name, _) in enumerate(POSES):
        out.setdefault(name, []).append(i)
    return out


def shadow(c, p):
    w = 6 if p == "lying" else 5
    for i in range(-w, w + 1):
        c.put(15 + i, FOOT_Y, "#00000040")
        c.put(16 + i, FOOT_Y, "#00000040")
    for i in range(-w + 2, w - 1):
        c.put(16 + i, FOOT_Y + 1, "#00000030")


# ---------------------------------------------------------------- frente

def legs_front(c, p, back=False):
    b = p["bob"]
    knee = p["crouch"]
    for side, x0, foot in (("l", 11, p["lf"]), ("r", 17, p["rf"])):
        dx, dy = foot
        # calça larga
        top = 34 + b - (0 if knee == 0 else 0)
        bottom = 40 + dy
        c.rect(x0 + dx, top, 4, max(bottom - top, 1), "pants")
        c.vline(x0 + dx + (3 if side == "l" else 0), top, bottom - 1, "pants_lo")
        c.rect(x0 + dx - (1 if side == "l" else -1), top + 2, 1, 3, "pants")
        # meia de tecido e bota
        c.hline(x0 + dx, x0 + dx + 3, bottom - 1, "cloth_lo")
        c.rect(x0 + dx, bottom, 4, 4, "boot")
        c.hline(x0 + dx, x0 + dx + 3, bottom, "boot_hi")
        c.put(x0 + dx + 1, bottom + 1, "gold_lo")
        if not back:
            c.hline(x0 + dx - (1 if side == "l" else 0), x0 + dx + 3 + (0 if side == "l" else 1), bottom + 3, "boot")


def torso_front(c, p):
    b = p["bob"]
    y = 22 + b
    # aba do casaco (até o joelho)
    c.rect(9, y + 7, 14, 9 - min(p["crouch"], 3), "coat")
    c.vline(9, y + 7, y + 15 - min(p["crouch"], 3), "gold")
    c.vline(22, y + 7, y + 15 - min(p["crouch"], 3), "gold")
    c.rect(14, y + 8, 4, 8 - min(p["crouch"], 3), "leather_lo")   # frente aberta
    c.vline(13, y + 8, y + 15 - min(p["crouch"], 3), "gold")
    c.vline(18, y + 8, y + 15 - min(p["crouch"], 3), "gold")
    # peito
    c.rect(10, y, 12, 8, "coat")
    c.rect(10, y, 1, 8, "coat_hi")
    c.rect(21, y, 1, 8, "coat_lo")
    c.rect(14, y, 4, 6, "cloth")             # camisa
    c.vline(15, y + 1, y + 5, "cloth_lo")
    # bandoleira e cinto
    c.line(11, y, 19, y + 7, "leather")
    c.put(15, y + 4, "gold")
    c.hline(10, 21, y + 7, "leather")
    c.rect(15, y + 7, 2, 1, "gold")
    # bolsa no quadril e relógio de bolso
    c.rect(19, y + 8, 3, 3, "leather_hi")
    c.put(12, y + 9, "gold")
    c.put(12, y + 10, "gold_lo")


def arm_front(c, p, side):
    b = p["bob"]
    dx, dy = p["la"] if side == "l" else p["ra"]
    x = 7 if side == "l" else 22
    y = 23 + b + dy
    c.rect(x + dx, y, 3, 7, "coat")
    c.vline(x + dx + (0 if side == "l" else 2), y, y + 6, "coat_lo")
    c.hline(x + dx, x + dx + 2, y + 6, "cloth")            # punho dobrado
    c.rect(x + dx, y + 7, 3, 2, "skin")
    c.put(x + dx + 1, y + 8, "leather_lo")                 # luva sem dedos


def head_front(c, p, back=False):
    b = p["bob"]
    y = 11 + b
    # rosto
    c.rect(12, y + 1, 8, 8, "skin")
    c.hline(13, 18, y + 9, "skin_lo")
    c.put(12, y + 8, "skin_lo")
    c.put(19, y + 8, "skin_lo")
    # cabelo cacheado
    c.rect(11, y - 3, 10, 4, "hair")
    c.rect(11, y + 1, 1, 4, "hair")
    c.rect(20, y + 1, 1, 4, "hair")
    for tx, ty in ((11, y - 4), (13, y - 5), (16, y - 5), (18, y - 4), (20, y - 3), (10, y - 1), (21, y)):
        c.put(tx, ty, "hair")
    for tx, ty in ((14, y - 3), (17, y - 2), (12, y - 1)):
        c.put(tx, ty, "hair_hi")
    if back:
        c.rect(11, y + 1, 10, 7, "hair")
        c.put(13, y + 3, "hair_hi")
        c.put(18, y + 5, "hair_hi")
        c.rect(14, y + 8, 4, 2, "skin_lo")                 # nuca
        return
    c.hline(12, 19, y + 1, "hair")                         # franja
    c.put(13, y + 2, "hair")
    c.put(18, y + 2, "hair")
    if p["hurt"]:
        c.hline(13, 14, y + 4, "outline")
        c.hline(17, 18, y + 4, "outline")
    else:
        c.put(13, y + 3, "hair")                           # sobrancelha
        c.put(18, y + 3, "hair")
        c.put(14, y + 4, "outline")
        c.put(17, y + 4, "outline")
        c.put(14, y + 5, "skin_hi")
    c.put(15, y + 6, "skin_lo")
    c.hline(15, 16, y + 7, "skin_lo")


def scarf_front(c, p, back=False):
    b = p["bob"]
    y = 20 + b
    c.rect(11, y, 10, 3, "cloth")
    c.hline(11, 20, y + 2, "cloth_lo")
    if back:
        c.rect(12, y + 2, 3, 5, "cloth")
        c.vline(12, y + 7, y + 7, "cloth_lo")
    else:
        c.rect(18, y + 3, 2, 4, "cloth")
        c.put(18, y + 7, "cloth_lo")
        c.put(19, y + 7, "cloth_lo")


def blade_front(c, p):
    b = p["bob"]
    kind = p["blade"]
    if kind is None:
        # bainha à esquerda (lado do quadril)
        c.line(9, 30 + b, 7, 38 + b, "leather_lo")
        c.put(9, 29 + b, "gold")
        return
    if kind == "wind_r":
        c.line(24, 22 + b, 28, 14 + b, "steel")
        c.line(25, 22 + b, 29, 14 + b, "steel_lo")
        c.hline(23, 26, 23 + b, "gold")
    elif kind == "hit_r":
        c.line(22, 33 + b, 13, 41 + b, "steel")
        c.line(22, 34 + b, 14, 41 + b, "steel_lo")
        c.vline(23, 31 + b, 34 + b, "gold")
    elif kind == "wind_l":
        c.line(8, 22 + b, 3, 14 + b, "steel")
        c.line(7, 22 + b, 2, 14 + b, "steel_lo")
        c.hline(6, 9, 23 + b, "gold")
    elif kind == "hit_l":
        c.line(10, 33 + b, 19, 41 + b, "steel")
        c.line(10, 34 + b, 18, 41 + b, "steel_lo")
        c.vline(8, 31 + b, 34 + b, "gold")
    elif kind == "wind_up":
        c.vline(16, 3 + b, 16 + b, "steel")
        c.vline(17, 3 + b, 16 + b, "steel_lo")
        c.hline(14, 19, 17 + b, "gold")
    elif kind in ("hit_down", "rest"):
        c.vline(15, 33 + b, 46, "steel")
        c.vline(16, 33 + b, 46, "steel_lo")
        c.hline(13, 18, 32 + b, "gold")


def shield_front(c, p):
    b = p["bob"]
    c.ellipse(15, 29 + b, 6, 6, "brass")
    c.ellipse(15, 29 + b, 4, 4, "brass_hi")
    c.ellipse(15, 29 + b, 2, 2, "brass")
    c.put(15, 29 + b, "brass_lo")
    for i in range(-6, 7):
        c.put(15 + i, 35 + b, "brass_lo") if abs(i) < 3 else None


def tool_front(c, p):
    b = p["bob"]
    c.rect(22, 33 + b, 4, 3, "brass")
    c.put(25, 34 + b, "brass_hi")
    c.vline(24, 36 + b, 40 + b, "steel_lo")
    c.put(23, 41 + b, "steel")
    c.put(25, 41 + b, "steel")


def draw_front(p):
    c = Canvas(W, H)
    shadow(c, p)
    legs_front(c, p)
    torso_front(c, p)
    if p["blade"] != "wind_up":
        arm_front(c, p, "l")
        arm_front(c, p, "r")
    scarf_front(c, p)
    head_front(c, p)
    if p["blade"] == "wind_up":
        arm_front(c, p, "l")
        arm_front(c, p, "r")
    blade_front(c, p)
    if p["shield"]:
        shield_front(c, p)
    if p["tool"]:
        tool_front(c, p)
    c.outline()
    return c


# ---------------------------------------------------------------- costas

def draw_back(p):
    c = Canvas(W, H)
    shadow(c, p)
    if p["blade"] in ("hit_down", "rest", "hit_r", "hit_l"):
        pass
    legs_front(c, p, back=True)
    b = p["bob"]
    y = 22 + b
    cr = min(p["crouch"], 3)
    c.rect(9, y, 14, 16 - cr, "coat")
    c.rect(10, y, 1, 8, "coat_hi")
    c.vline(9, y + 7, y + 15 - cr, "gold")
    c.vline(22, y + 7, y + 15 - cr, "gold")
    c.hline(9, 22, y + 15 - cr, "gold")
    c.vline(15, y + 8, y + 15 - cr, "coat_lo")               # fenda
    # farol bordado (dourado) nas costas
    c.vline(18, y + 9, y + 12 - (1 if cr else 0), "gold")
    c.put(18, y + 8, "gold_lo")
    c.hline(17, 19, y + 13 - cr, "gold_lo")
    c.hline(10, 21, y + 7, "leather")
    # bolsa nas costas
    c.rect(11, y + 8, 3, 3, "leather")
    for side in ("l", "r"):
        arm_front(c, p, side)
    scarf_front(c, p, back=True)
    head_front(c, p, back=True)
    k = p["blade"]
    if k is None:
        c.line(20, 23 + b, 23, 31 + b, "leather_lo")
    elif k in ("wind_r", "wind_l", "wind_up"):
        x = 25 if k == "wind_r" else (6 if k == "wind_l" else 16)
        c.vline(x, 8 + b, 21 + b, "steel")
        c.hline(x - 2, x + 2, 22 + b, "gold")
    if p["shield"]:
        c.hline(9, 22, 21 + b, "brass")
        c.hline(10, 21, 20 + b, "brass_hi")
    c.outline()
    return c


# ---------------------------------------------------------------- lado

def draw_side(p):
    c = Canvas(W, H)
    shadow(c, p)
    b = p["bob"]
    cr = min(p["crouch"], 3)
    # pernas: trás (mais escura) e frente
    for which, x0, foot, col, lo in (("back", 13, p["lf"], "pants_lo", "pants_lo"), ("front", 16, p["rf"], "pants", "pants_lo")):
        dx, dy = 0, 0
        st = p["stride"]
        sx = x0 + (st if which == "front" else -st)
        if (which == "front" and st > 0) or (which == "back" and st < 0):
            dy = -1
        c.rect(sx, 34 + b, 4, 40 + dy - (34 + b), col)
        c.vline(sx + 3, 34 + b, 39 + dy, lo)
        c.rect(sx, 40 + dy, 4, 4, "boot")
        c.put(sx + 4, 43 + dy, "boot")                    # bico da bota
        c.hline(sx, sx + 3, 40 + dy, "boot_hi")
    y = 22 + b
    # aba do casaco (atrás se abre)
    c.rect(11, y + 7, 9, 9 - cr, "coat")
    c.vline(10, y + 9, y + 15 - cr, "coat_lo")
    c.hline(10, 19, y + 15 - cr, "gold")
    c.vline(19, y + 8, y + 15 - cr, "gold")
    c.rect(12, y, 8, 8, "coat")
    c.vline(19, y, y + 7, "coat_hi")
    c.hline(12, 19, y + 7, "leather")
    c.put(19, y + 7, "gold")
    c.rect(11, y + 8, 3, 3, "leather_hi")                 # bolsa
    # bainha
    if p["blade"] is None:
        c.line(13, y + 8, 9, y + 15, "leather_lo")
    # cachecol voando para trás
    c.rect(13, 20 + b, 7, 3, "cloth")
    c.hline(13, 19, 22 + b, "cloth_lo")
    c.line(12, 21 + b, 10, 23 + b, "cloth")
    c.put(10, 24 + b, "cloth_lo")
    # cabeça de perfil
    hy = 11 + b
    c.rect(13, hy + 1, 7, 8, "skin")
    c.hline(14, 19, hy + 9, "skin_lo")
    c.put(20, hy + 5, "skin")                              # nariz
    c.rect(12, hy - 3, 8, 4, "hair")
    c.rect(11, hy + 1, 4, 6, "hair")
    for tx, ty in ((12, hy - 4), (15, hy - 5), (18, hy - 4), (10, hy - 1), (10, hy + 3), (20, hy - 2)):
        c.put(tx, ty, "hair")
    c.put(15, hy - 2, "hair_hi")
    c.put(14, hy + 4, "skin_lo")                           # orelha
    if p["hurt"]:
        c.hline(17, 18, hy + 4, "outline")
    else:
        c.put(18, hy + 4, "outline")
        c.put(18, hy + 3, "hair")
    c.put(19, hy + 7, "skin_lo")
    # braço da frente
    dx, dy = p["ra"]
    ax, ay = 15 + dx, 23 + b + dy
    k = p["blade"]
    if k in ("hit_r", "hit_l", "hit_down", "rest"):
        c.rect(16, 26 + b, 6, 3, "coat")                   # braço estendido
        c.rect(22, 26 + b, 2, 3, "skin")
        c.hline(24, 31, 27 + b, "steel")
        c.hline(24, 31, 28 + b, "steel_lo")
        c.vline(23, 25 + b, 29 + b, "gold")
    elif k in ("wind_r", "wind_l", "wind_up"):
        c.rect(13, 19 + b, 3, 6, "coat")                   # braço erguido atrás
        c.rect(13, 17 + b, 3, 2, "skin")
        c.line(13, 16 + b, 7, 8 + b, "steel")
        c.line(14, 16 + b, 8, 8 + b, "steel_lo")
        c.hline(12, 16, 17 + b, "gold")
        c.rect(ax, ay + 2, 3, 6, "coat_lo")
    else:
        c.rect(ax, ay, 3, 7, "coat")
        c.vline(ax + 2, ay, ay + 6, "coat_hi")
        c.hline(ax, ax + 2, ay + 6, "cloth")
        c.rect(ax, ay + 7, 3, 2, "skin")
    if p["shield"]:
        c.rect(20, 22 + b, 3, 12, "brass")
        c.vline(21, 23 + b, 32 + b, "brass_hi")
        c.put(22, 27 + b, "brass_lo")
    if p["tool"]:
        c.rect(18, 27 + b, 6, 3, "coat")
        c.rect(24, 26 + b, 4, 4, "brass")
        c.put(27, 27 + b, "brass_hi")
    c.outline()
    return c


def draw_lying(view):
    """Caído: deitado de lado, igual nas três linhas."""
    c = Canvas(W, H)
    shadow(c, "lying")
    y = 38
    c.rect(6, y, 6, 5, "hair")                             # cabeça
    c.rect(8, y + 1, 4, 4, "skin")
    c.rect(12, y, 3, 5, "cloth")                           # cachecol
    c.rect(15, y, 9, 5, "coat")
    c.hline(15, 23, y + 4, "gold")
    c.rect(24, y + 1, 4, 3, "pants")
    c.rect(28, y + 1, 2, 4, "boot")
    c.outline()
    return c


def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out_dir = os.path.join(root, "assets", "art", "personagens")
    os.makedirs(out_dir, exist_ok=True)
    frames = []
    for view, draw in (("down", draw_front), ("up", draw_back), ("side", draw_side)):
        for _, p in POSES:
            frames.append(draw_lying(view) if p == "lying" else draw(p))
    img = sheet(frames, len(POSES))
    img.save(os.path.join(out_dir, "yggnus.png"))
    meta = {
        "frame_size": [W, H], "pivot": [16, FOOT_Y],
        "rows": {"down": 0, "up": 1, "side": 2}, "side_faces": "right",
        "anims": anims(),
        "fps": {"idle": 2, "walk": 8, "guard": 4, "dodge": 12, "fall": 6},
    }
    with open(os.path.join(out_dir, "yggnus.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    print("yggnus.png", img.size, len(frames), "quadros")


if __name__ == "__main__":
    main()
