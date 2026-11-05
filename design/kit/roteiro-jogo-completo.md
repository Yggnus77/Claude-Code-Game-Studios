# A LENDA DE YGGNUS
## Roteiro e proposta de jogo — versão 1.0

Documento de criação. História definida em conjunto; aparência, equipamentos, inimigos, números de combate e áreas intermediárias são propostas novas. Este material descreve um jogo a desenvolver, não um jogo já implementado.

## 1. A experiência de jogar

Aventura de ação em visão superior, para um jogador, com exploração de um arquipélago, vilas, passagens secretas, masmorras, enigmas e combate em tempo real. A referência é o ritmo das aventuras clássicas de 16 bits: observar um obstáculo, descobrir uma ferramenta e perceber que ela também abre caminhos em regiões antigas. Os cenários, personagens, mapas, músicas, arte e enigmas serão próprios.

Título de trabalho: A Lenda de Yggnus. Campanha proposta: 10 a 14 horas, mais 3 a 5 horas de exploração opcional. O primeiro protótipo deverá conter apenas Versalhes e a Torre Akurame; esses tempos não são estimativa de produção.

Você controla Yggnus. Ádally acompanha a narrativa e participa de momentos específicos, sem exigir gerenciamento de dois personagens durante as lutas. Em exploração, ela desenha pistas descobertas e pode indicar detalhes se você solicitar. Nunca resolve automaticamente um enigma ainda não examinado.

O ciclo é: explorar uma região → conversar e investigar → abrir uma masmorra → encontrar equipamento → aprender seu uso → superar o chefe → recuperar uma memória → retornar ao mundo com novos caminhos disponíveis.

### Controles propostos

| Ação | Controle no controle moderno |
|---|---|
| Movimentar | Direcional ou analógico esquerdo |
| Golpear com espada | X |
| Interagir, conversar, empurrar | A |
| Esquivar com passo curto | B |
| Usar ferramenta ou magia equipada | Y |
| Defender | LB, enquanto estiver pressionado |
| Trocar item rápido | RB |
| Abrir mapa | View/Select |
| Inventário e pausa | Menu/Start |

As teclas são remapeáveis. No teclado: WASD, J para espada, K para interação, Espaço para esquiva, L para item, Shift para defesa, Tab para mapa e Esc para pausa. Atalhos são uma proposta a validar com testes de conforto.

### Regras fundamentais

Yggnus começa com 6 pontos de vida. Ataques comuns retiram 1, ataques fortes 2 e golpes de chefe até 3, sempre com aviso visual e sonoro. Após sofrer dano, há um breve período de invulnerabilidade. Quatro Fragmentos de Âncora aumentam a vida máxima em 1; não recuperam pessoas nem funcionam como vidas extras.

A energia mágica, chamada Ressonância, começa em 60 pontos. Ela se recupera em santuários e com gotas deixadas por inimigos. Habilidades de enigma não gastam energia: nenhuma porta obrigatória depende de encontrar um consumível aleatório. A Matrix sempre pode examinar o ambiente gratuitamente.

A morte retorna ao último Marco de Memória, com os equipamentos e descobertas importantes preservados. Chefes reiniciam; atalhos já abertos permanecem. Há salvamento automático ao mudar de região e salvamento manual nos marcos.

Não há experiência obrigatória nem necessidade de repetir batalhas para subir de nível. A progressão vem de equipamentos, aprendizado e melhorias opcionais. Bronze é a moeda de serviços e consumíveis.

## 2. O mundo e o que aconteceu

Rouge é um arquipélago de portos, oficinas, observatórios e ruínas mecânicas. Durante uma guerra, técnicas de armazenamento de memória foram usadas para orientar armas e localizar cidades. Lívia, irmã de Melissa, morreu nesse conflito.

Exódia pesquisava uma maneira de preservar e aliviar lembranças traumáticas. Melissa se aproximou desse trabalho para conservar a voz da irmã. O projeto se tornou o Reset Sistem: uma rede capaz de retirar memórias e alterar a ligação entre um lugar e seus habitantes.

