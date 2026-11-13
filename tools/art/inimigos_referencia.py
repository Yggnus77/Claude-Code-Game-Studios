"""Inimigos, Yame Black e Igris a partir das folhas do usuário.

Referência 12 (papel e tinta): rastejo de tinta, mariposa de papel e Yame
Black. Referência 13 (máquina): soldado de corda, guarda do contrapeso e
Igris. Cada figura é recortada do fundo roxo (recorte.py), reduzida ao
tamanho do jogo e repetida nos quadros que o jogo usa, com pequenas
variações (respiro, brilho do aviso, esticada do bote). Os nomes dos quadros
e o pivô seguem assets/art/personagens/inimigos.json, lido por SpriteAtlas.

Uso: python3 tools/art/inimigos_referencia.py (também roda em gerar_tudo.py)
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image  # noqa: E402

from recorte import pose, quadro  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
REFS = os.path.join(ROOT, "design", "art", "referencias", "personagens")
OUT = os.path.join(ROOT, "assets", "art", "personagens")

PAPEL = os.path.join(REFS, "12-inimigos-de-papel-e-tinta.png")
MAQUINA = os.path.join(REFS, "13-inimigos-de-maquina-e-igris.png")
BG_PAPEL = (110, 65, 109)
BG_MAQUINA = (108, 63, 107)

# Quadros dos inimigos comuns e de Yame: os pés 2 px abaixo do pivô, como
# nas folhas antigas (os nós desenham com o mesmo deslocamento).
FRAME, PIVOT = (48, 56), (24, 52)
FEET = (PIVOT[0], PIVOT[1] + 2)
IGRIS_FRAME, IGRIS_PIVOT = (80, 72), (40, 68)
IGRIS_FEET = (IGRIS_PIVOT[0], IGRIS_PIVOT[1] + 2)

# Recortes (x, y, largura, altura) na imagem de 1672 × 941; altura no jogo.
FIGURAS = {
    "rastejo": {"src": PAPEL, "bg": BG_PAPEL, "box": (62, 386, 531, 342), "h": 21},
    "mariposa": {"src": PAPEL, "bg": BG_PAPEL, "box": (538, 223, 605, 409), "h": 24},
    "yame": {"src": PAPEL, "bg": BG_PAPEL, "box": (1168, 271, 451, 440), "h": 40},
    "soldado": {"src": MAQUINA, "bg": BG_MAQUINA, "box": (61, 490, 242, 347), "h": 38, "flip": True},
    "guarda": {"src": MAQUINA, "bg": BG_MAQUINA, "box": (332, 346, 471, 495), "h": 40},
    "igris": {"src": MAQUINA, "bg": BG_MAQUINA, "box": (851, 2, 788, 843), "h": 62},
}


def _fig(nome):
    f = FIGURAS[nome]
    return pose(Image.open(f["src"]), f["box"], f["bg"], f["h"], flip=f.get("flip", False))[0]


def main():
    os.makedirs(OUT, exist_ok=True)
    fig = {n: _fig(n) for n in FIGURAS}
    q = lambda nome, **kw: quadro(FRAME, FEET, fig[nome], **kw)  # noqa: E731
    small = {"sombra": (7.5, 2.0)}
    frames = [
        ("rastejo_idle0", q("rastejo", **small)),
        ("rastejo_idle1", q("rastejo", sx=1.04, sy=0.92, **small)),
        ("rastejo_telegraph", q("rastejo", sy=1.06, clarear=0.25, **small)),
        ("rastejo_charge", q("rastejo", sx=1.15, sy=0.85, **small)),
        ("mariposa_fly0", q("mariposa", dy=-14, **small)),
        ("mariposa_fly1", q("mariposa", dy=-15, sx=0.8, **small)),
        ("mariposa_dive", q("mariposa", dy=-8, sy=0.85, clarear=0.15, **small)),
        ("mariposa_land", q("mariposa", sx=0.45, **small)),
        ("soldado_idle", q("soldado")),
        ("soldado_windup", q("soldado", sy=0.97, clarear=0.15)),
        ("soldado_strike", q("soldado", sx=1.06)),
        ("guarda_idle", q("guarda", sombra=(11, 2.5))),
        ("guarda_raise", q("guarda", dy=-3, clarear=0.12, sombra=(11, 2.5))),
        ("guarda_open", q("guarda", sy=0.94, sombra=(11, 2.5))),
        ("yame_idle", q("yame")),
        ("yame_telegraph", q("yame", clarear=0.2)),
    ]
    sheet = Image.new("RGBA", (FRAME[0] * len(frames), FRAME[1]), (0, 0, 0, 0))
    for i, (_, im) in enumerate(frames):
        sheet.alpha_composite(im, (i * FRAME[0], 0))
    sheet.save(os.path.join(OUT, "inimigos.png"))

    igris_frames = [("idle", 0.0), ("muffler", 0.04), ("regulator", 0.08), ("free", 0.12)]
    ig = Image.new("RGBA", (IGRIS_FRAME[0] * len(igris_frames), IGRIS_FRAME[1]), (0, 0, 0, 0))
    for i, (_, light) in enumerate(igris_frames):
        ig.alpha_composite(quadro(IGRIS_FRAME, IGRIS_FEET, fig["igris"], clarear=light, sombra=(16, 3)), (i * IGRIS_FRAME[0], 0))
    ig.save(os.path.join(OUT, "igris.png"))

    meta = {
        "frame_size": list(FRAME), "pivot": list(PIVOT), "frames": [n for n, _ in frames],
        "igris": {"frame_size": list(IGRIS_FRAME), "pivot": list(IGRIS_PIVOT), "frames": [n for n, _ in igris_frames]},
        "source": ["design/art/referencias/personagens/12-inimigos-de-papel-e-tinta.png",
                   "design/art/referencias/personagens/13-inimigos-de-maquina-e-igris.png"],
    }
    with open(os.path.join(OUT, "inimigos.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    print("inimigos", len(frames), "igris", len(igris_frames))


if __name__ == "__main__":
    main()
