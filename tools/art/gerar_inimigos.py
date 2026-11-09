"""Inimigos da fatia, Yame Black e Igris.

inimigos.png: quadros 32×48, pivô [16,44] (os pés), colunas em FRAMES.
igris.png: quadros 48×64, pivô [24,60], colunas em IGRIS_FRAMES.
Referência: pranchas 08 e 09 e as ilustrações de Yame e Igris do kit.
Guia: design/art/art-bible.md, Seção 5. O desenho está em inimigos_hd.py.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixel import sheet  # noqa: E402
from inimigos_hd import FY, H, IFY, IH, IW, W, guarda, igris, mariposa, rastejo, soldado, yame  # noqa: E402

FRAMES = [
    ("rastejo_idle0", rastejo, "idle0"), ("rastejo_idle1", rastejo, "idle1"),
    ("rastejo_telegraph", rastejo, "telegraph"), ("rastejo_charge", rastejo, "charge"),
    ("mariposa_fly0", mariposa, "fly0"), ("mariposa_fly1", mariposa, "fly1"),
    ("mariposa_dive", mariposa, "dive"), ("mariposa_land", mariposa, "land"),
    ("soldado_idle", soldado, "idle"), ("soldado_windup", soldado, "windup"),
    ("soldado_strike", soldado, "strike"),
    ("guarda_idle", guarda, "idle"), ("guarda_raise", guarda, "raise"), ("guarda_open", guarda, "open"),
    ("yame_idle", yame, "idle"), ("yame_telegraph", yame, "telegraph"),
]


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
