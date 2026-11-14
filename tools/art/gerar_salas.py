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

import numpy as np

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

import animacoes_salas
import objetos_pintados

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
    "t03_treino": "t03-travessia-do-gancho.png",
    "t04_pesos": "t04-contrapesos.png",
    "t02_oficina": "t02-oficina-do-gancho-sem-yggnus.png",
    "t05_sinos": "t05-galeria-dos-sinos-sem-yggnus.png",
    "t00_base": "t00-base-da-torre-sem-yggnus.png",
    "t01_guardas": "t01-sala-dos-guardas.png",
    "t06_marco": "t06-antecamara-sem-yggnus.png",
    "t07_igris": "t07-camara-de-igris.png",
    "r01_cruzamento": "r01-cruzamento.png",
}

# Cores por sala: menos cores deixam a imagem com cara de pixel art.
COLORS = 96


def tamanho(room_id):
    """Tamanho da sala em pixels, lido do mapa."""
    with open(os.path.join(MAPS, room_id + ".json"), encoding="utf-8") as f:
        d = json.load(f)
    ts = int(d.get("tile_size", 16))
    return int(d["width"]) * ts, int(d["height"]) * ts


# Portas que a imagem não tem e o mapa precisa (decisão do usuário de
# 2026-11-13: "Eu desenho a porta lateral"). Cada sala copia a própria
# saída pintada para outro trecho da parede da frente: "de" é o recorte
# (x0, y0, x1, y1) e "para" o canto esquerdo de cima do destino, em pixels
# da referência de 960 × 540.
PORTAS = {
    "t01_guardas": [{"de": (325, 416, 600, 540), "para": (612, 416)}],
    "t00_base": [{"de": (320, 376, 610, 540), "para": (640, 376)}],
    "t06_marco": [{"de": (372, 376, 588, 540), "para": (656, 376)}],
    "t07_igris": [{"de": (372, 400, 588, 540), "para": (120, 400)}],
}


# Lâmpadas pintadas que são tochas do jogo (a Lamparina as acende): o fundo
# as mostra apagadas, e o jogo desenha a chama e a luz quando acesas. Caixas
# (x0, y0, x1, y1) em pixels da referência.
APAGAR = {
    "r02_bomba": [(362, 436, 390, 470), (515, 436, 543, 470)],
}


# Portões da cidade pintados abertos que o jogo mantém fechados: uma grade
# de ferro baixada no vão (pedido do usuário, 2026-11-14: "se o jogo diz que
# o portão está fechado, ele não deveria ficar aberto"). Vão em pixels da
# referência: x0, x1 (batentes), topo do arco, início do arco, chão.
GRADES = {
    "r00_estrada": [(106, 207, 138, 188, 292)],
    "r01_cruzamento": [(112, 197, 118, 162, 218)],
}


def grade(im, x0, x1, topo, arco, chao):
    """Grade levadiça baixada: o vão escurece e barras de ferro o fecham."""
    k = 4
    w, h = (x1 - x0) * k, (chao - topo) * k
    vao = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(vao)
    d.ellipse([0, 0, w - 1, (arco - topo) * 2 * k], fill=255)
    d.rectangle([0, (arco - topo) * k, w - 1, h - 1], fill=255)
    vao = vao.resize((x1 - x0, chao - topo), Image.Resampling.LANCZOS)
    caixa = (x0, topo, x1, chao)
    sombra = ImageEnhance.Brightness(im.crop(caixa)).enhance(0.45)
    im.paste(sombra, (x0, topo), vao)
    barras = Image.new("RGBA", (x1 - x0, chao - topo), (0, 0, 0, 0))
    d = ImageDraw.Draw(barras)
    ferro, brilho, escuro = (58, 50, 58, 255), (128, 112, 112, 255), (26, 20, 28, 255)
    for x in range(4, x1 - x0 - 2, 11):  # barras de pé, com ponta embaixo
        d.rectangle([x - 2, 0, x + 2, chao - topo - 6], fill=ferro, outline=escuro)
        d.line([x - 1, 0, x - 1, chao - topo - 7], fill=brilho)
        d.polygon([(x - 2, chao - topo - 6), (x + 2, chao - topo - 6), (x, chao - topo - 1)], fill=ferro, outline=escuro)
    for y in range(14, chao - topo - 10, 20):  # travessas
        d.rectangle([0, y - 2, x1 - x0, y + 2], fill=ferro, outline=escuro)
        d.line([1, y - 1, x1 - x0 - 2, y - 1], fill=brilho)
        for x in range(4, x1 - x0 - 2, 11):  # rebites
            d.point((x, y), fill=(196, 160, 96, 255))
    a = np.asarray(barras).copy()
    a[..., 3] = np.minimum(a[..., 3], np.asarray(vao))
    im.paste(Image.fromarray(a, "RGBA"), (x0, topo), Image.fromarray(a[..., 3], "L"))


def apaga_lampada(im, caixa):
    """Tira o brilho da lâmpada: o vidro aceso vira vidro escuro e frio."""
    x0, y0, x1, y1 = caixa
    a = np.asarray(im.crop(caixa)).astype(float)
    lum = a.mean(axis=2)
    h, w = lum.shape
    yy, xx = np.mgrid[0:h, 0:w]
    dentro = np.clip(2.5 - np.hypot((xx - w / 2) / (w / 2), (yy - h / 2) / (h / 2)) * 2.5, 0, 1)
    quente = np.maximum(np.clip((a[..., 0] - a[..., 2] - 25) / 30, 0, 1), np.clip((lum - 185) / 30, 0, 1))
    peso = np.clip((lum - 105) / 40, 0, 1) * quente * dentro
    escuro = np.stack([lum * 0.30 + 22, lum * 0.26 + 18, lum * 0.34 + 30], axis=2)
    a = a * (1 - peso[..., None]) + escuro * peso[..., None]
    im.paste(Image.fromarray(a.clip(0, 255).astype("uint8"), "RGB"), (x0, y0))


def copia_porta(im, de, para):
    """Copia a saída pintada para outro trecho da parede, com a borda suave."""
    pedaco = im.crop(de)
    mascara = Image.new("L", pedaco.size, 0)
    ImageDraw.Draw(mascara).rectangle([6, 0, pedaco.width - 7, pedaco.height - 1], fill=255)
    mascara = mascara.filter(ImageFilter.GaussianBlur(3))
    im.paste(pedaco, para, mascara)


def fundo(room_id, source):
    """Reduz a referência ao tamanho da sala e limita a paleta."""
    im = Image.open(os.path.join(REFS, source)).convert("RGB")
    im = animacoes_salas.apaga(im, room_id)  # o que gira é desenhado à parte
    for porta in PORTAS.get(room_id, []):
        copia_porta(im, **porta)
    for vao in GRADES.get(room_id, []):
        grade(im, *vao)
    for caixa in APAGAR.get(room_id, []):
        apaga_lampada(im, caixa)
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
    objetos_pintados.gerar()


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
    fundos, tamanhos, fontes = {}, {}, {}
    for room_id, source in SALAS.items():
        im = fundo(room_id, source)
        im.save(os.path.join(OUT, room_id + ".png"), optimize=True)
        fundos[room_id] = im.convert("RGB")
        tamanhos[room_id] = tamanho(room_id)
        fontes[room_id] = Image.open(os.path.join(REFS, source)).convert("RGB")
        print("salas:", room_id)
    objetos()
    animacoes_salas.gerar(fundos, tamanhos, fontes)


if __name__ == "__main__":
    main()
