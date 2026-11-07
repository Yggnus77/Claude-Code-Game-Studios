# Arte P1 — evidências

Pixel art original gerada por `tools/art/gerar_tudo.py` (guia em `design/art/art-bible.md`).

- `1_yggnus_no_jogo.png`: parado, andando de lado, preparando o corte e defendendo (praça).
- `2_salas.png`: oficina, praça, estrada, guardas, pesos e sinos com o cenário novo.
- `3_inimigos_yame_igris.png`: Rastejo, Mariposa, Soldado e Guarda; Yame na oficina com as amarras; Igris na câmara.
- `4_correcoes_da_revisao.png`: avisos por cima dos inimigos (Rastejo, Soldado virado para cima, "!" do Guarda aberto),
  bloco de granito claro em t04, Yggnus atrás do NPC (quem está mais abaixo na tela fica na frente) e o arco da defesa
  virado para cima.
- `5`–`9`: as folhas de quadros ampliadas 4×.

## Revisão (Game Studios)

`/code-review` com `godot-gdscript-specialist` e `qa-tester`. Corrigido:
- aviso do Rastejo e anel do Soldado ficavam por baixo do desenho; o Rastejo voltou a inflar ao preparar;
- o golpe do Soldado virado para cima ou para baixo apontava para o lado (agora mostra a lâmina na direção real);
- "!" do Guarda aberto ficava em cima do elmo; peso cinza trocado por latão;
- bloco de puxar tinha a mesma cor do piso da torre;
- personagens e NPCs agora se ordenam pela altura na tela (NPC e marco viraram nós próprios);
- defesa virada para cima não aparecia: o arco da defesa voltou, com ciano na defesa precisa;
- placa de examinar parecia a argola do gancho; pista ganhou "?"; marco apagado ficou mais claro;
- Mariposa pousada ganhou pose própria e em descanso não bate asas;
- divisões inteiras em relógios de animação.