Melissa passou a acreditar que eliminar as lembranças que alimentavam conflitos impediria outra guerra. Também tentou reconstruir Lívia com os registros preservados. Para sustentar as reconstruções, o sistema retirava cada vez mais lembranças das pessoas vivas. Aurélis foi o primeiro teste de apagamento de uma cidade inteira.

Exódia ajudou a construir a rede, percebeu tarde demais suas consequências e escondeu a Matrix: uma peça capaz de conservar memórias fora do controle central. Ela a colocou dentro de um relógio, que acabaria chegando à oficina de seu aprendiz, Yggnus.

Neste mundo, memória pode sustentar a presença de objetos e lugares. O jogo estabelece uma distinção: pessoas mortas não ressuscitam; memórias não são cópias completas de uma pessoa. Os habitantes de Aurélis sobreviveram deslocados e desorientados, enquanto a cidade foi afastada do mundo acessível. Reconstruções do sistema podem imitar vozes, mas não equivalem a devolver uma vida.

## 3. Personagens e funções jogáveis

| Nome | Papel e arco | Presença no jogo |
|---|---|---|
| Yggnus | Restaurador de Versalhes. Aprende a ouvir antes de decidir pelos outros. | Personagem controlável; espada, defesa, ferramentas e Matrix. |
| Ádally | Cartógrafa de Aurélis. Quer recuperar sua cidade sem sacrificar outras pessoas. | Mapa, investigação e auxílio em mecanismos predeterminados. |
| Melissa | Antiga guardiã e responsável pelos apagamentos. Confunde preservação com controle. | Antagonista; confronto final sem execução obrigatória. |
| Exódia | Mentora e engenheira do projeto. Precisa revelar sua responsabilidade. | Oficina, melhorias e explicação do funcionamento da rede. |
| Igris | Operador integrado aos sinos da Torre Akurame. Recupera o direito de escolher. | Primeiro chefe; depois aliado voluntário na passagem final. |
| Morina | Sobrevivente de Aurélis e antiga colega de Ádally. Desenha a cidade sem lembrar dela. | Caderno de pistas, encontro emocional e reconstrução. |
| Lívia | Irmã falecida de Melissa. Sua voz foi preservada e editada. | Memórias e gravações; nunca retorna como pessoa viva. |
| Yame Black | Criatura de páginas e retratos contendo memórias de pessoas apagadas. | Adversário recorrente; depois criatura livre que ajuda Igris. |
| Devorador de Ecos | Guardião da Caverna dos Terrores. Imita vozes e consome sons. | Chefe enfrentado por observação, som e combate. |

O visual individual de cada um acompanha este documento na pasta personagens. São artes conceituais, não sprites animados prontos para implementação.

## 4. Inventário: luta, magia e exploração

### Armas e equipamentos

| Equipamento | Aquisição | Uso e limite |
|---|---|---|
| Espada de Oficina | Início, em Versalhes | Lâmina curta de trabalho; combo de três golpes. Não lança projéteis. |
| Espada Diapasão | Após Akurame, na oficina | Faz vibrar alvos metálicos expostos. Exige proximidade; não atravessa escudos. |
| Lâmina da Âncora | Após a caverna, com Exódia | Usa um fragmento preservado pela Matrix para atingir matéria e ecos. Não exige fragmentos opcionais. |
| Escudo de Bronze | Tutorial | Bloqueia ataques frontais leves; não bloqueia ataques de área ou golpes pesados. |
| Escudo Ressonante | Depósito das Comportas | Redireciona pulsos sonoros quando defendidos no instante indicado. Defesa comum ainda reduz o dano. |
| Gancho de Retorno | Torre Akurame | Puxa argolas, conecta pontes e desmonta armaduras marcadas. Alcance curto e pontos de fixação visíveis. |
| Luvas de Lastro | Depósito das Comportas | Movem pesos e travam placas; não permitem carregar qualquer objeto do cenário. |
| Botas de Travessia | Ilha das Agulhas | Impulso curto entre bordas marcadas. Não permite atravessar buracos fora do alcance. |
| Arco de Fio | Pátio das Vigias | Dispara agulhas recuperáveis; munição reposta em recipientes fixos antes de desafios obrigatórios. |
| Cargas de Bronze | Comerciante, depois da torre | Abrem rachaduras e causam dano de área. Não são necessárias para derrotar o chefe final. |

