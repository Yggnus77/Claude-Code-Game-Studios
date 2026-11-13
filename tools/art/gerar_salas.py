"""Fundos pintados das salas (design/gdd/salas-pintadas.md).

Cada sala listada em SALAS usa uma das referências que o usuário mandou
(design/art/referencias/salas/), reduzida ao tamanho da sala no jogo
(largura × 16 por altura × 16 px). O mapa da sala aponta para o fundo com
"art": {"background": "<id da sala>"}; paredes, portas e objetos do mapa são
desenhados à mão para bater com a imagem.

Uso: python3 tools/art/gerar_salas.py (também roda em gerar_tudo.py)
"""

import json
import os

from PIL import Image, ImageEnhance, ImageFilter

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
REFS = os.path.join(ROOT, "design", "art", "referencias", "salas")
MAPS = os.path.join(ROOT, "assets", "data", "maps")
OUT = os.path.join(ROOT, "assets", "art", "salas")

# Sala -> referência de origem.
# A referência 1 trazia Yggnus pintado no meio da oficina; a cópia
# "-sem-yggnus" tem o chão refeito no lugar dele (espelho do tapete e do
# piso de baixo), porque o Yggnus do jogo anda por cima do fundo.
SALAS = {
    "v00_oficina": "01-oficina-de-exodia-sem-yggnus.png",
    "v01_praca": "02-praca-de-versalhes.png",
    "r00_estrada": "03-estrada-inicial-e-cruzamento.png",
    "r02_bomba": "r02-bomba-d-agua.png",
    "r03_poco": "r03-poco-antigo.png",
}

# Cores por sala: menos cores deixam a imagem com cara de pixel art.
COLORS = 96


def tamanho(room_id):
    """Tamanho da sala em pixels, lido do mapa."""
    with open(os.path.join(MAPS, room_id + ".json"), encoding="utf-8") as f:
        d = json.load(f)
    ts = int(d.get("tile_size", 16))
    return int(d["width"]) * ts, int(d["height"]) * ts


def fundo(room_id, source):
    """Reduz a referência ao tamanho da sala e limita a paleta."""
    im = Image.open(os.path.join(REFS, source)).convert("RGB")
    im = im.resize(tamanho(room_id), Image.Resampling.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=0.7, percent=50, threshold=2))
    im = ImageEnhance.Color(im).enhance(1.04)
    return im.quantize(colors=COLORS, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)


# Folhagem das referências (cores medidas no arbusto pintado da praça).
LEAF = [(41, 46, 39), (65, 74, 47), (103, 92, 46), (126, 110, 42), (173, 144, 30)]
FLOWER = (220, 185, 23)
LEAF_LINE = (26, 28, 24)


def _blob(w, h, blobs, light=(-0.6, -0.8)):
    """Folhagem redonda: união de círculos, iluminada de cima e da esquerda,
    com contorno escuro e flores amarelas soltas."""
    import math
    import random
    rnd = random.Random(7)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    inside = {}
    for y in range(h):
        for x in range(w):
            best = None
            for cx, cy, r in blobs:
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if d <= r and (best is None or d / r < best[0]):
                    best = (d / r, (x + 0.5 - cx) / r, (y + 0.5 - cy) / r)
            if best:
                inside[(x, y)] = best
    for (x, y), (_, nx, ny) in inside.items():
        lit = (nx * light[0] + ny * light[1]) * 0.5 + 0.5  # 0 sombra, 1 luz
        lit += rnd.uniform(-0.16, 0.16)
        i = max(0, min(len(LEAF) - 1, int(lit * len(LEAF))))
        px[x, y] = LEAF[i] + (255,)
        if lit > 0.62 and rnd.random() < 0.12:
            px[x, y] = FLOWER + (255,)
    for (x, y) in list(inside):
        if (x, y + 1) not in inside and y + 1 < h:  # sombra no chão, embaixo
            for k in (1, 2):
                if y + k < h and px[x, y + k][3] == 0:
                    px[x, y + k] = (20, 12, 18, 110 if k == 1 else 60)
    for (x, y) in inside:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in inside and 0 <= x + dx < w and 0 <= y + dy < h:
                px[x + dx, y + dy] = LEAF_LINE + (255,)
    return im


def objetos():
    """Arbusto inteiro e cortado e a barreira, no estilo das referências."""
    bush = _blob(20, 19, [(10, 10, 7.5), (6, 11, 5), (14.5, 11, 5), (10, 6, 5), (7, 7, 4)])
    bush.save(os.path.join(OUT, "obj_bush.png"))
    cut = _blob(20, 19, [(6, 15, 3), (10, 14.5, 3.5), (14, 15, 3)])
    cut.save(os.path.join(OUT, "obj_bush_cut.png"))
    barreira().save(os.path.join(OUT, "obj_barreira.png"))


def barreira(w=64, h=28):
    """Barreira de madeira para uma saída fechada de sala pintada: dois
    postes e duas tábuas com faixas roxas e creme (as cores dos toldos da
    praça) e uma engrenagem de latão no meio."""
    from PIL import ImageDraw
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    line = (28, 18, 24, 255)
    wood, wood_hi, wood_lo = (123, 82, 54, 255), (156, 108, 69, 255), (82, 53, 34, 255)
    purple, cream = (96, 58, 112, 255), (232, 214, 186, 255)
    d.ellipse((2, h - 6, w - 3, h - 1), fill=(20, 12, 18, 90))  # sombra
    for x in (5, w - 11):  # postes
        d.rectangle((x, 4, x + 5, h - 3), fill=wood, outline=line)
        d.line((x + 1, 5, x + 1, h - 4), fill=wood_hi)
        d.rectangle((x - 1, 2, x + 6, 4), fill=wood_lo, outline=line)
    for y in (7, 15):  # tábuas listradas
        d.rectangle((1, y, w - 2, y + 5), fill=cream, outline=line)
        for k in range(-6, w, 8):
            d.polygon([(k, y + 5), (k + 4, y + 1), (k + 8, y + 1), (k + 4, y + 5)], fill=purple)
        d.rectangle((1, y, w - 2, y + 5), outline=line)
        d.line((2, y + 1, w - 3, y + 1), fill=(255, 240, 215, 255))
    cx, cy = w // 2, 13
    d.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(184, 135, 58, 255), outline=line)
    d.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(125, 90, 38, 255))
    d.point((cx - 3, cy - 4), fill=(240, 200, 110, 255))
    return im


def main():
    os.makedirs(OUT, exist_ok=True)
    for room_id, source in SALAS.items():
        fundo(room_id, source).save(os.path.join(OUT, room_id + ".png"), optimize=True)
        print("salas:", room_id)
    objetos()


if __name__ == "__main__":
    main()
