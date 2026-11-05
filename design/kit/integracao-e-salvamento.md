# A LENDA DE YGGNUS — INTEGRAÇÃO, SALVAMENTO E CONTEÚDO

## 1. Estrutura sugerida do projeto Godot

- scenes/main: inicialização, menu e transições.
- scenes/actors: Yggnus, NPC, inimigo-base e chefes.
- scenes/world: salas, portas, marcos e interativos.
- scenes/ui: HUD, pausa, inventário, mapa, caixa de fala e histórico.
- scripts/components: vida, hitbox, hurtbox, inventário, percepção e recibos únicos.
- scripts/services: sessão, salvamento, eventos, missões, diálogos e áudio.
- data: cópia validada dos catálogos e textos deste pacote.
- assets: sprites e sons produzidos a partir das referências.

Limitar os serviços globais: Session guarda estado da partida; SaveService lê e grava; DialogueService apresenta; AudioService organiza barramentos. Mundo e inimigos não precisam ser globais. UI não calcula dano e uma fala não altera Bronze diretamente.

## 2. Movimento e colisões

Yggnus e inimigos: CharacterBody2D em modo flutuante. Atualizar movimento no passo de física e usar os métodos de movimento do motor, preservando colisões. Hitbox e hurtbox são áreas separadas do corpo físico.

Convenção de camadas: 1 cenário; 2 corpo do jogador; 3 corpos inimigos; 4 NPC/interativo; 5 hitbox do jogador; 6 hurtbox do jogador; 7 hitbox inimiga; 8 hurtbox inimiga; 9 projétil; 10 sensor de porta; 11 perigo; 12 alvo de ferramenta. Documentar máscaras na cena-base. Uma espada não pode acertar o próprio usuário.

Y-sort usa o ponto dos pés. Telhados e arcos ficam em camada superior separada. O sprite não deve definir sozinho a colisão. Pivô e tamanhos precisam permanecer iguais entre skins.

## 3. Fluxo de eventos

O mundo emite um evento semântico depois de um resultado real, como obter_gancho ou igris_escolhe_sair. O DialogueService consulta trigger_id no arquivo. Verifica requires_all e requires_none e não inicia uma cena modal durante ataque ativo.

Ao terminar ou pular uma cena, preparar uma transação: flags seen, itens únicos e alterações permanentes. Aplicar tudo ou nada. Só depois atualizar missões, HUD e salvamento. Uma cena repetida pode tocar de novo quando permitido, mas recibos já usados não concedem item outra vez.

As missões concluem quando suas pré-condições e as cenas finais indicadas já estão confirmadas. Reavaliar missões até nenhuma nova conclusão surgir. Não concluir uma missão apenas porque o jogador abriu o mapa ou leu a descrição.

Os gatilhos são contratos. Ainda é necessário conectá-los a portas, NPC, baús, morte de grupo e máquinas de chefe no código. Ter o nome em JSON não implementa o acontecimento.

## 4. Interpretar os diálogos

Cada cena possui um nó de entrada e nós identificados. Tipos: line, direction, choice e end. line exibe fala; direction é indicação de encenação ou texto de tutorial, não dublagem automática. choice oferece perguntas explicativas e caminhos que convergem. end executa completion_effects.

Antes de usar o texto em uma caixa, substitua as referências de ação por ícones do InputMap, quando aplicável. Autoquebra usa largura da caixa, nunca palavras já cortadas no JSON. Mostrar até duas linhas visíveis e preservar texto completo no histórico.

As duas perguntas foram escritas para Morina e para a preparação com Exódia. Elas esclarecem detalhes, mas não mudam as decisões já definidas da campanha. O pacote não introduz um sistema de moralidade ou finais alternativos.

Falas delivery=bark são não modais, com recarga de 12 s; podem ser colocadas na fila e descartadas se ficaram antigas. Não repetir mais de uma mensagem de energia insuficiente em 3 s. Falas importantes têm prioridade sobre comentários de combate.

requires_all considera todos os flags listados verdadeiros; requires_none exige que todos sejam ausentes ou falsos. Cena não repetível marca seen.id. Os flags são strings registradas, não código para executar. Nunca interpretar texto de dados como script.

## 5. Objetos, moedas e recibos

Um baú tem ID estável que não depende da posição no array. Ao abrir: confirmar se o recibo não existe, calcular espaço, distribuir item/Bronze, adicionar recibo, marcar aberto e persistir. Fazer isso em uma atualização. Não marcar baú aberto antes de guardar o conteúdo.