### Matrix e magias

| Poder | Uso | Custo |
|---|---|---|
| Leitura de Vestígios | Revela pistas e compara o lugar atual com uma lembrança. | Gratuito. |
| Pulso de Eco | Atordoa inimigos leves e interrompe conjurações. | 10 de Ressonância. |
| Fio de Âncora | Mantém uma plataforma de memória visível enquanto você cruza. | Gratuito nos pontos de enigma; 15 para imobilizar inimigo. |
| Lanterna de Lembranças | Ilumina tinta apagada e distingue ecos de objetos presentes. | Gratuito para exploração; 8 para expor criatura oculta. |
| Acorde Vivo | Sequência de três notas criada por Yggnus e Ádally; desfaz imitações fixas. | Gratuito. Sem teste obrigatório de ritmo. |
| Véu de Proteção | Absorve um golpe e desaparece. | 25; não acumula escudos. |
| Retorno de Memórias | Distribui registros preservados no clímax. | Poder narrativo, não ataque nem ressurreição. |

As magias têm sinais visuais e sonoros. Enigmas musicais possuem alternativa visual, legendas e opção de repetir as notas. Combates não exigem distinguir cores sem outros sinais.

### Consumíveis e melhorias

Frasco Restaurador recupera 3 de vida; Essência de Ressonância recupera 30 de energia; Pão de Porto recupera 1 de vida fora de combate. Dois frascos podem ser encontrados, e a capacidade aumenta em missões opcionais. A loja sempre oferece uma opção acessível antes de cada grande área.

Pó de Revelação expõe trilhas opcionais, mas a campanha nunca depende dele. Medalhões encontrados em explorações reduzem o custo de uma magia ou melhoram a defesa; não são necessários para compreender a história.

## 5. Campanha, como será jogada

### Prólogo — A décima terceira badalada

Você começa na oficina de Versalhes. Sem exposição longa, aprende a andar, examinar uma bancada, empurrar uma caixa e entregar um mecanismo a um vizinho. Pequenos diálogos estabelecem que Exódia ensinou Yggnus e que as ilhas dependem de equipamentos antigos.

Um relógio chega embrulhado em tecido. Yggnus o ajusta. Ele toca treze vezes. Na rua, uma mulher esquece o nome do companheiro; uma placa perde suas letras. A câmera permanece no jogo, permitindo que você examine as alterações.

Ádally entra com um mapa: o desenho de uma cidade começa a desaparecer. Ela reconhece no relógio o símbolo que encontrou nas ruínas de Aurélis. Exódia abre o fundo da peça e revela a Matrix, mas evita explicar sua origem.

Yame Black invade a oficina. Você recolhe a espada e o escudo, defende projéteis de papel e corta os fios que bloqueiam a saída. Não é possível matar a criatura: após três pontos de amarração rompidos, ela foge pelas telhas. Objetivo concluído: manter a Matrix e evacuar os moradores.

Exódia indica a Torre Akurame. Ela acredita que o registro original do sistema esteja no alto, acessível pelos antigos canais de comunicação.

### Capítulo 1 — Estrada das Oficinas

Área aberta curta entre Versalhes e a torre. Você aprende a abrir atalhos, localizar marcos e examinar paredes rachadas. Inimigos fáceis aparecem individualmente; o primeiro combate com dois adversários acontece apenas após existir espaço para esquivar.

Ádally desenha o caminho percorrido. Uma ponte interrompida mostra argolas de metal fora de alcance: é a primeira promessa de retorno com uma ferramenta nova. Uma tarefa opcional, recuperar peças de uma bomba d'água, recompensa o primeiro frasco.

### Capítulo 2 — Torre Akurame

