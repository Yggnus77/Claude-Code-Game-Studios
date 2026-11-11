# Smoke check: jogabilidade clássica (teste18), 2026-11-11

GDD: `design/gdd/jogabilidade-classica.md`.

## Suíte automática

`godot --headless --path . -s res://tests/run_tests.gd`: **280 passaram, 0 falharam**.

Testes novos:

- `tests/unit/combat/test_sword_swing.gd` cobre o golpe, o arco, a carga, o giro, a espera da estocada, a varredura e os corações.
- `tests/integration/combat/test_classic_play.gd` cobre:
  - a frente inteira e as costas;
  - o giro nos quatro lados;
  - andar de lado carregando;
  - o escudo passivo, que fica baixo durante o golpe e a carga;
  - a falta de esquiva livre;
  - o recuo e a invencibilidade;
  - a linha de teclas;
  - o HUD;
  - o arco na torre;
  - o sino que toca uma vez;
  - a estocada por inimigo;
  - o save antigo.

## Revisão (especialista GDScript e QA), corrigido

1. A lâmina segurada tocava o sino de novo (quebrava a ordem de Igris e de t05) e contava como golpe no regulador e nas amarras. Agora a estocada só atinge inimigos comuns, começa depois de `poke_interval` e conta por inimigo.
2. Um save antigo com o arco ganhava um baú na torre que dizia "Recebeu..." sem dar nada. Agora o baú diz "Vazio. Você já tem o que estava aqui."
3. Espaço, Shift, B e LB ficavam presos às ações removidas. Agora estão livres.
4. O Broche da Vigília não fazia nada. Agora alarga o escudo (140°).
5. A lâmina era desenhada 6 px acima de onde acertava. Agora usa um pivô só.
6. A linha de teclas mostrava o frasco sem frasco. Agora só mostra o que o jogador tem.
7. Textos e documentos sobre esquiva e defesa precisa:
   - a fala das Botas;
   - o comentário de Igris;
   - o protocolo do playtest, que agora registra o primeiro giro;
   - a nota no kit de mecânicas.
8. Código e teste mortos da linha de chaves antiga.

## Evidência visual

`production/qa/evidence/jogabilidade-classica/` (01 a 12):

- o começo sem nada;
- o golpe para a direita, para cima e para a esquerda;
- a carga, a carga cheia e o giro;
- o HUD com corações, meio coração e a caixa do arco;
- o HUD na masmorra.

## Ainda não verificado em jogo

- A luta com Igris sem esquiva. A conta foi feita: a onda tem raio de 26 px e aviso de pelo menos 0,75 s, e para sair andando bastam cerca de 0,3 s.
- A sensação geral é para o playtest do usuário.
