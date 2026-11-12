"""Gera todas as folhas de arte do jogo (assets/art). Uso: python3 tools/art/gerar_tudo.py"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

import gerar_cenario  # noqa: E402
import gerar_interface  # noqa: E402
import gerar_salas  # noqa: E402
import inimigos_referencia  # noqa: E402
import yggnus_referencia  # noqa: E402

if __name__ == "__main__":
    yggnus_referencia.main()
    gerar_cenario.main()
    inimigos_referencia.main()
    gerar_interface.main()
    gerar_salas.main()