Masmorra vertical composta por quatro conjuntos de salas: base, contrapesos, galeria dos sinos e câmara de operação. Cada piso tem um atalho visível de volta à escada central. As frases transmitidas pelos sinos parecem desconexas, mas repetem o nome Reset Sistem.

Você encontra o Gancho de Retorno em uma oficina lateral após vencer dois Guardas de Contrapeso. Aprende a puxar uma argola em segurança, depois usa a mesma ação sobre um inimigo protegido. Para subir, precisa suspender um peso enquanto Ádally fixa uma trava; o jogo não exige trocar de personagem.

O chefe é Igris. Primeiro, evite três ondas indicadas por círculos no chão e use o gancho para soltar os abafadores de seu peito. Depois, ative os sinos na sequência apresentada nas paredes; isso interrompe os comandos de Melissa e expõe o regulador, que pode ser atingido com a espada. Após dois ciclos, a Matrix permite estabilizar o operador.

A luta encerra quando o controle externo é interrompido. Yggnus não decide o destino de Igris. Ele escolhe deixar a torre e entrega um registro: Aurélis foi o primeiro apagamento de uma cidade inteira, autorizado por Melissa.

Ao voltar, Exódia melhora a espada para Espada Diapasão. Essa melhoria é gratuita e faz parte da campanha.

### Capítulo 3 — A sobrevivente

Nas rotas de barqueiros, a dupla encontra Morina. Ádally a reconhece, mas Morina não se lembra dela. Uma conversa interativa permite escolher perguntas; todas conduzem ao mesmo fato, sem punir quem escolhe palavras diferentes.

Morina completa uma canção de infância que Ádally começa a cantar. Não recupera todas as lembranças, mas aceita mostrar seu caderno. Ela desenha Aurélis durante o sono, incluindo uma passagem que Ádally nunca visitou: a Caverna dos Terrores.

Para alcançá-la, é preciso baixar o nível de um canal. Isso leva ao Depósito das Comportas.

### Capítulo 4 — Depósito das Comportas

Uma masmorra de água e engenharia com três níveis de inundação. As mudanças são locais: nenhum objeto essencial pode ser perdido. Placas mostram para onde cada canal conduz.

Você obtém as Luvas de Lastro e o Escudo Ressonante. Os enigmas combinam posicionamento de pesos e redirecionamento de pulsos. A sala anterior ao chefe oferece recuperação, um marco e treino gratuito da defesa sonora.

O novo chefe proposto é a Custódia Ferrugem, máquina de manutenção que aprisiona viajantes para mantê-los longe da rede. Use as luvas para bloquear um trilho, evite o jato sinalizado, redirecione o pulso e ataque o regulador exposto. Três ciclos encerram o combate.

Ao restaurar a máquina, você abre o canal da caverna. A recompensa é o Fio de Âncora. Yame Black aparece brevemente, tenta alcançar a Matrix e recua ao ouvir os sinos de Igris ao longe.

### Capítulo 5 — Caverna dos Terrores

A entrada é silenciosa. Pouco depois, você ouve a voz de Morina pedindo ajuda em uma passagem lateral. Ádally percebe que as palavras repetem exatamente o que ouviram no porto. A Matrix destaca um vestígio: o chamado é uma imitação.

A primeira metade da caverna apresenta o Fio de Âncora, que sustenta pontes de memória, e a Lanterna de Lembranças, encontrada em uma estação de observação abandonada. Trilhas verdadeiras e falsas diferem por movimento, formato e som, não apenas pela cor.

O Devorador de Ecos é o chefe. Você não o vence imitando vozes antigas. Primeiro desvia das investidas, ilumina placas ressonantes e destrói dois acúmulos externos com a espada. Depois a criatura tenta atrair Ádally com a canção de infância, mas só repete trechos fixos.

Yggnus e Ádally criam juntos o Acorde Vivo. O jogador escolhe três símbolos musicais novos e reproduz a sequência por botões, sem exigência de velocidade. O guardião perde a capacidade de controlar a câmara. Mais um ciclo de luz e ataque permite imobilizá-lo e atravessar. Uma opção de acessibilidade executa a sequência após a solução ser identificada.

