"""Yggnus de frente, desenhado à mão pixel a pixel (versão detalhada).

Cada linha é texto: uma letra por pixel (legenda em LEGENDA). O corpo é
montado em camadas (cabeça, cachecol, tronco, braços, pernas) para que as
poses de andar e de ataque reaproveitem as mesmas peças.
"""

LEGENDA = {
    ".": None,
    "K": "#1b1420",
    "H": "#231c22", "h": "#3b2d35", "j": "#5c4552",
    "S": "#a06a46", "s": "#7a4b31", "L": "#c48d63",
    "E": "#1b1420", "w": "#f4ecdc",
    "C": "#3f4790", "c": "#2b3066", "D": "#1d2148", "B": "#5b67b5",
    "G": "#d9ad4f", "g": "#9c7530",
    "F": "#ebe2c9", "f": "#c4b796", "v": "#948866",
    "T": "#7d4d31", "t": "#4f2f20", "R": "#a8714a",
    "N": "#d9cfb4", "n": "#a99f86",
    "P": "#5e4637", "p": "#3f2e25", "q": "#7a5c48",
    "O": "#3a2720", "o": "#5c4033", "b": "#24181a",
    "M": "#dfe5ec", "m": "#8f99a6",
}

CABECA = {
    6: (12, "KK.KKK.KK"),
    7: (10, "KKhhKhhhKhhKK"),
    8: (9, "KhhjhhhhhjhhhK"),
    9: (9, "KhjjhhhhhhjhhK"),
    10: (9, "KhhhhhhhhhhhhK"),
    11: (9, "KhHhhHhhhHhhHK"),
    12: (9, "KHHhLSSHSSSHHK"),
    13: (9, "KHLSSSSSSSSsHK"),
    14: (9, "KHSHHSSSSHHsHK"),
    15: (9, "KHSSESSSSESsHK"),
    16: (9, "KHSSESSSSESsHK"),
    17: (9, "KHLSSSSsSSSsHK"),
    18: (10, "KSSSSssSSssK"),
    19: (11, "KsSSSSSSssK"),
}

CACHECOL = {
    20: (10, "KFFFFFFFFFFK"),
    21: (9, "KFFFFfFFFFffFK"),
    22: (9, "KfFFfffFFffffK"),
    23: (7, "KKBCvfffvvffvCccKK"),
}

TRONCO = {   # x 9..22
    24: "CCCGNNNNNNGCcc",
    25: "CCBGNnNNnNGCcc",
    26: "CCBGTNNNnNGCcc",
    27: "CCBGNTNNnNGCcc",
    28: "CCBGNNTNnNGCcc",
    29: "CCCGNNNTnGGCcc",
    30: "TTTTTTGGTTTTTt",
    31: "CCBGRRtPPpGCcc",
    32: "CCBGRRtPPpGCcc",
    33: "CCBGttPPPpGCcc",
    34: "CCBGPPPPPpGCcD",
    35: "CCCGPPppPpGccD",
    36: "GGGgPPppPpgGGg",
}

BRACO_E = {24: "KBc", 25: "KBc", 26: "KBc", 27: "KBc", 28: "KCc", 29: "KCc", 30: "KFf", 31: "KSs", 32: "KSs", 33: ".KK"}
BRACO_D = {24: "cDK", 25: "cDK", 26: "cDK", 27: "cDK", 28: "cDK", 29: "cDK", 30: "ffK", 31: "sSK", 32: "ssK", 33: "KK."}

PERNA_E = {37: "KqPPpK", 38: "KqPPpK", 39: "KFFFfK", 40: "KOooOK", 41: "KOoOOK", 42: "KOOOOK", 43: "KbbbbK"}
PERNA_D = {37: "KqPPpK", 38: "KqPPpK", 39: "KFFFfK", 40: "KOooOK", 41: "KOoOOK", 42: "KOOOOK", 43: "KbbbbK"}


def montar(c, put, bob=0, pe_e=0, pe_d=0, braco_e=0, braco_d=0):
    """Desenha a pose em c: put(x, y, cor). bob e os deslocamentos movem peças."""
    def linha(y, x0, txt):
        for i, ch in enumerate(txt):
            col = LEGENDA.get(ch)
            if col:
                put(x0 + i, y, col)
    # pernas primeiro (o casaco cobre o topo)
    for y, t in PERNA_E.items():
        linha(y + pe_e if y < 43 else y + min(pe_e, 0), 10, t) if True else None
    for y, t in PERNA_D.items():
        linha(y + pe_d if y < 43 else y + min(pe_d, 0), 17, t)
    for y, t in TRONCO.items():
        linha(y + bob, 9, t)
    for y, t in BRACO_E.items():
        linha(y + bob + braco_e, 6, t)
    for y, t in BRACO_D.items():
        linha(y + bob + braco_d, 23, t)
    # bainha da espada no quadril esquerdo
    for i in range(8):
        put(8 - i // 3, 31 + bob + i, "#4f2f20")
    put(8, 30 + bob, "#d9ad4f")
    put(6, 39 + bob, "#9c7530")
    for y, (x0, t) in CACHECOL.items():
        linha(y + bob, x0, t)
    for y, (x0, t) in CABECA.items():
        linha(y + bob, x0, t)
