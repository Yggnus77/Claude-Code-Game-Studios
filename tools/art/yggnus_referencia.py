"""Yggnus a partir da folha de personagem do usuário (referência 11).

A folha (design/art/referencias/personagens/11-yggnus-folha-de-personagem.png)
traz Yggnus parado nas quatro direções, quatro passos de caminhada de frente,
de costas e de lado, e três poses de ataque de lado. Cada pose é recortada do
fundo roxo, sem a sombra (nas poses de golpe de lado, sem a lâmina e o rastro:
o jogo desenha a lâmina na hora do golpe), reduzida à altura do jogo e posta na grade da folha que o
jogo usa (assets/art/personagens/yggnus.png + yggnus.json: linhas frente,
costas e lado; colunas por animação). As poses que a referência não tem
(defesa, esquiva, dano, queda, ferramenta) reaproveitam as que tem.

Uso: python3 tools/art/yggnus_referencia.py (também roda em gerar_tudo.py)
"""

import json
import os

import sys

sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image  # noqa: E402

from recorte import contorno, pose  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE = os.path.join(ROOT, "design", "art", "referencias", "personagens", "11-yggnus-folha-de-personagem.png")
OUT = os.path.join(ROOT, "assets", "art", "personagens")

FRAME = (64, 52)        # tamanho de cada quadro
PIVOT = (32, 48)        # os pés
HEIGHT = 42             # altura de Yggnus no jogo, em pixels
BG = (83, 42, 93)  # roxo do fundo (RGB)

# Recortes na folha (x, y, largura, altura), medidos na imagem de 1672 × 941.
IDLE = {"down": (301, 38, 169, 230), "up": (604, 35, 166, 233), "side": (903, 38, 145, 231)}
WALK = {
    "down": [(62, 362, 117, 192), (218, 362, 109, 192), (363, 365, 113, 189), (509, 364, 110, 190)],
    "up": [(711, 366, 108, 190), (851, 366, 110, 190), (1003, 365, 107, 191), (1150, 366, 113, 190)],
    "side": [(59, 663, 119, 189), (214, 661, 118, 192), (367, 663, 115, 190), (516, 661, 112, 191)],
}
# Ataque de lado: preparo, golpe e fim; "cut" corta a lâmina e o rastro
# (tudo à direita dessa coluna da folha).
ATTACK = [
    {"box": (1405, 339, 142, 157), "cut": None},
    {"box": (1407, 511, 225, 179), "cut": 1545},
    {"box": (1402, 731, 235, 151), "cut": 1538},
]


def _frame(figura, dy=0, squash=1.0):
    """Põe a pose num quadro, com os pés no pivô e uma sombra no chão."""
    if squash != 1.0:
        figura = figura.resize((figura.width, max(1, round(figura.height * squash))), Image.Resampling.NEAREST)
    f = Image.new("RGBA", FRAME, (0, 0, 0, 0))
    sh = Image.new("RGBA", FRAME, (0, 0, 0, 0))
    sx = PIVOT[0]
    for yy in range(-2, 2):
        for xx in range(-8, 9):
            if (xx / 8.5) ** 2 + (yy / 2.4) ** 2 <= 1.0:
                sh.putpixel((sx + xx, PIVOT[1] + yy), (20, 12, 24, 90))
    f.alpha_composite(sh)
    p = contorno(figura)
    x = PIVOT[0] - p.width // 2
    y = PIVOT[1] - p.height + 1 + dy
    f.alpha_composite(p, (x, y))
    return f


def build():
    sheet = Image.open(SOURCE)
    idle = {d: pose(sheet, b, BG, HEIGHT)[0] for d, b in IDLE.items()}
    walk = {d: [pose(sheet, b, BG, HEIGHT)[0] for b in boxes] for d, boxes in WALK.items()}
    # O ataque usa a escala do preparo, para o braço esticado não encolher.
    ready, s = pose(sheet, ATTACK[0]["box"], BG, HEIGHT)
    attack = [ready] + [pose(sheet, a["box"], BG, cut=a["cut"], scale=s)[0] for a in ATTACK[1:]]

    anims = {}
    cols = []

    def add(name, frames):
        anims[name] = list(range(len(cols), len(cols) + len(frames)))
        cols.extend(frames)

    # Cada entrada: função direção -> imagem do quadro.
    add("idle", [lambda d: _frame(idle[d]), lambda d: _frame(idle[d], dy=0, squash=0.98)])
    add("walk", [lambda d, i=i: _frame(walk[d][i]) for i in range(4)])
    side_or = lambda i, other: (lambda d: _frame(attack[i]) if d == "side" else _frame(other(d)))  # noqa: E731
    add("slash1", [side_or(0, lambda d: idle[d]), side_or(1, lambda d: walk[d][1])])
    add("slash2", [side_or(0, lambda d: idle[d]), side_or(2, lambda d: walk[d][3])])
    add("slash3", [side_or(0, lambda d: idle[d]), side_or(1, lambda d: walk[d][1]), side_or(2, lambda d: walk[d][3])])
    add("guard", [lambda d: _frame(idle[d]), lambda d: _frame(idle[d], squash=0.98)])
    add("dodge", [lambda d: _frame(walk[d][1], dy=-2), lambda d: _frame(walk[d][3])])
    add("hurt", [lambda d: _frame(idle[d], squash=0.95)])
    add("fall", [lambda d: _frame(idle[d], squash=0.7), lambda d: _frame(idle[d], squash=0.35)])
    add("tool", [lambda d: _frame(attack[0]) if d == "side" else _frame(idle[d])])
    add("swing", [lambda d: _frame(attack[1]) if d == "side" else _frame(walk[d][1]),
                  lambda d: _frame(attack[2]) if d == "side" else _frame(walk[d][3])])
    add("hold", [lambda d: _frame(attack[0]) if d == "side" else _frame(idle[d])])

    rows = ["down", "up", "side"]
    out = Image.new("RGBA", (FRAME[0] * len(cols), FRAME[1] * len(rows)), (0, 0, 0, 0))
    for r, d in enumerate(rows):
        for c, make in enumerate(cols):
            out.alpha_composite(make(d), (c * FRAME[0], r * FRAME[1]))
    meta = {
        "frame_size": list(FRAME), "pivot": list(PIVOT),
        "rows": {d: i for i, d in enumerate(rows)}, "side_faces": "right",
        "anims": anims,
        "fps": {"idle": 2, "walk": 8, "guard": 4, "dodge": 12, "fall": 6},
        "source": "design/art/referencias/personagens/11-yggnus-folha-de-personagem.png",
    }
    return out, meta


def main():
    os.makedirs(OUT, exist_ok=True)
    out, meta = build()
    out.save(os.path.join(OUT, "yggnus.png"))
    with open(os.path.join(OUT, "yggnus.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    print("yggnus: %d quadros por linha" % (out.width // FRAME[0]))


if __name__ == "__main__":
    main()
