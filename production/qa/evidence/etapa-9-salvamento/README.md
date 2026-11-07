# Evidência — Etapa 9: salvamento e exportação

Fonte: `design/kit/plano-implementacao.md` § Etapa 9; `integracao-e-salvamento.md` §7 (política de
salvamento) e §8 (pausa); `mecanicas-e-dificuldade.md` §9 (tentativa de chefe). Formato do arquivo:
`assets/data/salvamento-exemplo.json`.
Engine: Godot 4.7.2.stable.official.ed1daf0bf (Linux, Xvfb, opengl3).

## Como funciona

- **Três espaços** na tela de título. Espaço vazio começa um jogo novo; espaço salvo continua ou começa de
  novo (com confirmação). Cada espaço tem um salvamento automático com backup.
- **Quando salva:** ao entrar numa sala (porta, renascimento, carregamento), ao usar um marco, ao fim de
  uma cena com efeito, em cada transação de inventário (baú, pista, fragmento, compra, frasco), ao trocar
  o item do botão, ao sair pelo menu e ao fechar a janela. Uma gravação por quadro, depois das transações.
  Um aviso discreto "Jogo salvo" aparece no canto, sem bloquear comandos.
- **Onde volta:** na última entrada segura da sala (o ponto em que se entrou, ou ao lado do marco usado).
- **Igris:** durante a tentativa, o salvamento guarda o início dela (frascos, pão, vida, entrada da câmara).
  A vitória e o gasto da tentativa só são gravados juntos, quando a cena da vitória termina.
- **Gravação segura:** arquivo temporário → fechado, reaberto e validado → o principal válido vira backup
  (um danificado é guardado à parte, nunca sobre o backup) → o temporário vira o principal.
- **Leitura:** principal → temporário completo de uma gravação interrompida → backup. Valida versão, soma
  de verificação (só contra dano acidental), salas e itens do catálogo, entrada pisável, marco existente,
  limites de vida, Bronze, bolsa e frascos. Uma versão mais nova é recusada com aviso, sem fingir
  compatibilidade. Nada do arquivo vira caminho nem comando.
- **Preferências** (`settings.cfg`: último espaço, pausar ao perder o foco) ficam fora dos espaços e
  sobrevivem a um jogo novo.
- **Pausa:** Esc abre Continuar / Salvar e voltar ao título / Salvar e sair do jogo. Se a gravação falhar,
  o jogo não fecha e mostra o erro.

## Testes automatizados

`godot --headless --path . -s res://tests/run_tests.gd` → **169 passed, 0 failed**, sem SCRIPT ERROR.

| Critério da etapa | Teste |
|---|---|
| Progresso único não duplica nem some | `test_save::test_unique_progress_neither_duplicates_nor_disappears`, `test_save_flow::test_a_scene_with_rewards_is_saved_once_and_not_replayed`, `test_closing_during_the_victory_scene_keeps_win_and_supplies_together` |
| Arquivo inválido tem recuperação clara | `test_a_damaged_main_file_recovers_from_the_backup`, `test_nothing_readable_is_reported_as_damaged`, `test_an_edited_value_fails_the_checksum`, `test_title_offers_the_backup_when_the_save_is_damaged`, `test_starting_over_keeps_a_damaged_file_and_drops_old_copies` |
| Interrupção antes e depois de cada etapa da gravação | `test_closing_during_any_step_of_a_write_keeps_a_valid_save` |
| Backup nunca substituído por arquivo inválido | `test_a_damaged_file_is_never_written_over_the_backup` |
| Versão futura recusada com aviso | `test_a_newer_version_is_refused_with_a_clear_status` |
| Validação de IDs e limites | `test_validation_refuses_unknown_ids_and_limits` (12 casos) |
| Sair durante Igris volta à entrada da tentativa | `test_quitting_during_igris_returns_to_the_attempt_start` |
| Salvar/fechar/carregar em sala e transição | `test_close_and_load_after_a_door_returns_to_its_entry`, `test_a_marco_becomes_the_place_to_load`, `test_round_trip_keeps_every_saved_value` |
| Preferências separadas | `test_settings_are_kept_apart_from_the_slots`, `test_a_settings_value_of_the_wrong_type_keeps_the_default` |
| Título e pausa | `test_title_screen_starts_and_continues_slots`, `test_pause_menu_continues_and_offers_leaving` |

Revisão QA (sondagem sem interface): salvar, fechar e carregar nas **13 salas**; invasão de Yame com
amarras cortadas; morte e saída; os três arquivos danificados; fechar a janela.

## Pasta exportada

Os executáveis de Windows e Linux trazem os dados dentro (`embed_pck`, filtro `assets/data/*.json` e
`assets/data/maps/*.json`). O de Linux foi copiado para outra pasta e rodado com outro diretório de dados:
criou `slot_1.json`, depois continuou o espaço e criou `slot_1.bak.json`, sem erros. Nenhum caminho do
computador de desenvolvimento aparece no executável. Os salvamentos ficam na pasta de dados do usuário
(`%APPDATA%\Godot\app_userdata\A Lenda de Yggnus\saves` no Windows).

## Execução observada (640×360)

- `1_titulo_tres_espacos.png`: título com um espaço na Câmara de Igris, um com cópia recuperada e um vazio.
- `2_espaco_com_copia_recuperada.png`: o aviso claro de recuperação e as opções.
- `3_menu_de_pausa.png`: menu de pausa com Continuar, voltar ao título e sair; "Jogo salvo" no canto.
- `4_continuar_na_entrada_de_igris.png`: espaço continuado na entrada da câmara de Igris.

## Revisão (Game Studios)

`/code-review` com `godot-gdscript-specialist` e `qa-tester`: todos os achados verificados foram corrigidos
(vitória sobre Igris perdida ao fechar durante a cena t10, marco e fragmentos inexistentes aceitos,
`settings.cfg` com tipo errado travava a abertura, sair após falha de gravação sem aviso, `--slot` apagando
backup de espaço ilegível, aviso de recuperação impreciso, avisos de tipagem).
