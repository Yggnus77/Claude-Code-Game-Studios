# Kit de design — A Lenda de Yggnus

Material do autor (A.Jordan Coelho), trazido de `rouge-kit-desenvolvimento-completo.zip`
em 2026-11-05. O título de trabalho "Rouge: Reset Sistem" foi trocado por
**A Lenda de Yggnus**. "Rouge" continua sendo o nome do arquipélago onde o jogo se passa.

## Onde está cada coisa

| Conteúdo | Caminho |
|---|---|
| Documentação (mecânicas, plano, auditoria, diálogos, mistérios, salvamento, arte pendente) | `design/kit/*.md` |
| Roteiro completo e catálogo do atlas | `design/kit/roteiro-jogo-completo.md`, `design/kit/catalogo-atlas.md` |
| Plantas das 13 salas (SVG e grade CSV, para leitura) | `design/kit/plantas/` |
| Dados que o jogo lê (combate, inimigos, itens, missões, diálogos…) | `assets/data/*.json` |
| Salas que o jogo lê | `assets/data/maps/*.json` |
| Validador de conteúdo do kit e seu último relatório | `tools/content/` |

A planilha de localização (`dialogos-localizacao.csv`) e as grades CSV ficam em `design/kit/`
porque o Godot importa todo `.csv` dentro do projeto como tradução.

As ilustrações conceituais (~70 MB) não foram versionadas. Continuam no ZIP original, nos
arquivos do projeto.

O validador (`tools/content/validar_conteudo.py`) ainda espera a estrutura antiga do ZIP
(`dados/`, `mapas/`). Ajustar os caminhos antes de usá-lo aqui.