No depósito de memórias, a Matrix recupera a gravação de Lívia. Melissa havia cortado uma discussão, preservando apenas palavras de carinho. No trecho restaurado, Lívia pede que abandone o projeto e questiona o direito de controlar as lembranças alheias.

Ádally se recusa a usar a gravação como arma. O jogador pode examiná-la no arquivo, mas não existe uma opção de divulgá-la que contradiga essa decisão. A fita permanece protegida.

### Capítulo 6 — A confissão de Exódia

A dupla retorna a Versalhes. Exódia revela sua participação na criação do Reset Sistem. Explica que uma interrupção abrupta impediria novos apagamentos, mas poderia destruir as memórias armazenadas, incluindo os últimos registros de Aurélis e Lívia.

Ádally propõe usar a Matrix para devolver as lembranças antes de desligar a rede. Exódia não garante o sucesso: o núcleo possui canais separados para armazenar, distribuir e apagar. Será necessário alcançar seus controles e impedir que Melissa bloqueie a devolução.

A oficina recebe duas melhorias de campanha: Lâmina da Âncora e Véu de Proteção. Ambas usam peças já obtidas, sem exigir busca opcional. Igris confirma que a antiga rota submarina existe, mas seus terminais precisam ser reativados.

### Capítulo 7 — As duas rotas de acesso

Agora há duas regiões que podem ser visitadas em qualquer ordem. Cada uma devolve um terminal ao mapa, e ambas são necessárias para abrir a rota submarina. Não são novos selos místicos: são partes distintas da infraestrutura do Núcleo Zero.

Na Ilha das Agulhas, pontes suspensas e ventos ensinam o uso das Botas de Travessia. O chefe proposto é Aracne de Cobre, máquina de seis patas que rompe plataformas. Você fixa duas pernas com o Fio de Âncora, usa as botas para chegar ao dorso e corta fios de controle. Ela recua para uma nova seção após cada ciclo. A recompensa é o primeiro terminal ativo.

No Pátio das Vigias, você encontra o Arco de Fio. Enigmas exigem acertar placas através de janelas móveis e criar linhas temporárias. O chefe proposto é o Curador Cego, uma máquina que seleciona memórias pelo som. Você observa os padrões, dispara nas placas que ele expõe ao procurar a origem do ruído e aproxima-se para atingir o núcleo. A recompensa é o segundo terminal.

Concluídas as duas rotas, Igris escolhe ajudar. Não é convocado por obrigação ou controlado pela Matrix. Morina entrega um desenho do acesso submarino, recuperado de seus sonhos.

### Capítulo 8 — Libertar Yame Black

Na entrada do Núcleo Zero, Yame Black bloqueia a passagem. A luta combina projéteis de papel, marcas no chão e corredores que se fecham. Use a Lanterna para revelar os fios que prendem a criatura e o gancho para soltá-los. A espada protege Yggnus de fragmentos, mas não reduz uma barra de vida da criatura.

Com dois vínculos removidos, o combate muda para um enigma. A Matrix revela pessoas aprisionadas entre suas vozes. Ádally reconhece nomes em retratos e registros que o jogador examinou ao longo do caminho; os essenciais estão na própria sala, sem depender de colecionáveis.

Yggnus tenta libertá-lo e percebe que arrancar as memórias à força as destruiria. Ádally chama cada nome enquanto a Matrix oferece um destino seguro. Quando o último registro é recolhido, resta uma pequena criatura silenciosa.

Yggnus estende a mão. Yame Black decide se aproximar. Depois fica com Igris para manter a saída aberta, atravessando dutos que o antigo operador não alcança. A nova função é mostrada por uma breve sequência jogável de Yggnus preparando o mecanismo, seguida de uma cena curta dos aliados assumindo seus postos.

### Capítulo 9 — Núcleo Zero

Masmorra final em três setores: arquivo de origem, distribuidor de lembranças e câmara central. Cada setor reutiliza ferramentas conhecidas em combinações novas; nenhum equipamento obrigatório surge apenas no último minuto.

