"""Objetos de mecanismo no estilo das salas pintadas.

Recorta cada objeto de uma referência do usuário (baú da oficina, pote da
praça, caixote do poço, medalhão da antecâmara, placa de engrenagem da
base, papel da mesa da oficina) com uma máscara desenhada à mão, reduz ao
tamanho do jogo e salva em assets/art/salas/obj_<tipo>.png. As salas
pintadas desenham estes no lugar dos objetos de bloco (room.gd,
painted_objects), para o mecanismo parecer parte da pintura
(pedido do usuário, 2026-11-13). Chamado por gerar_salas.py.
"""

import os

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance

from recorte import contorno

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
REFS = os.path.join(ROOT, "design", "art", "referencias", "salas")
OUT = os.path.join(ROOT, "assets", "art", "salas")

# tipo: (referência, caixa de recorte, máscara no recorte, largura no jogo)
# A máscara é um polígono ou ("elipse", x0, y0, x1, y1).
FONTES = {
    "chest": ("01-oficina-de-exodia-sem-yggnus.png", (60, 368, 180, 450),
              [(9, 20), (20, 10), (55, 3), (100, 6), (112, 18), (114, 64), (60, 74), (40, 78), (12, 68)], 30),
    "pot": ("02-praca-de-versalhes.png", (48, 276, 84, 312), ("elipse", 5, 3, 30, 31), 14),
    "refill": ("r03-poco-antigo.png", (160, 126, 222, 182),
               [(14, 12), (32, 4), (55, 7), (55, 44), (37, 52), (14, 47)], 20),
    "plate": ("t06-antecamara-sem-yggnus.png", (455, 0, 512, 46),
              [(8, 10), (18, 3), (40, 3), (49, 10), (49, 30), (40, 37), (18, 37), (8, 30)], 18),
    "marco": ("t00-base-da-torre-sem-yggnus.png", (428, 248, 532, 322), [(4, 1), (99, 1), (99, 67), (4, 67)], 30),
    "clue": ("01-oficina-de-exodia-sem-yggnus.png", (412, 238, 468, 278), [(4, 11), (44, 4), (56, 28), (13, 39)], 15),
}


def recorte(ref, caixa, mascara, largura):
    """O objeto recortado com fundo transparente e contorno escuro."""
    im = Image.open(os.path.join(REFS, ref)).convert("RGBA").crop(caixa)
    k = 4  # máscara desenhada em 4x para a borda sair limpa depois da redução
    m = Image.new("L", (im.width * k, im.height * k), 0)
    d = ImageDraw.Draw(m)
    if mascara[0] == "elipse":
        d.ellipse([v * k for v in mascara[1:]], fill=255)
    else:
        d.polygon([(x * k, y * k) for x, y in mascara], fill=255)
    m = m.resize(im.size, Image.Resampling.LANCZOS)
    im.putalpha(m)
    altura = max(1, round(im.height * largura / im.width))
    im = im.resize((largura, altura), Image.Resampling.LANCZOS)
    arr = np.asarray(im).copy()
    arr[..., 3] = np.where(arr[..., 3] > 110, 255, 0)
    return contorno(Image.fromarray(arr, "RGBA"))


def tingir(im, brilho, quente=0.0):
    """Mais claro e mais dourado: o estado ativo de placas e marcos."""
    arr = np.asarray(ImageEnhance.Brightness(im).enhance(brilho)).astype(float)
    arr[..., 0] += 40 * quente
    arr[..., 1] += 25 * quente
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")


def bau_aberto(bau):
    """O mesmo baú com a tampa erguida e o fundo escuro à mostra."""
    w, h = bau.size
    corte = int(h * 0.42)  # a tampa é o arco de cima
    sobe = 3
    out = Image.new("RGBA", (w, h + sobe), (0, 0, 0, 0))
    corpo = bau.crop((0, corte, w, h))
    tampa = ImageEnhance.Brightness(bau.crop((0, 0, w, corte))).enhance(0.85)
    out.alpha_composite(corpo, (0, corte + sobe))
    d = ImageDraw.Draw(out)
    d.rectangle([2, corte + sobe - 1, w - 3, corte + sobe + 2], fill=(34, 20, 18, 255))
    d.line([4, corte + sobe + 1, w - 6, corte + sobe + 1], fill=(240, 196, 92, 255))  # brilho do que havia dentro
    out.alpha_composite(tampa, (0, 0))
    return out


def gerar():
    feitos = {}
    for tipo, (ref, caixa, mascara, largura) in FONTES.items():
        feitos[tipo] = recorte(ref, caixa, mascara, largura)
    feitos["chest_open"] = bau_aberto(feitos["chest"])
    feitos["plate_hit"] = tingir(feitos["plate"], 1.35, 1.0)
    feitos["marco_active"] = tingir(feitos["marco"], 1.3, 1.0)
    for tipo, im in feitos.items():
        im.save(os.path.join(OUT, "obj_%s.png" % tipo))
    return feitos


if __name__ == "__main__":
    for t in gerar():
        print("objeto:", t)
