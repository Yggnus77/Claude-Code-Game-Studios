# A LENDA DE YGGNUS — ESPECIFICAÇÃO DE MECÂNICAS E DIFICULDADE

Versão 1.1. Esta especificação complementa o roteiro e o atlas; em divergências de regra, prevalece sobre as versões 1.0. Os acontecimentos e decisões da história permanecem iguais. Os números são parâmetros iniciais verificáveis no protótipo, não uma garantia de diversão já comprovada.

## 1. Meta de experiência

Um jogo responsivo e exigente: o jogador ganha pela leitura, posicionamento e uso das ferramentas. Não haverá necessidade de repetir monstros para melhorar atributos nem mortes provocadas por ataques invisíveis. Dificuldade virá de decisões sob pressão, não de prolongar a vida dos adversários.

A modalidade padrão se chama Aventureiro e já exige atenção. Veterano combina padrões e reduz algumas recuperações depois de aprendidos; não remove avisos nem esconde a colisão. Acessibilidade é independente da modalidade: remapeamento, redução de flashes, repetição visual de notas e velocidade de texto não reduzem recompensas.

Primeiro alvo: computador, teclado e controle. Motor de referência: Godot 4, edição estável, com GDScript e renderizador Compatibility. Registrar a versão exata escolhida no projeto e não atualizar no meio de uma etapa sem testar o salvamento e as cenas. O pacote contém especificações e dados, não um projeto executável de Godot.

## 2. Escala, câmera e fluidez

Resolução lógica inicial: 640 × 360. Grade de cenário: 16 px. Personagem-base: quadro de 32 × 48 px, origem nos pés, colisão de 12 × 10 px. A arte ocupa mais espaço que o corpo que colide, para permitir passar por portas sem prender o cabelo ou o casaco.

Movimento em oito direções, com vetor normalizado: andar na diagonal não aumenta a velocidade. Espada, defesa e gancho usam quatro direções cardinais no primeiro protótipo; a direção acompanha a componente dominante do movimento. Empate diagonal mantém a última direção. Não inventar oito animações antes de validar as quatro.

Velocidade de caminhada: 110 px/s. Aceleração: 1.400 px/s²; desaceleração: 1.800 px/s². Alvo de resposta: deslocamento perceptível no próximo passo de física. Sem aceleração longa que pareça escorregamento. Paredes usam deslizamento; esquiva também respeita colisão.

Física a 60 passos/s; lógica usa tempo em segundos e não contagem de quadros de renderização. Arte em filtro nearest, escala inteira sempre que couber. Câmera acompanha uma zona central pequena e fica limitada aos limites da área. Testar interpolação com câmera e pixel snapping juntos: manter posição física fracionária e só arredondar a representação, evitando tremor. Ao mudar de sala, reposicionar e reiniciar interpolação.

Transição de sala: aproximadamente 0,18 s de escurecimento e 0,18 s de retorno, sem dano durante a transição. O jogador aparece em piso seguro, pelo menos 32 px distante de uma hitbox inimiga. Se o ponto estiver ocupado, escolher o primeiro ponto seguro da lista da porta; não empurrar o jogador para fora do mapa.

## 3. Controles e prioridade das ações

Movimento: WASD/direcional. Espada: J/X. Interagir: K/A. Esquiva: Espaço/B. Item: L/Y. Defender: Shift/LB. Troca rápida: Q/RB. Mapa: Tab/Select. Pausa: Esc/Start. Todas as ações são remapeáveis; caixas de diálogo mostram a ação configurada, não uma letra fixa.

Buffer de entrada: 0,12 s para ataque, item e esquiva. Pressionar durante o fim da recuperação pode executar a ação assim que ficar disponível, sem exigir uma janela de um quadro. Uma entrada é consumida uma única vez. Prioridade quando chegam juntas: dano inevitável já confirmado → morte → mudança de sala autorizada → esquiva disponível → defesa → item → ataque → movimento. Interações de história só começam fora de ataques e de hitstun.

