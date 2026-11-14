"""Movimento do cenário das salas pintadas (design/gdd/salas-pintadas.md §3).

Pedido do usuário (2026-11-14): "se o jogo diz que o moinho está girando,
então por que permanece parado?? Dê movimento às coisas que estão inseridas
no ambiente!"

Para cada sala, recorta da referência as peças que se mexem e grava
assets/art/salas/anim/<sala>__<peça>.png, mais assets/data/animacoes-salas.json
com onde e como cada uma se mexe. O jogo (src/world/ambient.gd) desenha as
peças por cima do fundo:

- "spin": gira em volta do centro (pás de moinho, engrenagens, rodas
  d'água). Com "apaga", a peça é tirada do fundo (cv2.inpaint), senão a
  peça redonda cobre a própria pintura ao girar.
- "sway": balança a ponta de baixo (estandartes).
- "glow": brilho que respira em cima de cada chama acesa da pintura
  (LUZES, marcadas à mão em pixels do jogo).
- "water": reflexos que correm por uma área de água.

Coordenadas em pixels da referência (960 × 540). Chamado por gerar_salas.py
(fundo() apaga as peças "apaga"; gerar() grava as peças e o json).
"""

import json
import math
import os

import cv2
import numpy as np
from PIL import Image, ImageDraw

from recorte import maior_mancha

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "art", "salas", "anim")
DATA = os.path.join(ROOT, "assets", "data", "animacoes-salas.json")


def pas(cx, cy, pontas, largura=17, cubo=13):
    """Polígonos das pás de um moinho: um braço do cubo até cada ponta."""
    polis = []
    for tx, ty in pontas:
        a = math.atan2(ty - cy, tx - cx)
        n = (-math.sin(a) * largura, math.cos(a) * largura)
        r0, r1 = cubo * 0.6, math.hypot(tx - cx, ty - cy) + 4
        p0 = (cx + math.cos(a) * r0, cy + math.sin(a) * r0)
        p1 = (cx + math.cos(a) * r1, cy + math.sin(a) * r1)
        polis.append([(p0[0] + n[0], p0[1] + n[1]), (p1[0] + n[0], p1[1] + n[1]),
                      (p1[0] - n[0], p1[1] - n[1]), (p0[0] - n[0], p0[1] - n[1])])
    return polis, cubo


# sala: lista de peças. Cada peça: tipo, nome e os dados do tipo.
PECAS = {
    "r00_estrada": [
        {"tipo": "spin", "nome": "pas", "centro": (571, 42), "apaga": True, "vel": 0.9,
         "pas": [(506, 9), (621, 7), (527, 93), (612, 93)],
         "zonas": [
             {"poligono": [(550, 34), (584, 34), (584, 100), (533, 100)],  # a torre
              "amostra": (556, 84, 566, 96)},
             {"poligono": [(490, 52), (548, 52), (531, 110), (490, 110)],  # casa e varanda
              "passos": [(-14, 0), (-28, 0), (0, 14), (-14, 14)]},
         ]},
        {"tipo": "spin", "nome": "roda", "centro": (508, 113), "raio": 23, "vel": -0.7},
        {"tipo": "sway", "nome": "estandarte", "caixa": (53, 113, 97, 215)},
        {"tipo": "sway", "nome": "estandarte2", "caixa": (263, 120, 293, 215)},
    ],
    "r01_cruzamento": [
        {"tipo": "spin", "nome": "pas", "centro": (733, 51), "apaga": True, "vel": 0.9,
         "pas": [(676, 13), (781, 12), (686, 96), (779, 91)], "largura": 24, "largura_peca": 17,
         "zonas": [
             {"poligono": [(708, 52), (740, 52), (748, 110), (686, 110)],  # a torre
              "amostra": (178, 136, 156)},
             {"poligono": [(655, 55), (706, 55), (690, 100), (655, 100)],  # casa
              "passos": [(-16, 0), (-32, 0), (-48, 0), (0, 12)]},
             {"poligono": [(655, 30), (700, 26), (716, 55), (655, 55)],  # telhado
              "passos": [(-12, 0), (-24, 0), (12, 0), (0, 9), (-12, 9)]},
             {"poligono": [(650, 0), (820, 0), (820, 120), (650, 120)],  # grama em volta
              "passos": [(26, 0), (-26, 0), (0, -22), (40, 6), (-40, 6), (26, 22), (0, 30), (52, 0)],
              "so_verde": True},
         ]},
        {"tipo": "spin", "nome": "engrenagem", "centro": (648, 110), "raio": 26, "vel": 0.6},
        {"tipo": "spin", "nome": "engrenagem2", "centro": (627, 136), "raio": 20, "vel": -0.8},
        {"tipo": "sway", "nome": "estandarte", "caixa": (598, 80, 622, 130)},
    ],
}

