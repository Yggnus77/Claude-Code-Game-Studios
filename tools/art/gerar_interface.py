"""Arte da interface (design/gdd/telas-e-mochila.md): fundo e título da
tela inicial, mochila do inventário e ícones dos itens.

O fundo da tela inicial vem da imagem que o próprio usuário enviou
(design/art/referencias/tela-inicial-usuario.png), reduzida para 640×360.
O título é escrito com a fonte serifada do sistema (DejaVu Serif) e vira
imagem; a fonte não vai junto com o jogo. Mochila e ícones são desenhados
aqui, pixel a pixel, com a paleta do guia de arte.

Uso: python3 tools/art/gerar_interface.py (também roda em gerar_tudo.py)
"""

import json
import os
import random

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

from pixel import Canvas, rgba

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "art", "ui")
SOURCE_TITLE = os.path.join(ROOT, "design", "art", "referencias", "tela-inicial-usuario.png")
ITEMS = os.path.join(ROOT, "assets", "data", "itens.json")

ICON = 24
# Grade da mochila: 6 × 4 bolsos de 26 px, passo 28.
GRID_COLS, GRID_ROWS, CELL, SLOT = 6, 4, 28, 26


# ---------------------------------------------------------------- tela inicial
def titulo():
    """640×360: a imagem do usuário, reduzida, com o lado esquerdo um pouco
    mais escuro para o nome do jogo e o menu ficarem legíveis."""
    im = Image.open(SOURCE_TITLE).convert("RGB")
    im = im.resize((640, 360), Image.Resampling.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=0.8, percent=60, threshold=2))
    im = ImageEnhance.Color(im).enhance(1.05)
    shade = Image.new("L", (640, 360))
    px = shade.load()
    for x in range(640):
        a = max(0.0, 1.0 - x / 330.0)
        for y in range(360):
            px[x, y] = int(120 * a * a)
    dark = Image.new("RGB", (640, 360), (12, 10, 26))
    im = Image.composite(dark, im, shade)
    im.save(os.path.join(OUT, "titulo.png"))


SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
CREAM, CREAM_LO, SHADOW = (246, 232, 200), (214, 190, 146), (8, 6, 16)


def _text_layer(text, size, spacing=0):
    font = ImageFont.truetype(SERIF, size)
    box = font.getbbox(text)
    w = box[2] - box[0] + spacing * (len(text) - 1) + 4
    h = box[3] - box[1] + 4
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    x = 2
    for ch in text:
        d.text((x - box[0], 2 - box[1]), ch, font=font, fill=255)
        x += font.getlength(ch) + spacing
    return im


def logo():
    """O nome do jogo, 236×74: "A LENDA DE" pequeno sobre "YGGNUS" grande,
    creme com leve degradê, sombra e um filete embaixo."""
    small = _text_layer("A LENDA DE", 15, 1)
    big = _text_layer("YGGNUS", 46, 1)
    W, H = max(small.width, big.width) + 8, small.height + big.height + 12
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for layer, (x, y) in ((small, (3, 2)), (big, (2, small.height + 2))):
        grad = Image.new("RGBA", layer.size)
        gp = grad.load()
        for yy in range(layer.height):
            t = yy / max(1, layer.height - 1)
            col = tuple(int(CREAM[i] + (CREAM_LO[i] - CREAM[i]) * t * t) for i in range(3))
            for xx in range(layer.width):
                gp[xx, yy] = col + (255,)
        shadow = Image.new("RGBA", layer.size, SHADOW + (200,))
        out.paste(shadow, (x + 2, y + 2), layer)
        out.paste(grad, (x, y), layer)
    out.save(os.path.join(OUT, "logo.png"))


