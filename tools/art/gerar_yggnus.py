"""Yggnus, roupa inicial: folha de quadros 32×48, pivô [16,44].

Linhas: 0 = de frente (baixo), 1 = de costas (cima), 2 = de lado (direita;
o jogo espelha para a esquerda). Colunas: ver POSES. O desenho de cada
vista está em yggnus_hd.py (feito à mão, linha a linha); aqui ficam as
poses e a folha. Cores e proporções: design/art/art-bible.md.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixel import sheet  # noqa: E402
import yggnus_hd as hd  # noqa: E402

W, H = 32, 48
FOOT_Y = 44

# Pose: bob (corpo sobe/desce), pés (dx, dy), braços (dx, dy), extras.
BASE = {"bob": 0, "lf": (0, 0), "rf": (0, 0), "la": (0, 0), "ra": (0, 0),
        "blade": None, "shield": False, "hurt": False, "tool": False, "crouch": 0,
        "stride": 0}


def pose(**kw):
    p = dict(BASE)
    p.update(kw)
    return p


# Ordem das colunas e quantos quadros cada animação usa.
POSES = [
    ("idle", pose()),
    ("idle", pose(bob=1)),
    ("walk", pose(lf=(0, -2), rf=(0, 0), la=(0, 1), ra=(0, -1), bob=-1, stride=2)),
    ("walk", pose(lf=(0, 0), rf=(0, 0), bob=0)),
    ("walk", pose(lf=(0, 0), rf=(0, -2), la=(0, -1), ra=(0, 1), bob=-1, stride=-2)),
    ("walk", pose(lf=(0, 0), rf=(0, 0), bob=0)),
    ("slash1", pose(ra=(1, -4), blade="wind_r", bob=0)),
    ("slash1", pose(ra=(0, 2), blade="hit_r", bob=1, lf=(0, 0))),
    ("slash2", pose(la=(-1, -4), blade="wind_l", bob=0)),
    ("slash2", pose(la=(0, 2), blade="hit_l", bob=1)),
    ("slash3", pose(ra=(0, -6), la=(0, -6), blade="wind_up", bob=-1)),
    ("slash3", pose(ra=(0, 3), la=(0, 3), blade="hit_down", bob=2, crouch=1)),
    ("slash3", pose(ra=(0, 2), la=(0, 2), blade="rest", bob=2, crouch=1)),
    ("guard", pose(shield=True, bob=1)),
    ("guard", pose(shield=True, bob=0)),
    ("dodge", pose(bob=3, crouch=2, la=(-1, 2), ra=(1, 2))),
    ("dodge", pose(bob=6, crouch=4, la=(0, 3), ra=(0, 3))),
    ("hurt", pose(hurt=True, bob=-1, la=(-2, -2), ra=(2, -2))),
    ("fall", pose(bob=5, crouch=3, la=(0, 4), ra=(0, 4))),
    ("fall", "lying"),
    ("tool", pose(tool=True, ra=(1, -1))),
    # Espada clássica (design/gdd/jogabilidade-classica.md): só o braço; a
    # lâmina grande é desenhada pelo jogo, girando.
    ("swing", pose(ra=(1, -4), bob=0)),
    ("swing", pose(ra=(0, 2), bob=1, blade="arm")),
    ("hold", pose(ra=(0, 1), blade="arm")),
]


def anims():
    out = {}
    for i, (name, _) in enumerate(POSES):
        out.setdefault(name, []).append(i)
    return out


def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    out_dir = os.path.join(root, "assets", "art", "personagens")
    os.makedirs(out_dir, exist_ok=True)
    frames = []
    for view in ("down", "up", "side"):
        for _, p in POSES:
            frames.append(hd.lying() if p == "lying" else hd.VIEWS[view](p))
    img = sheet(frames, len(POSES))
    img.save(os.path.join(out_dir, "yggnus.png"))
    meta = {
        "frame_size": [W, H], "pivot": [16, FOOT_Y],
        "rows": {"down": 0, "up": 1, "side": 2}, "side_faces": "right",
        "anims": anims(),
        "fps": {"idle": 2, "walk": 8, "guard": 4, "dodge": 12, "fall": 6},
    }
    with open(os.path.join(out_dir, "yggnus.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    print("yggnus.png", img.size, len(frames), "quadros")


if __name__ == "__main__":
    main()