A Matrix alterna entre presente e vestígio em pontos delimitados. Uma ponte pode existir no vestígio enquanto uma comporta só pode ser operada no presente. Yggnus preserva a posição em áreas seguras; o jogo impede alternar dentro de paredes ou cair por falta de aviso.

Ádally cruza seus mapas para separar registros de cidades diferentes. Em termos de jogo, você gira distribuidores e confirma conexões por símbolos, nomes e trajetos. Não há uma contagem real escondida que mate aliados durante a exploração. A urgência vem de cenas e etapas visíveis.

Igris e Yame Black mantêm a saída. Seus pedidos pelo comunicador explicam o perigo, mas não exigem escolta nem fazem o jogador repetir a masmorra.

### Capítulo 10 — Melissa e a devolução

Melissa espera diante de uma reconstrução incompleta de Lívia, que repete palavras de carinho. Oferece devolver Aurélis se a dupla entregar a Matrix. Ádally recusa: não aceitará recuperar sua cidade ao custo de abandonar outras pessoas.

O confronto final tem três partes. Na primeira, Melissa ativa estruturas da câmara; Yggnus corta os vínculos de controle e usa o escudo para redirecionar pulsos. Na segunda, plataformas desaparecem em sequências anunciadas; botas, gancho e Fio de Âncora permitem avançar enquanto Ádally localiza os canais. Na terceira, você estabiliza três reguladores com a Matrix. A defesa de Melissa cai, mas não surge um comando de execução.

Há espaço para luta, esquiva e domínio das ferramentas, porém a vitória significa alcançar o controle central. A espada atinge estruturas e projeções; o objetivo não é matar Melissa.

Para devolver as memórias, ela precisa liberar a autorização que reservou para si. Melissa começa, mas hesita quando a voz reconstruída de Lívia se desfaz. Ádally preserva a gravação íntima e fala de Morina, que sobrevivera sem reconhecer a amiga.

Melissa pergunta se tudo voltará ao que era. Yggnus admite que não sabe. A Matrix guarda lembranças; não desfaz todas as perdas.

Melissa libera as memórias e permanece no núcleo, operando manualmente os canais de devolução. Yggnus leva a Matrix até a saída, agora carregada dos registros a distribuir. Na fuga, o jogador atravessa um trajeto curto com os atalhos preparados por Igris e Yame Black. Não há novo chefe. Falhar em um salto retorna ao início do trecho, sem repetir a decisão final.

Antes de sair, Ádally ouve Melissa: “Se Aurélis voltar, me conte como ela é.” O sinal se perde. O destino de Melissa permanece incerto; não há cena secreta que confirme sua morte ou sobrevivência nesta versão.

### Epílogo — Aurélis e a oficina

Aurélis reaparece danificada. O observatório está partido e ruas terminam em escombros. Os sobreviventes retornam; não são recriados como cópias. Morina reconhece Ádally na praça. As duas começam um mapa que registra tanto o que voltou quanto o que será reconstruído.

Exódia revela publicamente sua participação no projeto. A história não a absolve com uma única fala: ela oferece os próprios registros e trabalha na recuperação sob supervisão dos moradores. Igris e Yame Black ajudam a restabelecer os sinais entre as ilhas.

Semanas depois, Yggnus volta à oficina de Versalhes. O relógio está sobre a bancada, com a cavidade da Matrix vazia. Ele ajusta uma mola e fecha a tampa. Ao lado da janela, coloca uma carta de Ádally: Morina ajuda a redesenhar as ruas; o observatório recebeu um telhado provisório. No verso há duas cadeiras diante de uma oficina ainda sem portas.

Ao meio-dia, o relógio bate doze vezes. Yggnus espera. Nenhuma décima terceira badalada vem. Uma carroça passa; alguém chama um vizinho pelo nome. O relógio continua seu movimento. Yggnus abre a oficina.

Créditos sobre pequenas cenas de reconstrução, sem revelar Melissa. Após os créditos, o arquivo oferece retorno ao ponto anterior à entrada final. O epílogo não é desfeito dentro da narrativa.

## 6. Bestiário e dificuldade