Estados principais: livre, preparando ataque, ataque ativo, recuperação, defesa, esquiva, uso de ferramenta, dano, queda, diálogo, transição e morto. Cada estado define explicitamente o que pode cancelá-lo. Animações representam esses estados; a lógica de combate não depende de um som terminar.

## 4. Espada: compromisso curto, impacto claro

Combo da Espada de Oficina:

| Golpe | Preparação | Ativo | Recuperação | Dano | Alcance inicial |
|---|---|---|---|---|---|
| Corte 1 | 0,09 s | 0,08 s | 0,16 s | 1 | 22 px |
| Corte 2 | 0,10 s | 0,08 s | 0,18 s | 1 | 23 px |
| Finalização | 0,16 s | 0,10 s | 0,28 s | 2 | 25 px |

A sequência só avança se o jogador pedir outro golpe; não há combo automático que ande sozinho. Uma pausa de 0,38 s encerra a sequência. Não se pode repetir o terceiro golpe sem fazer os anteriores. Durante a preparação, o jogador ainda pode orientar a lâmina; no período ativo, a direção fica fixada.

O primeiro e segundo golpes podem ser cancelados por esquiva após o fim da janela ativa, se a esquiva estiver pronta. A finalização só permite cancelamento nos últimos 0,10 s da recuperação. Isso permite jogar com segurança usando cortes curtos ou assumir um risco para quebrar postura.

Espada Diapasão: danos 2, 2, 3 e capacidade de interagir com metais ressonantes. Lâmina da Âncora: 3, 3, 4 e contato com alvos de vestígio expostos. Inimigos novos usam defesa, alcance e padrões adequados; não multiplicar automaticamente toda a vida deles só porque a espada mudou.

Cada ataque recebe um identificador único. A mesma janela ativa não causa dano duas vezes ao mesmo alvo, mesmo se entrar e sair da área de contato. A finalização não atravessa escudos e não ignora a invulnerabilidade de chefes.

Sensação de impacto: pausa visual de 0,035 s no contato confirmado, flash curto no alvo, efeito sonoro e recuo compatível. Evitar congelar diálogos, interface e timers de entrada durante a pausa visual; o sistema precisa ter uma única política de relógio. Tremor de câmera ajustável e desligável. Ataque bloqueado tem resposta diferente de acerto.

## 5. Esquiva, defesa e janelas justas

Esquiva: 0,22 s a 230 px/s, distância aproximada de 50,6 px, com invulnerabilidade somente entre 0,03 e 0,15 s. Recarga: 0,65 s contados desde o início. Sem gasto de magia e sem barra extra de vigor. Segurar o botão não repete a esquiva automaticamente.

A recarga e a janela limitada impedem atravessar todos os ataques apertando sem observar. A esquiva não atravessa paredes, portas, buracos, cones contínuos nem corpos de chefes. Buraco sem botas é interrompido antes da borda; uma queda só acontece em um ponto marcado ou por empurrão claramente anunciado.

Defesa: cone frontal de 100 graus, movimento reduzido a 45%. Bloqueia integralmente golpes leves. Golpes pesados provocam quebra de guarda, 0,45 s de recuperação e 1 de dano, quando o golpe original causaria 2 ou 3. Golpes de área e ataques não bloqueáveis têm forma e animação próprias. Nunca diferenciar apenas pela cor.

Defesa precisa com escudo ressonante: janela de 0,11 s a partir do início da defesa. Redireciona um pulso elegível e reduz brevemente a postura do agressor. Segurar a guarda mantém defesa comum; não gera defesas precisas continuamente. Uma nova tentativa exige soltar e pressionar, com intervalo mínimo de 0,25 s entre tentativas.

Nenhum chefe exige defesa precisa como única solução. Nos enigmas de reflexão, há um refletor fixo operável; nas lutas, uma rota de posicionamento ou mecânica ambiental abre o mesmo alvo. A execução precisa é uma vantagem para dominar o encontro, não uma barreira escondida à história.

