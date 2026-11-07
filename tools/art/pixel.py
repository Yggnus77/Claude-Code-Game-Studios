"""Small pixel-art toolkit for A Lenda de Yggnus.

Every sprite in assets/art is drawn by these scripts, pixel by pixel, from the
palette below (taken from the kit's concept illustrations). Nothing is traced
or copied from another source, so the art is original and carries the
project's own license.

Run from the repo root:  python3 tools/art/gerar_tudo.py
"""

from PIL import Image

# Paleta do guia de arte (design/art/art-bible.md, Seção 4).
PAL = {
    # contorno e sombras
    "outline": "#1b1420",
    "shadow": "#00000055",
    # pele e cabelo
    "skin": "#9a6644", "skin_hi": "#b98058", "skin_lo": "#74482f",
    "hair": "#211a1e", "hair_hi": "#3a2c30",
    # casaco índigo de Yggnus
    "coat": "#3d4583", "coat_hi": "#5560a6", "coat_lo": "#2a2f5e",
    "gold": "#d4a849", "gold_lo": "#9c7530",
    # couro, calça, botas
    "leather": "#7a4b30", "leather_hi": "#9a6440", "leather_lo": "#4f2f20",
    "pants": "#5b4334", "pants_lo": "#3f2e25",
    "boot": "#3e2a22", "boot_hi": "#5a3e30",
    # cachecol e camisa
    "cloth": "#e6dcc2", "cloth_lo": "#bfb196",
    # metal da espada
    "steel": "#d8dee6", "steel_lo": "#8f99a6",
    # cristal (Matrix)
    "crystal": "#5ee6e0", "crystal_hi": "#c8fffb",
    # pedra da torre e cidade
    "stone": "#5b4f66", "stone_hi": "#776a80", "stone_lo": "#3d3449", "stone_dk": "#2a2436",
    "night": "#141a2e",
    "wood": "#7b5236", "wood_hi": "#9c6c45", "wood_lo": "#523522",
    "brass": "#b8873a", "brass_hi": "#e0b555", "brass_lo": "#7d5a26",
    "lamp": "#f2b84a", "lamp_hi": "#ffe39a",
    "carpet": "#8a2f35", "carpet_hi": "#a8434a",
    "grass": "#4f6b3a", "grass_hi": "#6b8a4a", "grass_lo": "#38502a",
    "dirt": "#8a6a4a", "dirt_hi": "#a3825c", "dirt_lo": "#6b5038",
    "cobble": "#8c8378", "cobble_hi": "#a59c90", "cobble_lo": "#6a6259",
    "water": "#2f5a7a", "water_hi": "#4f86a8",
    "plank": "#a07850", "plank_lo": "#7a5a3a",
    # Yame Black (papel)
    "paper_dk": "#231b1e", "paper": "#3a2e33", "paper_hi": "#564650",
    "ember": "#f5a83a", "ember_hi": "#ffd98a",
    "rust": "#8e3a2a", "rust_hi": "#b0503a",
    # Igris (latão, roxo do manto)
    "robe": "#4a3566", "robe_hi": "#634a85", "robe_lo": "#33244a",
    # sinais de jogo
    "danger": "#e0503c", "danger_hi": "#ff8a6a",
    "safe": "#7ee0ff",
    "white": "#ffffff",
}


def rgba(name_or_hex):
    v = PAL.get(name_or_hex, name_or_hex)
    v = v.lstrip("#")
    if len(v) == 6:
        v += "ff"
    return tuple(int(v[i:i + 2], 16) for i in (0, 2, 4, 6))


class Canvas:
    """A frame of w×h pixels with helpers that never draw out of bounds."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.px = self.img.load()

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[x, y] = rgba(c)

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[x, y]
        return (0, 0, 0, 0)

    def rect(self, x, y, w, h, c):
        for j in range(y, y + h):
            for i in range(x, x + w):
                self.put(i, j, c)

    def hline(self, x0, x1, y, c):
        for i in range(min(x0, x1), max(x0, x1) + 1):
            self.put(i, y, c)

    def vline(self, x, y0, y1, c):
        for j in range(min(y0, y1), max(y0, y1) + 1):
            self.put(x, j, c)

    def line(self, x0, y0, x1, y1, c):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.put(x0, y0, c)
            if x0 == x1 and y0 == y1:
                return
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def ellipse(self, cx, cy, rx, ry, c):
        for j in range(-ry, ry + 1):
            for i in range(-rx, rx + 1):
                if (i * i) / max(rx * rx, 0.25) + (j * j) / max(ry * ry, 0.25) <= 1.0:
                    self.put(cx + i, cy + j, c)

    def outline(self, c="outline"):
        """Dark one-pixel outline around every opaque pixel (4-neighbour)."""
        col = rgba(c)
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[x, y][3] != 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if self.get(x + dx, y + dy)[3] > 200 and self.get(x + dx, y + dy) != col:
                        add.append((x, y))
                        break
        for x, y in add:
            self.px[x, y] = col

    def flipped(self):
        c = Canvas(self.w, self.h)
        c.img = self.img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        c.px = c.img.load()
        return c


def sheet(frames, cols):
    """Packs equal-size canvases left to right, top to bottom."""
    w, h = frames[0].w, frames[0].h
    rows = (len(frames) + cols - 1) // cols
    out = Image.new("RGBA", (w * cols, h * rows), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f.img, ((i % cols) * w, (i // cols) * h))
    return out