Todos os nomes abaixo, exceto Yame Black e Devorador de Ecos, são propostas novas. Variantes difíceis mudam comportamento, não apenas vida. Cores sempre acompanham padrões de forma e animação.

### Inimigos fáceis — aprender com segurança

| Inimigo | Onde | Comportamento e resposta |
|---|---|---|
| Rastejo de Tinta | Estrada, cavernas | Avança em linha após inflar; 2 golpes de espada. Esquivar para o lado. |
| Mariposa de Papel | Telhados, torre | Pousa antes de mergulhar; 1 golpe, defesa possível. |
| Caranguejo de Sucata | Canais | Frente protegida; 2 golpes pelas costas ou após sua investida. |
| Lamparina Errante | Ruínas | Acende por um instante antes de disparar; 2 golpes, projétil bloqueável. |
| Soldado de Corda | Torre | Um golpe lento e previsível; 3 golpes, defesa abre espaço. |
| Pingo de Eco | Arquivos | Salta sobre uma marca visível; 1 golpe ou pulso. Não drena itens. |

### Inimigos médios — combinar ações

| Inimigo | Onde | Comportamento e resposta |
|---|---|---|
| Guarda de Contrapeso | Akurame | Escudo frontal; gancho abre defesa por tempo suficiente para 2 ataques. |
| Tecelão de Fios | Caverna | Prende uma faixa do chão; corte a amarração antes de se aproximar. |
| Cão de Ressonância | Rotas | Fareja passos e investe; interrompa com pulso ou espere sua recuperação. |
| Sentinela de Vidro | Ilha das Agulhas | Projeta um feixe antes de disparar; use cobertura e atinja a placa traseira. |
| Copista Vazio | Arquivos | Repete o último ataque feito contra ele; alterne ferramenta e espada. |
| Cavaleiro de Lodo | Comportas | Ataque pesado em arco; recue, espere a arma ficar presa e golpeie. |

### Inimigos difíceis e minichefes

| Inimigo | Desafio | Solução |
|---|---|---|
| Capitão das Correntes | Controla duas argolas e fecha espaço. | Puxe uma argola durante a preparação, criando abertura. |
| Arquivista Partido | Três corpos compartilham um registro. | Leitura da Matrix identifica o corpo ligado ao piso; ataque após interromper o vínculo. |
| Carrasco de Bronze | Golpe pesado e pulso de chão. | Esquiva lateral e salto curto pelas botas apenas nos pontos marcados. |
| Dupla de Vigias | Um protege o outro. | Use cobertura e desative placas em alternância; nenhum ataque inevitável. |

Os inimigos fáceis causam geralmente 1 de dano; médios, 1 ou 2; minichefes, até 3. Sua vida deve permitir entender o padrão em poucos ciclos. Esses valores são ponto de partida para testes, não balanceamento final.

## 7. Quadro dos chefes

| Encontro | Papel | Ferramenta principal | Condição de vitória |
|---|---|---|---|
| Yame Black na oficina | Tutorial e ameaça recorrente | Espada e defesa | Abrir a saída e proteger a Matrix; ele foge. |
| Igris | Chefe da Torre Akurame | Gancho e sinos | Romper controle externo e estabilizar o operador. |
| Custódia Ferrugem | Chefe das Comportas | Luvas e escudo | Restaurar o regulador e abrir o canal. |
| Devorador de Ecos | Chefe da caverna | Lanterna, espada e Acorde Vivo | Interromper imitações e liberar a passagem. |
| Aracne de Cobre | Chefe da Ilha das Agulhas | Fio e botas | Cortar vínculos da máquina e ativar terminal. |
| Curador Cego | Chefe do Pátio das Vigias | Arco e observação | Expor e desativar o seletor central. |
| Yame Black na entrada | Combate que se torna resgate | Lanterna, gancho e Matrix | Libertar memórias sem destruir a criatura. |
| Melissa / Câmara de Controle | Confronto final | Conjunto das ferramentas | Estabilizar canais e alcançar a decisão de Melissa. |

