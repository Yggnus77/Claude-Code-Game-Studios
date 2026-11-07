"""Gera todas as folhas de arte do jogo (assets/art). Uso: python3 tools/art/gerar_tudo.py"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

import gerar_cenario  # noqa: E402
import gerar_inimigos  # noqa: E402
import gerar_yggnus  # noqa: E402

if __name__ == "__main__":
    gerar_yggnus.main()
    gerar_cenario.main()
    gerar_inimigos.main()