# Peças pequenas em pixels do jogo, recortadas do próprio fundo reduzido:
# sala -> lista de (nome, centro x, centro y, raio, velocidade).
GIROS = {
    "r02_bomba": [("engrenagem", 403, 190, 21, 0.7), ("roda", 561, 250, 8, -1.2), ("engrenagem2", 459, 203, 8, -1.4)],
    "t04_pesos": [("polia", 110, 53, 16, 0.8), ("polia2", 529, 53, 16, -0.8), ("polia3", 159, 117, 7, -1.5),
                  ("polia4", 159, 171, 7, 1.5), ("polia5", 477, 117, 7, 1.5), ("polia6", 477, 171, 7, -1.5)],
    "t07_igris": [("engrenagem", 267, 33, 11, 0.6), ("engrenagem2", 373, 33, 11, -0.6)],
}

# Chamas acesas da pintura, em pixels do jogo: sala -> [(x, y), ...].
LUZES = {
    "v00_oficina": [(119, 55), (252, 63), (421, 63), (290, 143), (510, 110), (262, 308), (377, 308)],
    "v01_praca": [(215, 115), (238, 115), (408, 115), (425, 115), (198, 247), (229, 247), (422, 248), (450, 248),
                  (292, 21), (348, 21), (155, 69), (208, 65), (457, 48), (535, 48), (75, 277), (571, 328)],
    "r00_estrada": [(163, 123)],
    "r01_cruzamento": [(70, 107), (133, 100), (233, 97)],
    "r02_bomba": [(272, 20), (368, 20), (40, 103), (90, 175), (153, 160), (472, 142), (604, 179)],
    "r03_poco": [(319, 52)],
    "t00_base": [(247, 51), (393, 51), (41, 139), (597, 135), (265, 306), (375, 306), (476, 306), (588, 306)],
    "t01_guardas": [(265, 50), (377, 50), (47, 127), (592, 127), (199, 175), (440, 175),
                    (249, 329), (389, 329), (440, 329), (580, 329)],
    "t02_oficina": [(258, 53), (384, 53), (44, 162), (265, 299), (375, 299)],
    "t03_treino": [(117, 93), (524, 93), (28, 175), (609, 175), (252, 283), (385, 283), (273, 20), (365, 20)],
    "t04_pesos": [(273, 40), (365, 40), (47, 144), (592, 144), (29, 207), (610, 207), (280, 313), (360, 313)],
    "t05_sinos": [(273, 41), (364, 41), (265, 330), (373, 330)],
    "t06_marco": [(271, 47), (365, 47), (101, 79), (213, 124), (424, 124), (197, 225), (441, 225),
                  (24, 200), (613, 192), (263, 325), (377, 325), (567, 325)],
    "t07_igris": [(120, 87), (408, 41), (231, 41), (43, 150), (595, 150), (108, 313), (200, 313), (273, 313), (365, 313)],
}

# Água, em pixels do jogo: sala -> [(centro x, centro y, raio x, raio y), ...].
AGUA = {
    "v01_praca": [(323, 193, 55, 12), (323, 166, 18, 4)],
    "r02_bomba": [(543, 73, 52, 13)],
    "r03_poco": [(130, 165, 24, 7)],
}


def _escala(tamanho):
    return tamanho[0] / 960.0, tamanho[1] / 540.0


def mascara_peca(p, size=(960, 540), k=1.0):
    """Máscara (L) da peça no tamanho da referência."""
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    cx, cy = p["centro"]
    if "pas" in p:
        polis, cubo = pas(cx, cy, p["pas"], p.get("largura", 17))
        for poli in polis:
            d.polygon(poli, fill=255)
        d.ellipse([cx - cubo, cy - cubo, cx + cubo, cy + cubo], fill=255)
    else:
        r = p["raio"] * k
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    return m


def _poligono(size, pontos):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).polygon(pontos, fill=255)
    return np.asarray(m) > 0