## 6. Dano, postura e prevenção de injustiças

Dano recebido: 1 comum, 2 médio, até 3 forte. Após um acerto: 0,75 s de invulnerabilidade e 0,18 s de hitstun. Recuo de até 18 px, reduzido junto a paredes. A invulnerabilidade começa junto com a aplicação do dano; dois contatos no mesmo passo de física não se acumulam.

Yggnus não pode ser empurrado por três adversários contra uma parede sem oportunidade de resposta: um diretor de encontro concede, no máximo, uma autorização de ataque corpo a corpo e uma à distância ao mesmo tempo em salas normais. Elites substituem a autorização de corpo a corpo. O diretor não torna ataques síncronos; os avisos precisam continuar legíveis.

Chefes usam orçamento próprio: um ataque principal e, quando já ensinado, um perigo secundário previsível. Projéteis não surgem fora da tela atingindo imediatamente. Se a origem está fora do campo visível, segurar o disparo até a câmera mostrar ou sinalizar a origem pelo menos 0,75 s antes.

Atordoar o mesmo inimigo repetidamente tem resistência temporária: primeiro Pulso interrompe por 0,70 s; o segundo em até 3 s dura 0,25 s; o terceiro não atordoa, mas ainda tem efeito visual. A resistência expira depois de 3 s sem novo Pulso. Chefes só aceitam interrupção em ataques marcados como interrompíveis.

## 7. Gancho e uso de ferramentas

Gancho: alcance 112 px, preparação de 0,10 s, deslocamento da ponta de até 360 px/s e retorno. Só dispara se houver linha de visão. A trajetória detecta paredes ao longo do caminho, não apenas no ponto final. Recarga após retorno: 0,35 s. Enquanto voa, Yggnus pode mover-se a 35% da velocidade. Um lançamento inválido volta rápido e não consome recurso.

Contra um Guarda de Contrapeso exposto, o gancho remove a defesa por 1,2 s. Antes de obter o gancho, é possível provocar a pancada e aproveitar 0,70 s de abertura. Essa alternativa é necessária para vencer os dois guardas que protegem a oficina.

Puxar Yggnus por um vão exige argola de travessia e destino seguro. Argolas de puxar objetos e argolas de travessia têm ícones diferentes. Nunca puxar o personagem através de inimigos sem colisão nem fixar em qualquer decoração parecida.

Luvas: empurrão de um bloco de 16 px por ação, 0,25 s. Blocos deslizam apenas em pistas marcadas; um comando de reinício local repõe o enigma, sem apagar baús. Botas: a travessia de um vão usa o ponto de partida e o destino marcado, com distância máxima de 64 px. A esquiva de combate não é convertida em salto livre.

Arco: preparação 0,18 s, projétil a 260 px/s, recarga 0,30 s; base de dano 2. Agulhas sem alvo podem ser recuperadas em locais seguros; estoque máximo inicial 20. Enigmas obrigatórios têm reposição fixa e não dependem de comprar munição.

## 8. Magias e Ressonância

Leitura de Vestígios, luz de leitura, pontes, Acorde Vivo e Retorno de Memórias são gratuitos. Somente efeitos de combate consomem Ressonância. Interface explica a diferença ao adquirir a habilidade.

Pulso: 10, raio 44 px, conjuração 0,16 s, recarga 1 s. Fio em combate: 15, imobiliza um alvo elegível por 0,9 s, recarga 1,4 s. Lanterna em combate: 8, exposição por 2,5 s, recarga 0,8 s. Véu: 25, prepara em 0,20 s, dura até 8 s ou um impacto; não acumula e não pode ser renovado enquanto ativo.

Custo é debitado no momento em que o efeito aparece. Se o personagem for interrompido antes disso, não há cobrança. Se um efeito já ocorreu, não reembolsar porque o alvo saiu do alcance. Mostrar falha de energia sem bloquear movimentação. Gancho e mecanismos continuam utilizáveis com energia zero.

