# A LENDA DE YGGNUS — ORDEM DE IMPLEMENTAÇÃO E ACEITAÇÃO

## Comece por uma fatia de 30–45 minutos

A primeira entrega é: oficina → praça → estrada → Torre Akurame → libertação de Igris → retorno. Use apenas a roupa Restaurador e quatro inimigos: Rastejo, Mariposa, Soldado e Guarda. As 13 salas têm plantas em grade, conexões e entidades. São referências de montagem; não cenas prontas do motor.

As duas primeiras histórias opcionais, Troco e Quarto Toque, têm pistas posicionadas nessas plantas. As outras seis têm diálogos, estados, pistas, solução e recompensa definidos, mas precisam de salas de campanha posteriores. Não tentar construir tudo junto.

## Etapa 1 — Projeto, movimento e câmera

Criar o projeto Godot, registrar versão e configurar ações. Montar uma sala de teste com paredes e portas. Implementar andar em oito direções, colisão dos pés e câmera. Validar controle desconectado, perda de foco e pausa.

Concluído quando: diagonal não é mais rápida, não prende nas quinas, a câmera não treme e 30/60/120 quadros de renderização não alteram a distância percorrida em um mesmo intervalo de física. Medir latência; não inferir pela taxa de quadros.

## Etapa 2 — Combate mínimo

Espada de Oficina, defesa, esquiva, vida, dano, invulnerabilidade e um Rastejo. Depois acrescentar Mariposa, Soldado e Guarda. Usar os parâmetros do catálogo, sem copiar a lógica de cada inimigo em vários lugares.

Concluído quando: um golpe não acerta o mesmo alvo duas vezes; dois contatos simultâneos não retiram duas vidas durante a invulnerabilidade; esquiva não cruza parede; defesa distingue frente e costas; o Guarda pode ser vencido sem gancho.

## Etapa 3 — Diálogos, inventário e eventos

Importar os dados. Montar caixa de fala e histórico. Implementar os tipos de nós, eventos, escolhas explicativas e efeitos de conclusão. Criar o sistema de recibos antes de adicionar dezenas de baús.

Concluído quando: concluir e pular uma cena concedem exatamente os mesmos itens; reiniciar ou repetir o evento não duplica nada; interagir rapidamente não abre duas caixas; fala de combate não pausa uma esquiva.

## Etapa 4 — Trecho de Versalhes

Montar oficina e praça. Iniciar sem arma equipada. A cena da invasão entrega espada e escudo antes de ativar os ataques. Implementar três amarras e a fuga de Yame, o primeiro marco e a transição para a estrada.

Concluído quando: a sequência pode ser jogada e também pulada sem travar; o objetivo fica compreensível sem narração externa; o jogador pode morrer e retornar sem perder a Matrix ou repetir recompensas.

## Etapa 5 — Estrada e recompensas

Montar duas salas de estrada, a bomba opcional, o comerciante e os recursos únicos. Validar chave, frascos, Bronze e reserva. Montar as pistas do mistério do troco, bloqueadas até o registro de Igris ser obtido.

Concluído quando: a bomba entrega apenas o segundo frasco; uma coleta de 100 com bolsa 190/200 produz 200 e reserva 90; reabrir o objeto não altera o saldo; não é necessário repetir inimigos para avançar.

## Etapa 6 — Torre e gancho

Montar base, guardas, oficina e treino. Depois contrapesos, sinos e antecâmara. Implementar a travessia especial e os flags de mecanismos.

Concluído quando: existe caminho até o gancho sem já possuí-lo; o gancho não atravessa paredes; o vão não vira piso caminhável; ida e volta pela porta usam o mesmo estado; reiniciar o enigma não fecha um baú já recolhido.

## Etapa 7 — Igris

Implementar os dois ciclos, avisos visuais, abafadores, sinos e regulador. Chegar à estabilização e à conversa de escolha. Registrar a entrega do arquivo e a saída voluntária.

Concluído quando: todos os estados de reinício funcionam; zero energia não impede vitória; o diálogo inicial não se repete obrigatoriamente a cada tentativa; o chefe não pode ser morto por dano comum; o resultado não depende de apertar um botão durante a fala.

## Etapa 8 — Dois mistérios e uma relíquia

Implementar pistas e comparação do Troco e do Quarto Toque. Aplicar um espaço de relíquia e seus modificadores. Tentar equipar e desequipar muitas vezes; sempre recalcular a partir dos números-base, sem acumular bônus.

Concluído quando: acerto sem as pistas não conclui a missão; erro não retira dinheiro; recompensa é única; Mola de Retorno altera somente a recarga prevista; Selo altera os dois tempos e mantém a cura em 3.

## Etapa 9 — Salvamento e exportação

Implementar arquivo temporário, backup, recuperação e versão. Salvar/fechar/carregar em cada sala e nas transições narrativas. Exportar um executável de teste para uma máquina diferente da usada no desenvolvimento.

Concluído quando: progresso único não duplica nem some; arquivo inválido tem recuperação clara; sair durante Igris volta à entrada de tentativa; a pasta exportada contém tudo de que precisa e não depende do caminho local do desenvolvedor.

## Etapa 10 — Teste de jogo e decisão de expansão

Cinco pessoas sem instrução verbal, com registro de mortes, travamentos, entendimento e comandos que pareciam não responder. Refinar os tempos antes de produzir as seis skins completas.

Concluído quando: não existem travamentos de campanha; a maioria explica o que fazer com o gancho; os ataques são percebidos antes do dano; Igris exige aprendizado; o retorno à oficina encerra a fatia corretamente. O alvo de 2–5 tentativas é uma hipótese a observar, não uma obrigação estatística.

## Campanha posterior

Construir Comportas → caverna → confissão → Agulhas/Vigias → Núcleo → epílogo, nessa ordem de dependência. Agulhas e Vigias devem continuar jogáveis em qualquer ordem. Para cada região: planta detalhada, equipamento, inimigos, enigma, chefe, diálogo, salvamento, áudio e teste de retorno.

As histórias opcionais 03–08 podem entrar junto às regiões correspondentes. Não atrasar o protótipo para implementar o inventário inteiro, um sistema de fabricação, multiplayer ou mundo aberto, que não fazem parte do escopo definido.

## Falhas que bloqueiam publicação

Perda ou duplicação de recurso persistente; progressão impossível; aquisição circular de item; dano durante conversa modal; ataque inevitável fora da câmera; arquivo de salvamento destruído por gravação parcial; controles sem remapeamento; texto essencial ilegível; chefe que altera as decisões de história por engano; ausência de licença ou origem conhecida em áudio/arte usados no executável.