Chefes têm avisos de ataque de aproximadamente 0,7 a 1,2 segundo nas primeiras aparições. Dificuldades maiores podem reduzir recuperação, mas não retirar pistas. Nenhum chefe exige consumível comprado. Restaurar um personagem não significa automaticamente curar seu trauma ou apagar sua responsabilidade.

## 8. Exploração opcional e retorno

Versalhes funciona como ponto de partida e retorno, com oficina, mercado, cais e moradores afetados pelo apagamento. As falas mudam após torre, caverna e confissão. Novas ferramentas abrem atalhos e pequenas histórias; o mapa marca obstáculos vistos sem revelar o conteúdo de áreas não visitadas.

Missões propostas: recuperar o nome de uma embarcação; recompor um álbum com espaços deliberadamente deixados vazios; restaurar a bomba d'água; reunir desenhos de Morina; devolver um instrumento a Igris. As recompensas são frascos, bronze, Fragmentos de Âncora e melhorias opcionais.

Colecionáveis de memória nunca contêm o único exemplar de uma informação indispensável ao final. Os registros de Lívia não são itens vendáveis. A gravação privada não serve como arma, moeda, chantagem ou requisito de vitória.

## 9. Interface, arte e som

HUD com vida, Ressonância, item equipado e bronze. Objetivo atual é curto e pode ser ocultado. O inventário separa equipamentos, magias, consumíveis e registros. O mapa é o caderno de Ádally; desenhos aparecem após descobertas e não antecipam salas desconhecidas.

Arte proposta: pixel art detalhada em visão superior, com personagens de silhueta clara, arquitetura costeira e máquinas de bronze. As ilustrações anexas são referências de personagem para futura adaptação a sprites. Não são modelos 3D nem folhas com animações.

Versalhes usa sons de ferramentas e instrumentos acústicos; Akurame usa sinos; a caverna alterna silêncio e vozes; o núcleo mistura pulsos mecânicos com fragmentos de melodias. A trilha será original. A canção de Ádally e Morina será composta para este jogo; sua presença na gravação das irmãs sugere uma canção popular compartilhada em Rouge, não um parentesco secreto.

Legendas identificam a origem das vozes. Incluem controles de volume separados, redução de flashes, remapeamento, tamanho de texto e assistência em sequência musical. Não há pressão por reflexos durante a cena íntima de Melissa.

## 10. Primeiro protótipo e critérios de aprovação

Primeira fatia jogável: oficina → invasão → estrada curta → Torre Akurame → luta e escolha de Igris → retorno. Duração alvo: 30 a 45 minutos para alguém que nunca jogou.

Implementar inicialmente: movimento, colisão, espada, defesa, dano, gancho, quatro inimigos, uma porta por mecanismo, um atalho, Igris, diálogo e salvamento. Usar arte provisória durante validação de controles; as artes conceituais não substituem sprites de produção.

O protótipo deve comprovar que o jogador entende quando defender e esquivar, reconhece os pontos do gancho, resolve os sinos sem tentativa aleatória e percebe que a vitória sobre Igris termina em escolha, não em morte. Se isso não funcionar, revisar antes de construir o resto do arquipélago.

## 11. Decisões preservadas da criação conjunta

Nomes: Yggnus, Ádally, Melissa, Exódia, Igris, Morina, Lívia e Yame Black. Lugares: Rouge, Versalhes, Aurélis, Torre Akurame, Caverna dos Terrores e Núcleo Zero. Fenômeno: Reset Sistem. Peça: Matrix. Guardião: Devorador de Ecos.

Decisões: Igris escolhe seu destino; Melissa perdeu Lívia e alterou sua gravação; Ádally se recusa a usá-la como arma; Exódia confessa a alternativa perigosa; Yggnus tenta libertar Yame Black, que fica com Igris; Ádally recusa o acordo; Melissa hesita, libera as memórias e permanece no núcleo; Aurélis retorna danificada; a última cena mostra o relógio funcionando corretamente.

As novas regiões, chefes intermediários, equipamentos, habilidades, visual e valores numéricos são sugestões para revisão. O roteiro mantém uma campanha principal definida; não promete ramificações que não foram projetadas.