def _textura(a, buraco, zona, passos, evita):
    """Enche [buraco] dentro de [zona] copiando a própria pintura da zona
    deslocada por [passos] (as fiadas de pedra se repetem)."""
    falta = buraco & zona
    h, w = falta.shape
    for _ in range(40):
        if not falta.any():
            break
        for dx, dy in passos:
            ys, xs = np.nonzero(falta)
            sx, sy = xs + dx, ys + dy
            ok = (sx >= 0) & (sx < w) & (sy >= 0) & (sy < h)
            ys, xs, sx, sy = ys[ok], xs[ok], sx[ok], sy[ok]
            boa = zona[sy, sx] & ~falta[sy, sx] & ~evita[sy, sx]
            a[ys[boa], xs[boa]] = a[sy[boa], sx[boa]]
            falta[ys[boa], xs[boa]] = False
    return falta


def _pedra(a, buraco, zona, amostra, curso=6, pedra=10):
    """Parede de pedra redonda desenhada no buraco: a cor média da
    [amostra] (x0, y0, x1, y1), fiadas de [curso] px com juntas
    desencontradas e sombra nas laterais, como uma torre cilíndrica."""
    if len(amostra) == 3:  # a própria cor
        base = np.array(amostra, float)
    else:
        x0, y0, x1, y1 = amostra
        base = np.median(a[y0:y1, x0:x1].reshape(-1, 3), axis=0)
    ys, xs = np.nonzero(zona)
    esq, dir_ = xs.min(), xs.max()
    rng = np.random.default_rng(7)
    falta = buraco & zona
    for y, x in zip(*np.nonzero(falta)):
        u = (x - esq) / max(1, dir_ - esq)  # 0 na borda esquerda, 1 na direita
        luz = 0.72 + 0.38 * math.sin(math.pi * min(1.0, u * 1.15))
        cor = base * luz + rng.normal(0, 5, 3)
        fiada = y // curso
        if y % curso == 0 or (x + (pedra // 2) * (fiada % 2)) % pedra == 0:
            cor = cor * 0.72
        a[y, x] = np.clip(cor, 0, 255)
    return np.zeros_like(falta)


def _linhas(a, buraco):
    """Enche cada trecho do buraco, linha a linha, entre as cores das pontas
    (céu com nuvens em faixas)."""
    for y in range(a.shape[0]):
        xs = np.nonzero(buraco[y])[0]
        if xs.size == 0:
            continue
        boas = np.nonzero(~buraco[y])[0]
        if boas.size == 0:
            continue
        for c in range(3):
            a[y, xs, c] = np.interp(xs, boas, a[y, boas, c])


def apaga(im, room_id):
    """Tira do fundo as peças que vão girar por cima (só as com "apaga").
    A parede atrás das pás é refeita com a textura dela mesma ("zonas":
    polígono e deslocamentos), o céu é refeito linha a linha."""
    pecas = [p for p in PECAS.get(room_id, []) if p.get("apaga")]
    if not pecas:
        return im
    a = np.asarray(im.convert("RGB")).copy()
    for p in pecas:
        buraco = cv2.dilate(np.asarray(mascara_peca(p, im.size)), np.ones((9, 9), np.uint8)) > 0
        resto = buraco.copy()
        for zona in p.get("zonas", []):
            dentro = _poligono(im.size, zona["poligono"])
            evita = np.zeros_like(dentro)
            verde = a[..., 1].astype(int) > a[..., 0].astype(int) - 8
            if zona.get("so_verde"):  # grama: só copia grama
                evita |= ~verde
            if zona.get("sem_verde"):  # parede: nunca copia a grama de trás
                evita |= (a[..., 1].astype(int) > a[..., 0].astype(int) - 8)
            for x0, y0, x1, y1 in zona.get("evita", []):
                evita[y0:y1, x0:x1] = True
            if "amostra" in zona:
                sobra = _pedra(a, resto & dentro, dentro, zona["amostra"])
            else:
                sobra = _textura(a, resto & dentro, dentro, zona["passos"], evita)
            resto &= ~(dentro & ~sobra)
        _linhas(a, resto)
        a = cv2.GaussianBlur(a, (3, 3), 0) * resto[..., None] + a * ~resto[..., None]
    return Image.fromarray(a.astype(np.uint8))


def _recorte(src, mascara, caixa, tamanho_sala):
    """Peça recortada da referência e reduzida como o fundo (sx, sy)."""
    sx, sy = _escala(tamanho_sala)
    im = src.crop(caixa).convert("RGBA")
    im.putalpha(mascara.crop(caixa))
    w = max(1, round(im.width * sx))
    h = max(1, round(im.height * sy))
    pre = np.asarray(im).astype(float)
    pre[..., :3] *= pre[..., 3:4] / 255.0
    small = np.asarray(Image.fromarray(pre.clip(0, 255).astype(np.uint8), "RGBA").resize((w, h), Image.Resampling.LANCZOS)).astype(float)
    al = small[..., 3]
    col = np.where(al[..., None] > 0, small[..., :3] * 255.0 / np.maximum(al[..., None], 1), 0)
    return Image.fromarray(np.dstack([col.clip(0, 255), np.where(al > 100, 255, 0)]).astype(np.uint8), "RGBA")


def gerar(fundos, tamanhos, fontes):
    """Grava as peças e o json. [fundos]: sala -> fundo já reduzido (para
    achar as chamas); [tamanhos]: sala -> (L, A); [fontes]: sala -> imagem
    da referência (antes de apagar)."""
    os.makedirs(OUT, exist_ok=True)
    dados = {}
    for room_id, fundo in fundos.items():
        tam = tamanhos[room_id]
        sx, sy = _escala(tam)
        itens = []
        for p in PECAS.get(room_id, []):
            nome = "%s__%s" % (room_id, p["nome"])
            if p["tipo"] == "spin":
                cx, cy = p["centro"]
                m = mascara_peca(p)
                bb = m.getbbox()
                if p.get("apaga"):
                    # Só o que muda entre a pintura e o fundo refeito: as pás,
                    # sem o céu ou a parede em volta delas.
                    limpo = np.asarray(apaga(fontes[room_id], room_id)).astype(int)
                    dif = np.abs(np.asarray(fontes[room_id]).astype(int) - limpo).sum(axis=2) > 60
                    dif = cv2.morphologyEx(dif.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8)) > 0
                    o = np.asarray(fontes[room_id]).astype(int)
                    # Pano, madeira e latão são quentes: céu roxo e grama não.
                    dif &= (o[..., 0] > o[..., 2] + 35) & (o[..., 0] > o[..., 1] + 12)
                    justa = mascara_peca(dict(p, largura=p.get("largura_peca", 13)))
                    m = Image.fromarray((np.asarray(justa) > 0) & dif).convert("L").point(lambda v: 255 if v else 0)
                r = max(abs(bb[0] - cx), abs(bb[2] - cx), abs(bb[1] - cy), abs(bb[3] - cy)) + 1
                caixa = (int(cx - r), int(cy - r), int(cx + r), int(cy + r))
                peca = _recorte(fontes[room_id], m, caixa, tam)
                if p.get("apaga"):
                    peca = maior_mancha(peca)  # sem pontinhos de nuvem ou flor
                peca.save(os.path.join(OUT, nome + ".png"))
                itens.append({"tipo": "spin", "textura": nome, "centro": [round(cx * sx, 1), round(cy * sy, 1)],
                              "vel": p["vel"], "achata": round(sy / sx, 4),
                              "pivo": [round((cx - caixa[0]) * sx, 1), round((cy - caixa[1]) * sy, 1)]})
            elif p["tipo"] == "sway":
                caixa = p["caixa"]
                m = Image.new("L", (960, 540), 0)
                ImageDraw.Draw(m).rectangle(caixa, fill=255)
                peca = _recorte(fontes[room_id], m, caixa, tam)
                peca.save(os.path.join(OUT, nome + ".png"))
                itens.append({"tipo": "sway", "textura": nome, "pos": [round(caixa[0] * sx), round(caixa[1] * sy)],
                              "amplitude": p.get("amplitude", 1.6), "vel": p.get("vel", 2.2)})
        for nome_g, cx, cy, r, vel in GIROS.get(room_id, []):
            nome = "%s__%s" % (room_id, nome_g)
            m = Image.new("L", fundo.size, 0)
            ImageDraw.Draw(m).ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
            peca = fundo.convert("RGBA")
            peca.putalpha(m)
            peca.crop((cx - r - 1, cy - r - 1, cx + r + 2, cy + r + 2)).save(os.path.join(OUT, nome + ".png"))
            itens.append({"tipo": "spin", "textura": nome, "centro": [cx + 0.5, cy + 0.5], "vel": vel,
                          "achata": 1.0, "pivo": [r + 1.5, r + 1.5]})
        for x, y in LUZES.get(room_id, []):
            itens.append({"tipo": "glow", "pos": [x, y], "raio": 14})
        for cx, cy, rx, ry in AGUA.get(room_id, []):
            itens.append({"tipo": "water", "centro": [cx, cy], "raio": [rx, ry]})
        if itens:
            dados[room_id] = itens
    with open(DATA, "w", encoding="utf-8", newline="\n") as f:
        json.dump(dados, f, ensure_ascii=False, indent=1)
    return dados