# ---------------------------------------------------------------- mochila
def _leather(c, x0, y0, w, h, base, rng, hi="leather_hi", lo="leather_lo", r=6):
    """Couro com cantos arredondados, luz à esquerda e grão."""
    b = rgba(base)
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            dx = min(x - x0, x0 + w - 1 - x)
            dy = min(y - y0, y0 + h - 1 - y)
            if dx < r and dy < r and (r - dx) ** 2 + (r - dy) ** 2 > r * r:
                continue
            t = (x - x0) / max(1, w - 1)
            k = 1.12 - 0.3 * t - 0.12 * (y - y0) / max(1, h - 1)
            n = rng.randint(-6, 6)
            c.px[x, y] = tuple(max(0, min(255, int(b[i] * k) + n)) for i in range(3)) + (255,)
    # contorno
    for y in range(y0 - 1, y0 + h + 1):
        for x in range(x0 - 1, x0 + w + 1):
            if c.get(x, y)[3] == 0:
                for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    p = c.get(x + ddx, y + ddy)
                    if p[3] == 255 and p != rgba("outline") and x0 <= x + ddx < x0 + w and y0 <= y + ddy < y0 + h:
                        c.put(x, y, "outline")
                        break
    c.hline(x0 + r, x0 + w - r, y0, hi)
    c.vline(x0, y0 + r, y0 + h - r, hi)


def _stitch(c, x0, y0, x1, y1, col="cloth_lo"):
    if y0 == y1:
        for x in range(x0, x1 + 1, 3):
            c.put(x, y0, col)
            c.put(x + 1, y0, col)
    else:
        for y in range(y0, y1 + 1, 3):
            c.put(x0, y, col)
            c.put(x0, y + 1, col)


def _buckle(c, x, y):
    c.rect(x - 4, y - 3, 9, 7, "outline")
    c.rect(x - 3, y - 2, 7, 5, "brass")
    c.rect(x - 2, y - 1, 5, 3, "leather_lo")
    c.hline(x - 3, x + 3, y - 2, "brass_hi")
    c.vline(x, y - 1, y + 1, "steel_lo")


