"""Inimigos da fatia, Yame Black e Igris.

inimigos.png: quadros 32×48, pivô [16,44] (os pés), colunas em FRAMES.
igris.png: quadros 48×64, pivô [24,60], colunas em IGRIS_FRAMES.
Referência: pranchas 08 e 09 e as ilustrações de Yame e Igris do kit.
Guia: design/art/art-bible.md, Seção 5.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixel import PAL, Canvas, sheet  # noqa: E402

PAL.update({
    "ink": "#2a2550", "ink_hi": "#4a4590", "ink_lo": "#161330",
    "eye": "#ffd25a",
    "red": "#9a2f2f", "red_hi": "#c04848",
    "toy": "#c99a62", "toy_lo": "#9a7044",
})

W, H = 32, 48
FY = 44


def shadow(c, w=7, y=FY):
    for i in range(-w, w + 1):
        c.put(16 + i, y, "#00000044")
    for i in range(-w + 2, w - 1):
        c.put(16 + i, y + 1, "#00000030")


# ---------------------------------------------------------------- Rastejo

def rastejo(pose):
    c = Canvas(W, H)
    shadow(c, 9)
    squash = {"idle0": 0, "idle1": 1, "telegraph": 2, "charge": -1}[pose]
    top = 33 + squash
    # corpo de tinta (três bolhas)
    c.ellipse(16, 39, 9 + max(squash, 0), 5 - max(squash, 0) // 2, "ink")
    c.ellipse(12, top + 4, 5, 4, "ink")
    c.ellipse(20, top + 4, 5, 4, "ink")
    c.ellipse(16, top + 2, 6, 5, "ink")
    c.hline(12, 17, top - 2, "ink_hi")
    c.put(11, top + 1, "ink_hi")
    c.hline(8, 24, 43, "ink_lo")
    # olhos
    eye = "white" if pose == "telegraph" else "eye"
    c.rect(13, top + 4, 2, 2, eye)
    c.rect(18, top + 4, 2, 2, eye)
    # penas de escrita
    for x0, x1, y1 in ((13, 9, top - 10), (16, 17, top - 12), (19, 23, top - 9)):
        c.line(x0, top - 1, x1, y1, "cloth")
        c.line(x0 + 1, top - 1, x1 + 1, y1, "red")
    # gotas
    for x, y in ((5, 42), (27, 41), (25, 44)):
        c.put(x, y, "ink")
    if pose == "charge":
        for x in range(3, 8):
            c.put(x, 38 + (x % 2), "ink_lo")
    c.outline()
    return c


# ---------------------------------------------------------------- Mariposa

def mariposa(pose):
    c = Canvas(W, H)
    cy = 30
    up = {"fly0": -4, "fly1": 1, "dive": 3}[pose]
    for side in (-1, 1):
        # asa superior
        for i in range(10):
            span = 10 - abs(i - 4)
            y = cy - 2 + (i - 5) + (up if i < 5 else 0)
            x0 = 16 + side * 2
            c.hline(x0, x0 + side * span, y, "cloth")
        # asa inferior
        for i in range(5):
            c.hline(16 + side * 2, 16 + side * (8 - i), cy + 2 + i, "cloth_lo")
        # marca vermelha de alvo
        c.ellipse(16 + side * 7, cy - 3 + up // 2, 2, 2, "red")
        c.put(16 + side * 7, cy - 3 + up // 2, "cloth")
        c.put(16 + side * 9, cy + 4, "red")
    c.rect(15, cy - 4, 2, 10, "toy")
    c.rect(15, cy - 6, 2, 2, "toy_lo")
    c.put(15, cy - 5, "eye")
    c.put(16, cy - 5, "eye")
    c.line(15, cy - 7, 12, cy - 11, "red")
    c.line(16, cy - 7, 19, cy - 11, "red")
    c.outline()
    return c


# ---------------------------------------------------------------- Soldado de Corda

def soldado(pose):
    c = Canvas(W, H)
    shadow(c, 6)
    lean = {"idle": 0, "windup": -1, "strike": 1}[pose]
    x = 12 + lean
    # pernas de madeira
    c.rect(x + 1, 37, 3, 6, "toy")
    c.rect(x + 5, 37, 3, 6, "toy")
    c.rect(x + 1, 42, 3, 2, "wood_lo")
    c.rect(x + 5, 42, 3, 2, "wood_lo")
    # corpo com farda vermelha e cordas
    c.rect(x, 26, 9, 12, "red")
    c.vline(x, 26, 37, "red_hi")
    c.line(x, 28, x + 8, 34, "cloth_lo")
    c.line(x, 33, x + 8, 29, "cloth_lo")
    c.hline(x, x + 8, 36, "leather")
    # cabeça de boneco
    c.rect(x + 1, 19, 7, 7, "toy")
    c.put(x + 3, 22, "outline")
    c.put(x + 6, 22, "outline")
    c.hline(x + 4, x + 5, 24, "toy_lo")
    # chapéu alto com engrenagem
    c.rect(x, 11, 9, 8, "red")
    c.hline(x - 1, x + 9, 18, "gold_lo")
    c.ellipse(x + 4, 14, 2, 2, "gold")
    c.put(x + 4, 14, "gold_lo")
    # chave de corda nas costas
    c.rect(x - 4, 27, 3, 2, "gold")
    c.rect(x - 5, 25, 2, 6, "gold")
    # braço e espada de madeira
    if pose == "idle":
        c.rect(x + 9, 28, 2, 6, "toy")
        c.vline(x + 11, 23, 34, "gold")
    elif pose == "windup":
        c.rect(x + 9, 22, 2, 6, "toy")
        c.line(x + 10, 21, x + 15, 12, "gold")
        c.line(x + 11, 21, x + 16, 12, "gold_lo")
    else:
        c.rect(x + 9, 30, 4, 2, "toy")
        c.hline(x + 13, x + 22, 31, "gold")
        c.hline(x + 13, x + 22, 32, "gold_lo")
    c.outline()
    return c


# ---------------------------------------------------------------- Guarda de Contrapeso

def guarda(pose):
    c = Canvas(W, H)
    shadow(c, 10)
    # pernas
    c.rect(9, 37, 5, 6, "brass_lo")
    c.rect(18, 37, 5, 6, "brass_lo")
    c.rect(8, 42, 7, 2, "outline")
    c.rect(17, 42, 7, 2, "outline")
    # tronco de latão
    c.rect(7, 22, 18, 16, "brass")
    c.vline(7, 22, 37, "brass_hi")
    c.vline(24, 22, 37, "brass_lo")
    c.ellipse(16, 28, 3, 3, "brass_lo")
    c.ellipse(16, 28, 1, 1, "lamp")
    c.rect(13, 32, 6, 6, "red")                    # estandarte
    c.put(15, 34, "gold")
    # elmo com visor
    c.rect(11, 13, 10, 9, "brass")
    c.hline(11, 20, 13, "brass_hi")
    c.hline(12, 19, 17, "outline")
    c.put(14, 17, "lamp")
    c.put(17, 17, "lamp")
    c.ellipse(16, 11, 2, 2, "brass_lo")
    # ombreiras
    c.rect(4, 21, 5, 4, "brass_hi")
    c.rect(23, 21, 5, 4, "brass_hi")
    if pose == "open":
        # escudo afastado: o corpo fica exposto
        c.rect(26, 24, 4, 16, "stone_lo")
        c.vline(26, 24, 39, "stone")
    else:
        # escudo grande com cadeado, à frente
        c.rect(3, 23, 12, 18, "stone")
        c.rect(3, 23, 12, 2, "stone_hi")
        c.vline(14, 23, 40, "stone_dk")
        c.rect(7, 30, 4, 4, "gold")
        c.ellipse(8, 29, 2, 2, "gold_lo")
        c.put(8, 29, "stone")
    if pose == "raise":
        c.rect(24, 9, 5, 13, "brass")             # braço erguendo o peso
    c.outline()
    return c


# ---------------------------------------------------------------- Yame Black

def yame(pose):
    c = Canvas(W, H)
    shadow(c, 7)
    # corpo de papel preto, em dobras
    for i in range(12):
        w = 4 + i // 2
        c.hline(16 - w, 15 + w, 30 + i, "paper" if i % 3 else "paper_hi")
    c.hline(9, 22, 41, "paper_dk")
    c.rect(11, 42, 3, 2, "paper_dk")
    c.rect(18, 42, 3, 2, "paper_dk")
    # cabeça redonda
    c.ellipse(16, 24, 6, 5, "paper_dk")
    bright = pose == "telegraph"
    c.rect(12, 23, 3, 3 if bright else 2, "ember_hi" if bright else "ember")
    c.rect(18, 23, 3, 3 if bright else 2, "ember_hi" if bright else "ember")
    # chapéu pontudo com ponta enrolada
    for i in range(6):
        c.hline(10 + i, 21 - i // 2, 19 - i, "paper")
    c.hline(8, 23, 19, "paper_hi")
    c.line(17, 13, 21, 9, "paper")
    c.put(22, 9, "paper")
    c.put(22, 10, "paper")
    # cachecol vermelho
    c.hline(10, 22, 29, "rust")
    c.line(10, 30, 7, 35, "rust_hi")
    # bolsa e lanterna
    c.rect(19, 33, 5, 5, "leather")
    c.put(21, 35, "gold")
    c.rect(8, 34, 3, 4, "brass")
    c.put(9, 35, "lamp_hi")
    if bright:
        c.line(23, 26, 27, 22, "paper_dk")       # braço erguido lançando
        c.rect(26, 19, 3, 3, "cloth")
    c.outline()
    return c


FRAMES = [
    ("rastejo_idle0", rastejo, "idle0"), ("rastejo_idle1", rastejo, "idle1"),
    ("rastejo_telegraph", rastejo, "telegraph"), ("rastejo_charge", rastejo, "charge"),
    ("mariposa_fly0", mariposa, "fly0"), ("mariposa_fly1", mariposa, "fly1"),
    ("mariposa_dive", mariposa, "dive"),
    ("soldado_idle", soldado, "idle"), ("soldado_windup", soldado, "windup"),
    ("soldado_strike", soldado, "strike"),
    ("guarda_idle", guarda, "idle"), ("guarda_raise", guarda, "raise"), ("guarda_open", guarda, "open"),
    ("yame_idle", yame, "idle"), ("yame_telegraph", yame, "telegraph"),
]


# ---------------------------------------------------------------- Igris

IW, IH = 48, 64
IFY = 60


def igris(pose):
    c = Canvas(IW, IH)
    for i in range(-12, 13):
        c.put(24 + i, IFY, "#00000044")
    # pernas mecânicas
    c.rect(16, 46, 6, 13, "brass_lo")
    c.rect(26, 46, 6, 13, "brass_lo")
    c.rect(15, 57, 8, 3, "brass")
    c.rect(25, 57, 8, 3, "brass")
    # manto roxo rasgado
    c.rect(13, 36, 22, 14, "robe")
    c.vline(13, 36, 49, "robe_hi")
    for x in range(13, 35, 3):
        c.put(x, 50, "robe")
        c.put(x + 1, 51, "robe_lo")
    c.vline(24, 38, 48, "gold_lo")                # faixa bordada
    c.put(24, 42, "gold")
    # tronco de latão com tubos de órgão
    c.rect(14, 22, 20, 15, "brass")
    c.vline(14, 22, 36, "brass_hi")
    c.vline(33, 22, 36, "brass_lo")
    for x in (19, 22, 25, 28):
        c.vline(x, 24, 33, "lamp" if pose == "free" else "brass_lo")
    # sinos nos ombros
    for sx in (10, 38):
        c.ellipse(sx, 22, 5, 5, "brass_hi")
        c.hline(sx - 5, sx + 5, 27, "brass_lo")
        c.put(sx, 28, "brass_lo")
    # cabeça humana: rosto cansado, cabelo grisalho
    c.rect(20, 10, 9, 10, "skin")
    c.rect(19, 7, 11, 4, "stone_hi")
    c.vline(19, 10, 15, "stone_hi")
    c.put(22, 14, "outline")
    c.put(26, 14, "outline")
    c.hline(22, 26, 18, "stone_hi")               # barba
    c.hline(18, 30, 20, "robe_hi")                # gola
    # cajado com sino
    c.vline(40, 12, 58, "wood")
    c.vline(41, 12, 58, "wood_lo")
    c.ellipse(41, 9, 3, 3, "brass")
    c.put(41, 12, "brass_lo")
    # partes do combate
    if pose == "muffler":
        c.rect(18, 25, 12, 8, "wood_lo")          # abafador exposto
        c.hline(18, 29, 25, "lamp")
    if pose in ("regulator", "free"):
        c.ellipse(24, 30, 4, 4, "gold")
        c.ellipse(24, 30, 2, 2, "cloth" if pose == "regulator" else "lamp_hi")
    c.outline()
    return c


IGRIS_FRAMES = ["idle", "muffler", "regulator", "free"]


def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out = os.path.join(root, "assets", "art", "personagens")
    os.makedirs(out, exist_ok=True)
    frames = [fn(p) for _, fn, p in FRAMES]
    sheet(frames, len(frames)).save(os.path.join(out, "inimigos.png"))
    ig = [igris(p) for p in IGRIS_FRAMES]
    sheet(ig, len(ig)).save(os.path.join(out, "igris.png"))
    meta = {
        "frame_size": [W, H], "pivot": [16, FY], "frames": [n for n, _, _ in FRAMES],
        "igris": {"frame_size": [IW, IH], "pivot": [24, IFY], "frames": IGRIS_FRAMES},
    }
    with open(os.path.join(out, "inimigos.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    print("inimigos", len(frames), "igris", len(ig))


if __name__ == "__main__":
    main()
