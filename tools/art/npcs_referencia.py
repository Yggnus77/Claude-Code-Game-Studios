"""NPCs no padrão dos personagens principais (pedido do usuário, 2026-11-14:
"ainda existem NPCs que estão fora do padrão gráfico").

Cada NPC sai de uma referência do usuário (design/art/referencias/
personagens/), reduzida à altura do jogo com o alfa pré-multiplicado e com
o contorno escuro de 1 px, como Yggnus. Grava assets/art/personagens/
npc_<nome>.png; o mapa liga a entidade com "look": "<nome>" e Room desenha a
figura em pé na célula.

- exodia: a inventora de cabelo grisalho (referência 21), na oficina.
- mecanica: a Mecânica do Cais da bomba d'água. Não tem referência própria:
  é a mesma figura de trabalho com outras cores (cabelo castanho escuro,
  vestido verde, avental de couro), para não parecer a Exódia.
"""

import colorsys
import os

import numpy as np
from PIL import Image

from recorte import contorno

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
REFS = os.path.join(ROOT, "design", "art", "referencias", "personagens")
OUT = os.path.join(ROOT, "assets", "art", "personagens")
HEIGHT = 40  # um pouco menor que Yggnus (42)


def figura(ref, altura=HEIGHT):
    """A figura da referência (fundo transparente) reduzida à altura."""
    im = Image.open(os.path.join(REFS, ref)).convert("RGBA")
    im = im.crop(im.getbbox())
    s = altura / im.height
    size = (max(1, round(im.width * s)), altura)
    pre = np.asarray(im).astype(float)
    pre[..., :3] *= pre[..., 3:4] / 255.0
    small = np.asarray(Image.fromarray(pre.clip(0, 255).astype(np.uint8), "RGBA").resize(size, Image.Resampling.LANCZOS)).astype(float)
    al = small[..., 3]
    col = np.where(al[..., None] > 0, small[..., :3] * 255.0 / np.maximum(al[..., None], 1), 0)
    out = np.dstack([col.clip(0, 255), np.where(al > 110, 255, 0)]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def recolorir(im):
    """Outra pessoa com a mesma roupa de trabalho: vestido roxo vira verde,
    cabelo grisalho vira castanho escuro, avental laranja vira couro."""
    a = np.asarray(im).astype(float) / 255.0
    h, w = a.shape[:2]
    out = a.copy()
    for y in range(h):
        for x in range(w):
            if a[y, x, 3] == 0:
                continue
            r, g, b = a[y, x, :3]
            hu, sa, va = colorsys.rgb_to_hsv(r, g, b)
            if y < h * 0.3 and va > 0.4 and (sa < 0.3 or 0.6 < hu < 0.85):  # cabelo grisalho
                out[y, x, :3] = colorsys.hsv_to_rgb(0.04, 0.6, 0.18 + va * 0.32)
            elif 0.55 < hu < 0.8 and sa > 0.2:  # roxo e azul do vestido
                out[y, x, :3] = colorsys.hsv_to_rgb(0.33, min(1.0, sa * 1.05), va * 0.95)
            elif 0.05 < hu < 0.12 and sa > 0.5 and y > h * 0.3:  # avental laranja
                out[y, x, :3] = colorsys.hsv_to_rgb(0.06, sa * 0.75, va * 0.62)
    return Image.fromarray((out * 255).clip(0, 255).astype(np.uint8), "RGBA")


def gerar():
    os.makedirs(OUT, exist_ok=True)
    exodia = figura("21-senhora-braco-de-latao.png")
    feitos = {"exodia": exodia, "mecanica": recolorir(exodia).transpose(Image.Transpose.FLIP_LEFT_RIGHT)}
    for nome, im in feitos.items():
        contorno(im).save(os.path.join(OUT, "npc_%s.png" % nome))
    return feitos


if __name__ == "__main__":
    for n in gerar():
        print("npc:", n)