Não há regeneração passiva durante combate. Marcos restauram vida e energia; algumas criaturas deixam gotas definidas no catálogo. Usar recursos ofensivos deve encurtar encontros ou abrir espaço, sem substituir leitura de padrões.

## 9. Cura, morte e recursos

Frasco Restaurador: +3 de vida, uso de 0,65 s e recuperação de 0,20 s. Yggnus fica a 25% da velocidade durante o uso e pode ser interrompido. O frasco é esvaziado apenas no instante em que a cura é aplicada. Cura a vida cheia não inicia uso nem consome item.

Pão: +1 fora de combate. Essência: +30 de Ressonância, uso de 0,55 s. Abrir inventário pausa o mundo, mas selecionar um consumível apenas prepara sua utilização no retorno; não permite curar dentro da pausa.

Morte sem perda de Bronze. Retornar ao marco com vida e energia máximas. Equipamentos, fragmentos, registros, portas e missões permanentes continuam. Inimigos comuns da sala reiniciam. Chefes reiniciam seus ciclos; recompensa ainda não recebida continua não recebida.

Antes de cada chefe, registrar um snapshot de tentativa com vida, energia e conteúdo dos frascos depois da recuperação do marco. Ao morrer ou reiniciar a tentativa, devolver exatamente esse inventário de tentativa. Compras, loot ou interações externas são bloqueados enquanto a arena estiver ativa; não existe lucro repetindo tentativas. Vitória confirma o consumo da tentativa e a recompensa única numa mesma atualização persistente.

Sair do jogo durante um chefe retorna ao início da tentativa, não ao meio de uma animação ou plataforma. Sair durante uma exploração carrega a última entrada segura da sala, com os estados persistentes já confirmados.

## 10. Inteligência artificial e dificuldade

Estados de inimigo: patrulha → percepção → aproximação → preparação → ataque → recuperação. Há ainda dano, atordoamento, perda de alvo e derrota. A preparação fixa a direção no último trecho, permitindo desviar; não seguir o jogador instantaneamente durante toda a investida.

Aventureiro: avisos de 0,50 a 0,85 s em campo; chefes de 0,70 a 1,20 s na apresentação. Veterano: reduzir até 15% em padrões já ensinados, sem aviso abaixo de 0,45 s, e diminuir recuperação até 10%. Vida e dano permanecem inicialmente iguais. Só aumentar atributos se testes demonstrarem necessidade.

Os primeiros encontros ensinam: Rastejo isolado; Mariposa isolada; Soldado isolado; dupla Soldado e Mariposa; Guarda com uma abertura após pancada. Depois, misturar posicionamento e intervalos. Não usar três inimigos novos ao mesmo tempo.

Alvo de duração: comum, 3–8 s; médio, 8–18 s; elite, 30–60 s; chefe, 2–4 min quando aprendido. Não manter um chefe invulnerável por longos períodos sem uma tarefa do jogador. Se a janela de dano for perdida, a próxima chance vem por um padrão conhecido, não por uma nova fala longa.

## 11. Chefes, soluções e condições de conclusão

Igris: dois ciclos. Em cada um: três ondas anunciadas → abafador alcançável com gancho por 2,0 s → sinos em sequência visual → regulador aberto por 2,4 s. Exigir dois golpes confirmados no regulador por ciclo, independentemente da espada. O segundo ciclo mistura uma onda lenta e uma rápida, ambas ensinadas. Dois ciclos corretos rompem o controle; a Matrix estabiliza Igris. Não matar o personagem nem permitir que dano comum pule a conversa de escolha.

Custódia: três ciclos. Travar trilho com bloco, evitar jato, usar refletor fixo ou escudo preciso, golpear regulador duas vezes. A arena mantém um caminho seguro para chegar ao bloco em todos os estados de água.

Devorador: expor duas placas, golpear seus acúmulos e resolver o Acorde Vivo fora da janela de dano. Interromper agressão durante a seleção de notas; o desafio é reconhecer a repetição, não ler menus sob ataque. Um último ciclo de exposição permite passar, sem golpe de execução.

