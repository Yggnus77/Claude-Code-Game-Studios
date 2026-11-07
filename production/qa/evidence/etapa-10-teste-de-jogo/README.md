# Evidência — Etapa 10: preparação do teste de jogo

Fonte: `design/kit/plano-implementacao.md` § Etapa 10; `mecanicas-e-dificuldade.md` §13.
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

A etapa é um teste com cinco pessoas, conduzido pelo autor. Esta entrega prepara o teste. Os critérios
da etapa (travamentos, entendimento do gancho, ataques percebidos, aprendizado contra Igris, fim da
fatia) só se fecham com as sessões reais.

## O que foi feito

- **Registro automático** (`src/state/playtest_log.gd`, ligado em `src/main.gd`). Ao jogar num espaço, o
  jogo grava `user://playtest/sessao-<data>-espaco<n>.txt` (resumo legível) e `.json` (dados) ao entrar
  em cada sala, ao sair e ao fechar a janela. O registro traz:
  - mortes e golpes recebidos por origem (o atacante se identifica ao acertar);
  - o primeiro uso de espada, defesa, defesa precisa e gancho;
  - as tentativas contra Igris, com resultado (morte, vitória, reiniciou, saiu) e duração;
  - os comandos sem efeito e as salas reiniciadas com R;
  - cada entrada em sala, com chegada e tempo, e o fim da fatia.

  O relógio começa ao escolher o espaço. O registro pode ser desligado com `playtest_log=false` em
  `settings.cfg`.
- **Menu de pausa:** "Abrir a pasta dos registros de teste".
- **Roteiro e ficha:** `production/qa/playtests/roteiro-etapa-10.md`, baseado no modelo do estúdio
  (`/playtest-report new`), com as perguntas da etapa.

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **175 passed, 0 failed**.

- `tests/unit/state/test_playtest_log.gd`: mortes por sala e causa, primeiro uso, tentativas de Igris,
  comandos sem efeito, salas e tempos.
- `test_save_flow::test_the_playtest_record_follows_the_session`: R no meio da luta encerra a tentativa,
  a morte encerra a seguinte, causa "onda de Igris", arquivos gravados.
- `test_save_flow::test_continuing_a_finished_save_is_not_a_new_finish`.

## Execução observada

- `1_pausa_com_registros_de_teste.png`: menu de pausa com a nova opção.
- `2_exemplo_de_registro.txt`: resumo gravado por uma sessão curta roteirizada (salas, golpe de guarda,
  ondas reais de Igris). Os tempos são de segundos porque a sessão foi automática.
- `3_espada_em_yame.png`: a espada chega em Yame Black e o jogo avisa que ela não fere Yame e que é
  preciso cortar as amarras da porta (resposta ao teste do usuário, em que a espada "não deu dano").

- `4_objetivo_na_praca_durante_invasao.png`: depois de morrer na invasão e voltar no marco da praça, a
  linha de objetivo manda voltar à oficina. No teste do usuário (sessão 2026-11-06 23:43) ela só dizia
  "Corte as amarras da porta" e ele passou 4 min 43 s na praça sem saber para onde ir.

## Revisão (Game Studios)

`/code-review` com `godot-gdscript-specialist` e `qa-tester`. Todos os achados verificados foram corrigidos:
- uma tentativa de Igris encerrada com R ou ao sair da câmara sumia;
- a causa da morte pela onda de Igris saía errada perto dos sinos;
- continuar um jogo já terminado registrava um falso fim;
- o primeiro golpe nas amarras de Yame não contava como primeiro acerto;
- faltavam golpes sem morte, tempo por sala e tempo até Igris;
- o relógio contava a tela de título;
- a ficha não tinha campos para golpe sem ver e para pessoa parada;
- um comentário de documentação estava fora do lugar.
