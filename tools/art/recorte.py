"""Recorte de personagens das folhas de referência do usuário.

Tira o fundo liso (e a sombra do mesmo tom) que toca a borda de cada
recorte, reduz à altura do jogo com o alfa pré-multiplicado, deixa só a
maior mancha e põe um contorno escuro de 1 px. Usado por
yggnus_referencia.py e inimigos_referencia.py.
"""

import numpy as np
from PIL import Image


def mascara(rgb, bg):
    """Máscara do personagem: tira o fundo roxo e a sombra (o mesmo roxo,
    mais escuro) que tocam a borda do recorte; o casaco roxo, por dentro do
    contorno, fica."""
    px = rgb.astype(float)
    bg = np.asarray(bg, dtype=float)
    dist = np.linalg.norm(px - bg, axis=2)
    k = (px @ bg) / (bg @ bg)
    shadow = (np.linalg.norm(px - k[..., None] * bg, axis=2) < 18) & (k < 0.95) & (k > 0.45)
    # A sombra fica embaixo dos pés: só no quarto de baixo do recorte, para
    # não comer tinta ou papel escuro do próprio personagem.
    shadow[: int(px.shape[0] * 0.72), :] = False
    loose = (dist < 34) | shadow
    outside = np.zeros_like(loose)
    outside[0, :] = loose[0, :]
    outside[-1, :] = loose[-1, :]
    outside[:, 0] |= loose[:, 0]
    outside[:, -1] |= loose[:, -1]
    while True:  # cresce a partir da borda só por pixels de fundo ou sombra
        grow = outside.copy()
        grow[1:, :] |= outside[:-1, :]
        grow[:-1, :] |= outside[1:, :]
        grow[:, 1:] |= outside[:, :-1]
        grow[:, :-1] |= outside[:, 1:]
        grow &= loose
        if (grow == outside).all():
            break
        outside = grow
    return ~outside


def pose(sheet, box, bg, height=None, cut=None, scale=None, flip=False):
    if (height is None) == (scale is None):
        raise ValueError("pose: passe height ou scale (só um)")
    x, y, w, h = box
    rgb = np.asarray(sheet.crop((x, y, x + w, y + h)).convert("RGB"))
    a = mascara(rgb, bg)
    if cut is not None:
        a[:, max(0, cut - x):] = False
    ys, xs = np.nonzero(a)
    if ys.size == 0:
        raise ValueError("pose: o recorte %s ficou vazio (caixa ou cor de fundo errada)" % (box,))
    top, bottom, left, right = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    rgba = np.dstack([rgb, (a * 255).astype(np.uint8)])[top:bottom, left:right]
    im = Image.fromarray(rgba, "RGBA")
    if flip:
        im = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    s = scale if scale is not None else height / im.height
    size = (max(1, round(im.width * s)), max(1, round(im.height * s)))
    # Reduz com a cor pré-multiplicada pelo alfa, para a borda não clarear.
    pre = np.asarray(im).astype(float)
    pre[..., :3] *= pre[..., 3:4] / 255.0
    small = np.asarray(Image.fromarray(pre.clip(0, 255).astype(np.uint8), "RGBA").resize(size, Image.Resampling.LANCZOS)).astype(float)
    al = small[..., 3]
    col = np.where(al[..., None] > 0, small[..., :3] * 255.0 / np.maximum(al[..., None], 1), 0)
    out = np.dstack([col.clip(0, 255), np.where(al > 110, 255, 0)]).astype(np.uint8)
    return maior_mancha(Image.fromarray(out, "RGBA")), s


def maior_mancha(im):
    """Só a maior mancha (tira pontinhos soltos do rastro do golpe)."""
    arr = np.asarray(im).copy()
    a = arr[..., 3] > 0
    h, w = a.shape
    seen = np.zeros_like(a)
    best = []
    for y0 in range(h):
        for x0 in range(w):
            if not a[y0, x0] or seen[y0, x0]:
                continue
            todo, part = [(y0, x0)], []
            seen[y0, x0] = True
            while todo:
                y, x = todo.pop()
                part.append((y, x))
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < h and 0 <= nx < w and a[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        todo.append((ny, nx))
            if len(part) > len(best):
                best = part
    keep = np.zeros_like(a)
    for y, x in best:
        keep[y, x] = True
    arr[~keep] = 0
    return Image.fromarray(arr, "RGBA")


def contorno(im):
    """Contorno escuro de 1 px por fora, para destacar do cenário."""
    a = np.asarray(im)[..., 3] > 0
    ring = np.zeros_like(a)
    ring[1:, :] |= a[:-1, :]
    ring[:-1, :] |= a[1:, :]
    ring[:, 1:] |= a[:, :-1]
    ring[:, :-1] |= a[:, 1:]
    ring &= ~a
    arr = np.asarray(im).copy()
    arr[ring] = (27, 20, 32, 255)
    return Image.fromarray(arr, "RGBA")


def quadro(size, pivot, figura, dy=0, sx=1.0, sy=1.0, sombra=(8.5, 2.4), clarear=0.0):
    """Põe [figura] num quadro [size] com os pés no [pivot] (subida [dy]),
    esticada por [sx] × [sy], com sombra no chão e um clareamento opcional."""
    if sx != 1.0 or sy != 1.0:
        figura = figura.resize((max(1, round(figura.width * sx)), max(1, round(figura.height * sy))), Image.Resampling.NEAREST)
    if clarear:
        arr = np.asarray(figura).astype(float)
        arr[..., :3] = arr[..., :3] + (255 - arr[..., :3]) * clarear
        figura = Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")
    f = Image.new("RGBA", size, (0, 0, 0, 0))
    if sombra:
        sh = Image.new("RGBA", size, (0, 0, 0, 0))
        rx, ry = sombra
        for yy in range(-int(ry) - 1, int(ry) + 2):
            for xx in range(-int(rx) - 1, int(rx) + 2):
                if (xx / rx) ** 2 + (yy / ry) ** 2 <= 1.0 and 0 <= pivot[0] + xx < size[0] and 0 <= pivot[1] + yy < size[1]:
                    sh.putpixel((pivot[0] + xx, pivot[1] + yy), (20, 12, 24, 90))
        f.alpha_composite(sh)
    p = contorno(figura)
    f.alpha_composite(p, (pivot[0] - p.width // 2, pivot[1] - p.height + 1 + dy))
    return f