def mochila():
    """A mochila aberta, 232×292, com 24 bolsos à mostra e o bolso da
    frente afivelado. Devolve a posição da grade."""
    rng = random.Random(7)
    W, H = 232, 292
    c = Canvas(W, H)
    # alças por trás (topo)
    for side in (-1, 1):
        cx = W // 2 + side * 62
        for t in range(0, 40):
            y = 40 - t
            x = cx + side * int(14 * (1 - (t / 40.0) ** 2) ** 0.5) - side * 14
            c.rect(x - 6, y, 12, 2, "leather_lo")
            c.put(x - 6, y, "outline")
            c.put(x + 5, y, "outline")
    # aba aberta dobrada para trás
    _leather(c, 26, 10, 180, 40, "leather", rng, r=12)
    _stitch(c, 36, 16, 196, 16)
    c.rect(104, 30, 24, 16, "outline")
    c.rect(106, 32, 20, 12, "brass")
    c.rect(110, 35, 12, 6, "brass_lo")
    c.hline(106, 125, 32, "brass_hi")
    # corpo
    _leather(c, 8, 42, 216, 244, "leather", rng, r=16)
    # bolsos laterais
    _leather(c, 2, 120, 16, 110, "leather_lo", rng, hi="leather", r=5)
    _leather(c, 214, 120, 16, 110, "leather_lo", rng, hi="leather", r=5)
    _stitch(c, 14, 58, 14, 268)
    _stitch(c, 217, 58, 217, 268)
    # boca aberta com forro escuro
    gx, gy = 32, 60
    inner_w, inner_h = GRID_COLS * CELL + 8, GRID_ROWS * CELL + 8
    c.rect(gx - 8, gy - 10, inner_w + 16, inner_h + 18, "outline")
    c.rect(gx - 7, gy - 9, inner_w + 14, inner_h + 16, "leather_lo")
    c.hline(gx - 7, gx + inner_w + 6, gy - 9, "leather_hi")
    for y in range(gy - 4, gy + inner_h + 4):
        for x in range(gx - 4, gx + inner_w):
            t = (y - gy) / inner_h
            base = (44, 30, 36) if (x // 4 + y // 4) % 2 == 0 else (40, 27, 33)
            k = 0.7 + 0.3 * t
            c.px[x, y] = tuple(int(v * k) for v in base) + (255,)
    # rebites em volta da boca
    for x in range(gx - 2, gx + inner_w, 12):
        c.put(x, gy - 7, "brass_hi")
        c.put(x, gy + inner_h + 5, "brass")
    # bolsos da grade: tecido afundado
    ox, oy = gx, gy
    for row in range(GRID_ROWS):
        for col in range(GRID_COLS):
            x, y = ox + col * CELL, oy + row * CELL
            c.rect(x, y, SLOT, SLOT, "outline")
            c.rect(x + 1, y + 1, SLOT - 2, SLOT - 2, "#5a4048")
            c.rect(x + 2, y + 2, SLOT - 4, SLOT - 4, "#4a333b")
            c.hline(x + 1, x + SLOT - 2, y + 1, "#2a1d22")
            c.vline(x + 1, y + 1, y + SLOT - 2, "#2a1d22")
            c.hline(x + 2, x + SLOT - 2, y + SLOT - 2, "#6e525a")
    # bolso da frente com aba e duas fivelas
    py = gy + inner_h + 16
    _leather(c, 30, py, 172, 286 - py - 10, "leather", rng, r=10)
    _stitch(c, 38, py + 6, 194, py + 6)
    _leather(c, 34, py - 2, 164, 30, "leather_hi", rng, hi="cloth_lo", lo="leather", r=8)
    _stitch(c, 40, py + 22, 192, py + 22, "leather_lo")
    for bx in (72, 160):
        c.rect(bx - 5, py + 10, 10, 48, "leather_lo")
        c.vline(bx - 5, py + 10, py + 57, "outline")
        c.vline(bx + 4, py + 10, py + 57, "outline")
        _buckle(c, bx, py + 30)
    # emblema de engrenagem no bolso
    ex, ey = 116, py + 44
    for k in range(8):
        dx, dy = [(0, -7), (5, -5), (7, 0), (5, 5), (0, 7), (-5, 5), (-7, 0), (-5, -5)][k]
        c.rect(ex + dx - 1, ey + dy - 1, 3, 3, "brass_lo")
    c.ellipse(ex, ey, 6, 6, "outline")
    c.ellipse(ex, ey, 5, 5, "brass")
    c.ellipse(ex, ey, 2, 2, "outline")
    c.put(ex - 3, ey - 3, "brass_hi")
    c.img.save(os.path.join(OUT, "mochila.png"))
    return {"size": [W, H], "grid_origin": [ox, oy], "cell": CELL, "slot": SLOT,
            "cols": GRID_COLS, "rows": GRID_ROWS}


# ---------------------------------------------------------------- ícones
def _blade(c, x0, y0, x1, y1, col="steel", lo="steel_lo"):
    c.line(x0, y0, x1, y1, col)
    c.line(x0 + 1, y0, x1 + 1, y1, lo)


def i_espada(c, steel="steel", lo="steel_lo", guard="brass", gem=None):
    _blade(c, 6, 17, 19, 4, steel, lo)
    c.line(7, 17, 19, 5, steel)
    c.put(20, 3, steel)
    c.line(3, 14, 9, 20, guard)
    c.line(4, 14, 10, 20, "brass_hi" if guard == "brass" else guard)
    c.line(2, 21, 5, 18, "leather")
    c.line(3, 21, 5, 19, "leather_lo")
    c.put(2, 22, guard)
    if gem:
        c.put(6, 17, gem)
        c.put(7, 16, gem)


def i_diapasao(c):
    i_espada(c, "#cfe6f0", "#7d93a6", "brass", "crystal")
    c.put(14, 9, "crystal_hi")
    c.put(10, 13, "crystal")


def i_lamina(c):
    i_espada(c, "#7d86d8", "coat_lo", "gold", "crystal")
    c.line(9, 14, 17, 6, "crystal_hi")


def i_escudo(c, face="brass", rim="brass_lo", hi="brass_hi", ring=False):
    for y in range(3, 21):
        half = 8 if y < 13 else max(1, 8 - (y - 12))
        c.hline(12 - half, 11 + half, y, face)
    c.hline(4, 19, 3, hi)
    c.vline(4, 3, 12, hi)
    c.vline(12, 4, 19, rim)
    c.hline(5, 18, 11, rim)
    c.ellipse(12, 11, 2, 2, "brass_hi" if face != "brass" else "gold")
    if ring:
        for r in (5,):
            for a in range(0, 360, 20):
                import math
                c.put(12 + int(r * math.cos(math.radians(a))), 11 + int(r * math.sin(math.radians(a))), "crystal")


def i_mapa(c):
    c.rect(3, 4, 18, 16, "cloth")
    c.rect(3, 4, 18, 2, "cloth_lo")
    c.vline(9, 4, 19, "cloth_lo")
    c.vline(15, 4, 19, "cloth_lo")
    c.line(5, 16, 9, 10, "rust")
    c.line(9, 10, 14, 13, "rust")
    c.line(14, 13, 18, 8, "rust")
    c.put(18, 8, "danger")
    c.rect(17, 7, 3, 3, "danger")
    c.rect(2, 3, 2, 18, "wood")
    c.rect(20, 3, 2, 18, "wood")


def i_bussola(c, face="cloth", needle="danger"):
    c.ellipse(12, 13, 9, 9, "brass_lo")
    c.ellipse(12, 13, 8, 8, "brass")
    c.ellipse(12, 13, 6, 6, face)
    c.rect(11, 2, 3, 3, "brass")
    c.line(12, 13, 16, 8, needle)
    c.line(12, 13, 8, 18, "steel_lo")
    c.put(12, 13, "outline")
    c.put(8, 9, "brass_hi")


def i_chave(c, big=False):
    head = "danger" if big else "brass"
    r = 5 if big else 4
    c.ellipse(7, 7, r, r, head)
    c.ellipse(7, 7, r - 2, r - 2, "outline")
    c.put(5, 5, "brass_hi")
    c.line(10, 10, 20, 20, "brass")
    c.line(11, 10, 21, 20, "brass_lo")
    c.rect(16, 18, 2, 3, "brass")
    c.rect(19, 15, 3, 2, "brass")
    if big:
        c.rect(13, 16, 2, 3, "brass")


def i_lamparina(c):
    c.rect(7, 8, 10, 12, "brass")
    c.rect(8, 9, 8, 10, "lamp")
    c.rect(10, 11, 4, 6, "lamp_hi")
    c.vline(7, 8, 19, "brass_lo")
    c.hline(6, 17, 20, "brass_lo")
    c.hline(6, 17, 7, "brass_hi")
    c.rect(9, 4, 6, 3, "brass")
    for x in range(8, 16):
        c.put(x, 2 if 10 <= x <= 13 else 3, "steel_lo")


def i_lanterna_lembrancas(c):
    i_lamparina(c)
    c.rect(8, 9, 8, 10, "crystal")
    c.rect(10, 11, 4, 6, "crystal_hi")
    c.put(4, 10, "crystal")
    c.put(19, 13, "crystal")
    c.put(5, 16, "crystal_hi")


def i_gancho(c):
    c.line(3, 21, 15, 9, "wood")
    c.line(4, 21, 16, 9, "wood_lo")
    c.rect(14, 7, 4, 4, "brass")
    for a, b in ((17, 5), (18, 4), (19, 4), (20, 5), (21, 7), (21, 9), (20, 11)):
        c.put(a, b, "steel")
        c.put(a, b + 1, "steel_lo")
    c.put(19, 12, "steel")


def i_luvas(c):
    c.rect(4, 9, 8, 10, "leather")
    c.rect(4, 5, 2, 5, "leather")
    c.rect(7, 4, 2, 6, "leather")
    c.rect(10, 5, 2, 5, "leather")
    c.rect(4, 17, 8, 3, "brass")
    c.rect(13, 10, 8, 10, "leather_hi")
    c.rect(13, 6, 2, 5, "leather_hi")
    c.rect(16, 5, 2, 6, "leather_hi")
    c.rect(19, 6, 2, 5, "leather_hi")
    c.rect(13, 18, 8, 3, "brass")
    c.put(5, 18, "brass_hi")
    c.put(14, 19, "brass_hi")


def i_botas(c):
    c.rect(4, 4, 7, 13, "boot_hi")
    c.rect(4, 15, 11, 5, "boot_hi")
    c.rect(13, 3, 7, 13, "boot")
    c.rect(13, 14, 10, 6, "boot")
    c.hline(4, 14, 20, "outline")
    c.hline(13, 22, 20, "outline")
    c.hline(4, 10, 6, "brass")
    c.hline(13, 19, 5, "brass")
    c.put(8, 11, "crystal")
    c.put(17, 10, "crystal")


def i_arco(c):
    import math
    for a in range(-70, 71, 4):
        x = 7 + int(11 * math.cos(math.radians(a)))
        y = 12 + int(10 * math.sin(math.radians(a)))
        c.put(x, y, "wood")
        c.put(x - 1, y, "wood_lo")
    c.vline(10, 2, 21, "cloth")
    c.line(5, 12, 21, 12, "steel_lo")
    c.put(21, 12, "steel")
    c.put(20, 11, "steel")
    c.put(20, 13, "steel")


def i_agulhas(c):
    for k, x in enumerate((6, 11, 16)):
        c.line(x, 20, x + 4, 4, "steel")
        c.put(x + 4, 3, "white")
        c.line(x - 1, 20, x, 17, "cloth")
        c.put(x + 1, 21, "danger" if k == 1 else "cloth_lo")


def i_frasco(c, liquid=None):
    c.rect(10, 2, 4, 3, "wood")
    c.rect(10, 5, 4, 4, "#bfe6f0")
    c.ellipse(12, 15, 7, 7, "#bfe6f0")
    if liquid:
        for y in range(13, 22):
            for x in range(5, 20):
                if c.get(x, y) == rgba("#bfe6f0"):
                    c.put(x, y, liquid)
    c.put(8, 11, "white")
    c.put(8, 12, "white")


def i_bolsa(c, col="leather", hi="leather_hi"):
    c.ellipse(12, 15, 9, 7, col)
    c.rect(6, 6, 12, 6, col)
    c.hline(6, 17, 6, hi)
    c.hline(5, 18, 9, "outline")
    c.rect(10, 8, 4, 3, "brass")
    _stitch(c, 6, 17, 18, 17, "leather_lo")
    c.put(7, 13, hi)


def i_pao(c):
    c.ellipse(12, 14, 9, 6, "#c08a4a")
    c.ellipse(12, 13, 8, 4, "#d9a560")
    for x in (7, 11, 15):
        c.line(x, 11, x + 2, 15, "#8a5a2a")
    c.put(9, 10, "#f0c888")


def i_essencia(c):
    c.rect(10, 3, 4, 3, "brass")
    c.rect(9, 6, 6, 3, "crystal_hi")
    c.ellipse(12, 15, 6, 7, "crystal")
    c.ellipse(11, 14, 3, 3, "crystal_hi")
    c.put(9, 12, "white")


def i_carga(c):
    c.ellipse(12, 14, 8, 8, "brass")
    c.ellipse(10, 12, 3, 3, "brass_hi")
    c.hline(5, 19, 14, "brass_lo")
    c.rect(10, 4, 5, 3, "brass_lo")
    c.line(14, 4, 18, 1, "#6a5a48")
    c.put(19, 1, "ember")
    c.put(20, 0, "ember_hi")


def i_po(c):
    i_bolsa(c, "robe", "robe_hi")
    c.put(12, 3, "crystal_hi")
    c.put(9, 2, "crystal")
    c.put(15, 4, "crystal")


def i_fragmento(c):
    pts = [(12, 2), (19, 12), (12, 22), (5, 12)]
    for y in range(2, 23):
        span = 7 - abs(y - 12) * 7 // 10
        c.hline(12 - span, 12 + span, y, "crystal")
    c.line(12, 2, 5, 12, "crystal_hi")
    c.line(12, 3, 12, 21, "#3aa8b0")
    c.put(10, 8, "white")
    del pts


def i_engrenagem(c, col="brass"):
    import math
    for a in range(0, 360, 45):
        x = 12 + int(9 * math.cos(math.radians(a)))
        y = 12 + int(9 * math.sin(math.radians(a)))
        c.rect(x - 1, y - 1, 3, 3, col)
    c.ellipse(12, 12, 7, 7, col)
    c.ellipse(12, 12, 3, 3, "outline")
    c.ellipse(12, 12, 1, 1, "brass_lo")
    c.put(8, 8, "brass_hi")


def i_eixo(c):
    c.line(3, 20, 20, 3, "steel_lo")
    c.line(4, 20, 21, 3, "steel")
    c.ellipse(6, 17, 3, 3, "brass")
    c.ellipse(17, 6, 3, 3, "brass")
    c.put(5, 16, "brass_hi")


def i_matrix(c):
    c.rect(9, 3, 6, 18, "crystal")
    c.rect(10, 3, 2, 18, "crystal_hi")
    c.hline(9, 14, 2, "white")
    c.rect(6, 9, 12, 3, "brass")
    c.rect(6, 15, 12, 3, "brass")
    c.hline(6, 17, 9, "brass_hi")
    c.put(12, 12, "white")


def i_magia(c, col, hi):
    c.ellipse(12, 12, 9, 9, col)
    c.ellipse(12, 12, 6, 6, hi)
    c.ellipse(12, 12, 3, 3, "white")
    for x, y in ((3, 3), (20, 4), (21, 19), (2, 18)):
        c.put(x, y, hi)


def i_pulso(c):
    import math
    for r, col in ((9, "crystal"), (6, "crystal_hi"), (3, "white")):
        for a in range(0, 360, 6):
            c.put(12 + round(r * math.cos(math.radians(a))), 12 + round(r * math.sin(math.radians(a))), col)


def i_fio(c):
    i_magia(c, "coat_lo", "crystal")
    c.line(2, 20, 21, 3, "crystal_hi")
    c.line(2, 21, 21, 4, "crystal")


def i_acorde(c):
    i_magia(c, "robe", "gold")
    c.vline(10, 6, 15, "outline")
    c.vline(15, 5, 14, "outline")
    c.hline(10, 15, 6, "outline")
    c.ellipse(9, 16, 2, 1, "outline")
    c.ellipse(14, 15, 2, 1, "outline")


def i_veu(c):
    for y in range(3, 22):
        w = 4 + (y - 3) // 2
        for x in range(12 - w, 12 + w):
            if (x + y) % 3:
                c.put(x, y, "#a8c8f0" if y % 4 else "#d8e8ff")
    c.hline(8, 15, 3, "gold")


def i_ampliador(c, n):
    c.ellipse(12, 12, 9, 9, "brass")
    c.ellipse(12, 12, 7, 7, "outline")
    c.ellipse(12, 12, 6, 6, "crystal")
    c.ellipse(11, 11, 2, 2, "crystal_hi")
    for k in range(n):
        c.rect(9 + k * 4, 20, 2, 3, "gold")


def i_reliquia(c, kind):
    if kind == "selo":
        c.ellipse(12, 12, 9, 9, "carpet")
        c.ellipse(12, 12, 6, 6, "carpet_hi")
        i = "gold"
        c.hline(9, 15, 12, i)
        c.vline(12, 9, 15, i)
    elif kind == "mola":
        for k in range(6):
            c.hline(6, 18, 4 + k * 3, "steel" if k % 2 == 0 else "steel_lo")
            c.line(18, 4 + k * 3, 6, 5 + k * 3 + 1, "steel_lo")
        c.rect(5, 20, 14, 2, "brass")
    elif kind == "fivela":
        c.rect(4, 6, 16, 12, "outline")
        c.rect(5, 7, 14, 10, "brass")
        c.rect(8, 9, 8, 6, "outline")
        c.vline(12, 7, 16, "steel")
        c.hline(5, 18, 7, "brass_hi")
    elif kind == "bussola":
        i_bussola(c, "night", "crystal")
    elif kind == "lente":
        c.ellipse(10, 10, 8, 8, "brass")
        c.ellipse(10, 10, 6, 6, "water_hi")
        c.ellipse(8, 8, 2, 2, "white")
        c.line(15, 15, 21, 21, "wood")
        c.line(16, 15, 22, 21, "wood_lo")
    elif kind == "afinador":
        c.vline(9, 3, 14, "steel")
        c.vline(15, 3, 14, "steel")
        c.hline(9, 15, 15, "steel_lo")
        c.vline(12, 15, 21, "brass")
        c.put(6, 6, "crystal")
        c.put(18, 6, "crystal")
        c.put(5, 9, "crystal_hi")
    elif kind == "broche":
        c.ellipse(12, 12, 8, 8, "gold")
        c.ellipse(12, 12, 5, 5, "coat")
        c.ellipse(12, 12, 2, 2, "crystal_hi")
        for x, y in ((12, 3), (21, 12), (12, 21), (3, 12)):
            c.put(x, y, "brass_hi")
    elif kind == "anel":
        import math
        for a in range(0, 360, 5):
            for r in (6, 7):
                c.put(12 + round(r * math.cos(math.radians(a))), 14 + round(r * 0.8 * math.sin(math.radians(a))), "gold" if r == 7 else "brass_lo")
        c.rect(10, 4, 5, 4, "crystal")
        c.put(11, 5, "crystal_hi")


def i_generico(c):
    i_bolsa(c)


ICONS = {
    "mapa_akurame": i_mapa,
    "bussola_akurame": i_bussola,
    "chave_chefe_akurame": lambda c: i_chave(c, True),
    "lamparina_oleo": i_lamparina,
    "espada_oficina": i_espada,
    "escudo_bronze": i_escudo,
    "matrix": i_matrix,
    "pulso_eco": i_pulso,
    "gancho_retorno": i_gancho,
    "espada_diapasao": i_diapasao,
    "luvas_lastro": i_luvas,
    "escudo_ressonante": lambda c: i_escudo(c, "coat", "coat_lo", "coat_hi", True),
    "fio_ancora": i_fio,
    "lanterna_lembrancas": i_lanterna_lembrancas,
    "acorde_vivo": i_acorde,
    "lamina_ancora": i_lamina,
    "veu_protecao": i_veu,
    "botas_travessia": i_botas,
    "arco_fio": i_arco,
    "ampliador_01": lambda c: i_ampliador(c, 1),
    "ampliador_02": lambda c: i_ampliador(c, 2),
    "frasco_01": i_frasco,
    "frasco_02": i_frasco,
    "frasco_03": i_frasco,
    "frasco_04": i_frasco,
    "frasco_cheio": lambda c: i_frasco(c, "#e05a7a"),
    "bolsa_reforcada": i_bolsa,
    "bolsa_navegante": lambda c: i_bolsa(c, "coat", "coat_hi"),
    "key_ak_base": i_chave,
    "pao_porto": i_pao,
    "essencia_ressonancia": i_essencia,
    "carga_bronze": i_carga,
    "po_revelacao": i_po,
    "ancora_fragmento": i_fragmento,
    "agulha_fio": i_agulhas,
    "peca_bomba_a": i_engrenagem,
    "peca_bomba_b": i_eixo,
    "selo_restaurador": lambda c: i_reliquia(c, "selo"),
    "mola_retorno": lambda c: i_reliquia(c, "mola"),
    "fivela_lastro": lambda c: i_reliquia(c, "fivela"),
    "bussola_aurelis": lambda c: i_reliquia(c, "bussola"),
    "lente_mare": lambda c: i_reliquia(c, "lente"),
    "afinador_eco": lambda c: i_reliquia(c, "afinador"),
    "broche_vigilia": lambda c: i_reliquia(c, "broche"),
    "anel_calibracao": lambda c: i_reliquia(c, "anel"),
    "bronze": None,
    "_generico": i_generico,
}


def i_bronze(c):
    for k, (x, y) in enumerate(((8, 15), (14, 13), (11, 9))):
        c.ellipse(x, y, 5, 4, "brass")
        c.ellipse(x - 1, y - 1, 2, 1, "brass_hi")
        c.hline(x - 4, x + 4, y + 3, "brass_lo")
        del k


ICONS["bronze"] = i_bronze


def itens():
    with open(ITEMS, encoding="utf-8") as f:
        ids = [it["id"] for it in json.load(f)["items"]]
    names = list(dict.fromkeys(ids + [k for k in ICONS if k not in ids]))
    frames = []
    for name in names:
        c = Canvas(ICON, ICON)
        (ICONS.get(name) or i_generico)(c)
        c.outline()
        frames.append(c)
    cols = 8
    rows = (len(frames) + cols - 1) // cols
    out = Image.new("RGBA", (ICON * cols, ICON * rows), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f.img, ((i % cols) * ICON, (i // cols) * ICON))
    out.save(os.path.join(OUT, "itens.png"))
    return {"size": ICON, "cols": cols, "index": {n: i for i, n in enumerate(names)}}


def main():
    os.makedirs(OUT, exist_ok=True)
    titulo()
    logo()
    for old in ("moldura.png", "cursor.png"):
        if os.path.exists(os.path.join(OUT, old)):
            os.remove(os.path.join(OUT, old))
    info = {"mochila": mochila(), "itens": itens(), "titulo": {"crystal": [484, 90]}}
    with open(os.path.join(OUT, "interface.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(info, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("interface: titulo, logo, mochila, %d ícones" % len(info["itens"]["index"]))


if __name__ == "__main__":
    main()