Aracne: três plataformas sucessivas. Prender duas pernas nos pontos da arena, atravessar com botas e cortar os fios do dorso. Há um mecanismo gratuito para fixar as pernas no contexto do enigma, equivalente ao Fio de Âncora; energia zero nunca bloqueia a campanha.

Curador: três placas de escuta, apresentadas uma a uma. Disparar quando expostas, aproximar-se do núcleo e recuar antes da varredura. Reposição de agulhas em dois recipientes fixos na arena; fontes não se esgotam durante uma tentativa.

Yame Black: duas amarras de combate; depois, desativar ataques e relacionar retratos/registros. Todas as pistas obrigatórias estão na sala. A criatura libertada permanece viva e escolhe ficar com Igris.

Câmara de Melissa: três reguladores, com perigos crescentes. Espada e ferramentas atingem estruturas e projeções. O confronto termina quando os controles ficam estáveis; então começam a hesitação e a decisão de Melissa. Nenhuma escolha rápida, nota musical ou colecionável decide seu destino.

## 12. Enigmas, diálogos e assistência

Enigma precisa apresentar linguagem, permitir tentativa segura e só então combinar risco. Após 45 s sem avanço em uma sala de enigma, pode aparecer um ícone discreto de dica; não abrir fala automaticamente. Se solicitado, a primeira dica aponta um detalhe; a segunda explica a relação; a solução direta só aparece por nova solicitação. Dicas não reduzem recompensas.

Falas modais pausam combate e só iniciam em estado seguro. Falas curtas de combate não tomam o controle e aparecem longe das áreas de perigo. Máximo de duas linhas visíveis; duração por palavra e opção de histórico. Mensagens não disputam o mesmo espaço com avisos de ataque.

Na primeira execução, Interagir mostra imediatamente o restante da frase e um segundo toque avança. Segurar Pular por 0,8 s encerra a cena aplicando todos os efeitos finais uma única vez. Cenas já vistas podem oferecer um resumo na repetição. O jogador nunca perde equipamento por pular uma conversa.

O arquivo de diálogos inclui falas de história, aquisição, ajuda, missões opcionais, falas de combate e epílogo. Perguntas de explicação não mudam as decisões já fixadas pelo autor. Não apresentar falsamente uma escolha de matar Igris, divulgar Lívia ou executar Melissa.

## 13. Medir se ficou divertido e difícil

Primeira rodada: cinco pessoas que não conhecem o projeto, 30–45 min, sem explicação do desenvolvedor. Registrar tempo para aprender espada/defesa/gancho, erros de leitura, mortes por sala, duração de Igris e comentários após a sessão. Perguntar o que o jogador queria fazer quando o comando falhou.

Metas de triagem, não resultados obtidos: quatro de cinco entendem o gancho sem instrução verbal externa; a maioria alcança Igris em até 35 min; Igris exige aproximadamente 2–5 tentativas para o perfil de jogador de aventura; nenhuma morte é atribuída a uma origem invisível ou colisão incoerente. Uma pessoa muito experiente vencendo de primeira não prova que a luta é fácil.

Se estiver fácil, combinar padrões já ensinados e reduzir recuperação de inimigo até 10% antes de aumentar dano. Se estiver frustrante, revisar clareza e latência antes de reduzir agressividade. Jogadores devem conseguir explicar como poderiam ter evitado a maior parte dos danos.

Não afirmar que a mecânica já é fluida ou divertida antes desses testes. O pacote deixa o teste executável e os parâmetros ajustáveis.

## 14. Referências técnicas consultadas

Godot — CharacterBody2D, movimento pelo passo de física e modo flutuante para visão superior:
https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html

Godot — interpolação de física e reposicionamento:
https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html

Godot — identificação e serialização de objetos persistentes:
https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

As escolhas de combate e números acima são propostas originais do projeto; as fontes orientam implementação no motor, não comprovam balanceamento.