Bronze vai até a capacidade da bolsa; excedente vai à reserva. Exemplo: bolsa com 190, capacidade 200 e coleta de 100 → 200 na bolsa e 90 na reserva. Reabrir a mesma coleta não altera nada. Reserva é um inteiro persistente e não um baú físico duplicável.

Itens de campanha não são vendidos nem descartados. Frascos têm ID e conteúdo; capacidade é um limite separado da quantidade de frascos existentes. Ter três espaços não gera automaticamente três frascos. Recompensa de Morina garante o terceiro espaço e o terceiro frasco numa transação única.

Fragmentos de Âncora têm 32 IDs individuais. O total recolhido determina a melhoria de vida, sem reiniciar o contador histórico quando quatro são convertidos. Fórmula: máximo = 6 + floor(fragmentos_unicos/4), limitado a 14. Mostrar resto/4 no HUD e preservar a lista de IDs.

## 6. Chave e portas do protótipo

A chave key_ak_base está no baú t00_base.ak_key, antes da primeira porta que a exige. A primeira abertura consome a chave e grava o flag open da porta. As visitas seguintes usam o flag e não cobram outra chave. Ida e volta referenciam o mesmo ID de porta.

world.guards_clear só é verdadeiro após os dois guardas designados serem vencidos. world.weight_locked surge após o peso ser fixado. world.bells_solved vem da sequência círculo → fenda → ondas. Esses flags não podem ser criados por abrir o inventário ou apenas ler uma dica.

A passagem do gancho é um vão real na grade, associado à aresta especial de travessia. O jogador não anda sobre o símbolo ~. O sistema de ferramenta verifica alcance, argola e piso seguro antes de iniciar o movimento.

## 7. Política de salvamento

Três slots de partida e um autosave por slot. Configurações de áudio, controles e acessibilidade ficam em arquivo separado. Não perder preferências ao iniciar nova partida.

Guardar: versão do schema, sala e entrada segura, marco, vida/energia máximas, inventário, conteúdo dos frascos, Bronze/reserva, skins, flags, missões, portas, baús, fragmentos e recibos. Não guardar como fonte da verdade: um timer de hitbox, alvo temporário, caminho de IA ou posição de um projétil no meio do chefe.

Salvar em arquivo temporário no mesmo diretório, fechar, reabrir para validar JSON e campos, preservar backup do último válido e só então substituir o arquivo principal. Testar interrupção antes e depois de cada etapa. Não sobrescrever silenciosamente todos os backups com um arquivo inválido.

No carregamento, validar números, IDs e limites. Resolver um ID de sala contra o catálogo permitido; não carregar um caminho arbitrário fornecido pelo save. Arquivos desconhecidos não executam comandos. Versões futuras exigem migração explícita ou aviso claro; não fingir compatibilidade.

Checksum pode detectar corrupção acidental, mas não é proteção contra edição de um jogo local. Não prometer antitrapaça ou criptografia segura por apenas codificar JSON.

Autosave: entrada segura de sala, conclusão de cena com efeito permanente, abertura de atalho, equipamento e marco. Esperar transações de inventário concluírem antes da gravação. Mensagem de salvando não bloqueia comandos por vários segundos.

## 8. Pausa e retomada

Pausa abre UI e suspende combate. Diálogo modal suspende danos, projéteis e timers da arena. Após fechar uma cena, não iniciar um ataque inimigo já no quadro ativo; retomar o estado ou recomeçar um aviso visível. Controle não pode ficar preso entre pausa e diálogo.

Perda de foco pausa no modo para computador, salvo configuração explícita. Desconectar controle abre aviso e permite continuar pelo teclado. Nenhum desses eventos apaga o conteúdo de uma tentativa de chefe.

## 9. Verificação dos dados

Execute validar_conteudo.py com Python 3. Ele verifica IDs, destinos de nós, caminhos de conversa, dependências sem ciclos, nomes de itens, aquisição, planta e passagem do gancho, fontes de chave e relações numéricas de progressão. O relatório identifica que são verificações estáticas e simulações de conteúdo.

Isso não verifica movimento, latência, diversão, colisões do motor ou um executável, que ainda não existem neste pacote. Esses pontos têm critérios no plano de implementação.

## 10. Referências técnicas

[CharacterBody2D](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html)

[Interpolação](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html)

[Salvamento](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html)

A arquitetura proposta é uma escolha do projeto; não é a única forma de usar o motor.
