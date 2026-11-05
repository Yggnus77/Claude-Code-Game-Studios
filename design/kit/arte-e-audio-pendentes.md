# A LENDA DE YGGNUS — PRODUÇÃO DE ARTE, ANIMAÇÃO E ÁUDIO

## O que já existe

Nove ilustrações individuais e 17 pranchas conceituais. Elas orientam identidade, materiais, cores e atmosfera. As plantas SVG novas são diagramas em grade e servem para montar colisões. Nenhum desses arquivos é uma animação pronta ou áudio gravado.

## Escala inicial

Cenário em células de 16 × 16 px. Yggnus em quadros de 32 × 48 px, pivô [16,44], colisão dos pés 12 × 10 px. Todas as roupas compartilham pivô e tamanho. Inimigos e chefes podem ter quadros maiores; dimensões precisam ser múltiplas de 16 quando facilitar organização. Não deformar a arte para caber na colisão.

## Animações mínimas de Yggnus

| Estado | Quadros sugeridos por direção | Observação |
|---|---|---|
| Parado | 4 | Pode ser estático no primeiro protótipo. |
| Andar | 6 | Movimento não depende de completar o ciclo. |
| Corte 1 | 5 | Janela de dano segue o estado do combate. |
| Corte 2 | 5 | Direção fixa durante contato. |
| Finalização | 7 | Recuperação visível. |
| Defesa | 2 | Diferenciar levantar e sustentar. |
| Esquiva | 4 | Efeito curto; reduzir flashes opcional. |
| Dano | 2 | Não usar o sprite inteiro como hitbox. |
| Queda | 5 | Retorno ao ponto seguro. |
| Usar ferramenta | 6 | Gancho separado da mão. |
| Interagir | 4 | Inclui empurrão provisório. |

Produzir quatro direções para a primeira roupa. A soma é 50 quadros por direção, 200 antes de reaproveitamento; seis roupas completas podem chegar a 1.200 quadros antes de otimização. Este é dimensionamento de conteúdo, não promessa de prazo. Começar com formas e uma única roupa; decidir se camadas de roupa reduzem retrabalho.

## Inimigos e chefes

Cada inimigo precisa de parado/patrulha, percepção, preparação, ataque, recuperação, dano e conclusão. Guardas têm escudo fechado e exposto. Copista precisa indicar o ataque que copiou. Sentinela precisa mostrar a trajetória antes do disparo.

Igris: comandado, preparando ondas, emitindo ondas, abafador exposto, um vínculo removido, regulador aberto, estabilizado e livre. Não criar animação de morte para ele. Yame: forma presa, amarras, memórias separando e forma pequena; a libertação é distinta de uma derrota comum.

Chefes posteriores entram somente após validação de Igris. Produzir máscaras de contato e efeitos separados das ilustrações, para que o alcance fique controlável.

## Objetos e cenário

Baús fechado/aberto; portas fechada/aberta/destravada; válvula em três estados; placas livres/pressionadas; argola válida/inválida; marco apagado/ativo; contrapeso parado/movendo; chão sólido/vão; paredes e cantos; telhados em camada superior.

A primeira região pede oficina, praça, cais, estrada e torre. Usar um conjunto modular pequeno antes de detalhar cada casa. A escala da ilustração pode ser isométrica; a implementação escolhida é de visão superior. Adaptar volumes para não esconder caminhos ou alvos.

## Ícones ainda necessários

Inventário, estado de salvamento, ações remapeadas, frasco vazio/cheio, moeda e reserva, três espadas, escudos, gancho, Matrix, custo e falta de magia, fragmento e ampliadores. As oito relíquias novas ainda precisam de ícones individuais: Selo do Restaurador, Mola de Retorno, Fivela de Lastro, Bússola de Aurélis, Lente de Maré, Afinador de Eco, Broche da Vigília e Anel de Calibração.

Cada relíquia tem uma única versão e não ganha uma cor de raridade aleatória. A descrição informa o bônus e a contrapartida.

## Áudio mínimo do protótipo

Passo em madeira e pedra; espada no ar, contato e bloqueio; escudo comum e quebra; esquiva; dano de Yggnus e inimigo; gancho disparando, fixando e recolhendo; baú, item raro e Bronze; três sinos com símbolos visuais; marco; porta; interface; relógio comum e décima terceira badalada; ruído de memórias; ambiente da praça, estrada e torre; tema de Igris.

Criar barramentos Música, Ambiente, Efeitos e Voz/Diálogo. Volume separado e legendas quando o som transmite informação. Acorde Vivo precisa de equivalentes visuais e opção de repetir notas. Não usar música extraída de outros jogos.

As falas de texto funcionam sem dublagem. Decidir dublagem depois de revisar e testar os diálogos, para não regravar cada alteração.

## Pacotes de prioridade

P0: movimento, colisão, UI simples, espada e quatro inimigos com formas provisórias.

P1: uma roupa com animações essenciais, objetos da torre, Igris e sinos.

P2: melhoria de sensação de impacto, ambientação, retratos nas falas, dois mistérios e ícones das relíquias iniciais.

P3: regiões restantes, oito mistérios completos, seis skins e acabamento de toda a campanha.

Nenhum pacote de arte substitui testes de legibilidade em movimento. Aprovar uma prancha estática não prova que um projétil seja fácil de reconhecer durante a luta.
