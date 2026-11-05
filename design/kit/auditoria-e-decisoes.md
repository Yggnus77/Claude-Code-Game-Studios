# A LENDA DE YGGNUS — AUDITORIA E DECISÕES CONSOLIDADAS

Versão 1.1. Revisão dos arquivos de roteiro e atlas já entregues. Nenhuma partida real foi executada: o material existente era documentação e arte conceitual, sem projeto Godot, cenas ou scripts de jogo. A revisão abaixo resolve lacunas de especificação e separa o que pode começar do que ainda precisa ser produzido.

## O que estava faltando e foi acrescentado

| Lacuna | Entrega nesta revisão | Alcance |
|---|---|---|
| Conversas e explicações durante a campanha | 147 cenas com nós, gatilhos, falas, indicações e duas perguntas explicativas | Campanha e missões descritas, mais mensagens de sistema. |
| Tempos e resposta do combate | Mecânicas, combate.json e tabela de inimigos | Base testável; balanceamento depende de jogo implementado. |
| Mapas utilizáveis como referência de implementação | 13 salas do protótipo em JSON, grade CSV e planta SVG | Oficina, praça, estrada e Torre Akurame. |
| Dependências e ordem de objetivos | 30 missões e regras de conclusão | Inclui duas rotas em qualquer ordem. |
| Entrega e repetição de itens | Catálogo com IDs e recibos de recompensa única | Impede duplicação na integração se a política for implementada. |
| Chefes descritos apenas em prosa | Definição dos encontros e transições | Igris detalhado para protótipo; demais como contratos de campanha. |
| Salvamento e recuperação | Exemplo de arquivo, política de tentativa e validação de conteúdo | Falta escrever e testar o sistema no motor. |
| Arte necessária e sons | Lista de produção de animações, tiles, interface e áudio | Requisitos, não arquivos já animados ou sons gravados. |
| Ordem de programação | Etapas com critérios de conclusão e testes | Começa pela primeira área; evita construir campanha inteira de uma vez. |

## Inconsistências corrigidas

1. **Guarda antes do gancho.** O inimigo ficava protegido e parecia depender da ferramenta guardada atrás dele. Agora sua pancada cria 0,70 s de abertura pelas laterais e costas. Depois de obter o gancho, o jogador pode criar 1,20 s de abertura sem esperar a pancada.
2. **Frasco inicial e recompensa da bomba.** Começa-se com dois espaços e um frasco vazio. A bomba entrega o segundo frasco, não o primeiro. Morina e o posto entregam o terceiro e o quarto frascos, junto da capacidade necessária, uma única vez.
3. **Energia para passagem obrigatória.** Pontes, leitura e pontos de fixação de chefe não gastam Ressonância. Fio de Âncora em inimigo comum continua custando 15. Uma Aracne não pode travar a campanha quando a barra estiver vazia.
4. **Defesa precisa obrigatória.** O Escudo Ressonante dá uma vantagem de execução, mas há reflexão ambiental nos enigmas e solução de posicionamento nos chefes. A janela de 0,11 s não vira bloqueio de narrativa.
5. **Vida desenhada e vida numérica.** A versão mais recente do HUD usa barra âmbar, emblema e número. Os valores de referência são 6, 10 e 14. O número é a fonte da regra, não uma contagem de detalhes da ilustração.
6. **Ampliadores.** São dois objetos únicos: 60 → 90 → 120. Três estágios visuais não significam três melhorias.
7. **Primeiro ganho de habilidades.** Pulso de Eco é habilitado no primeiro Marco após a invasão. O Fio aparece após as Comportas; Lanterna na caverna; Acorde na luta do Devorador; Véu e Lâmina com Exódia; botas e arco em suas rotas.
8. **Espada e escudo durante a invasão.** A cena de entrada de Yame é modal antes de o combate começar; ao concluí-la ou pulá-la, os dois equipamentos são entregues na mesma transação. Não cobrar do jogador uma luta antes de entregar o comando de ataque.
9. **Morte, consumo e chefes.** Tentativas restauram o snapshot de entrada da arena. Recompensas só são confirmadas na vitória. Consumíveis da tentativa perdida retornam, sem possibilidade de comprar ou coletar ganhos externos durante a arena.
10. **Duas rotas.** Agulhas e Vigias têm flags independentes; ambas precisam estar concluídas. A ordem não altera diálogos de modo a chamar uma delas sempre de primeira.
11. **Lívia e memórias.** Lívia continua falecida; a gravação não é uma pessoa ressuscitada. Aurélis reaparece danificada com seus sobreviventes. A gravação privada nunca vira moeda, chantagem ou arma.
12. **Escopo de arte.** Pranchas são conceitos. Seus rótulos pequenos e detalhes decorativos não criam itens, inimigos ou regras adicionais. IDs, catálogos e roteiro consolidado orientam implementação.

## Prioridade dos documentos

Para fatos da história: decisões do autor → roteiro principal → diálogos 1.1, que concretizam as cenas sem mudar as decisões.

Para números, aquisição e regras: especificação 1.1 → dados JSON 1.1 → atlas e roteiro 1.0. Uma divergência entre documento e JSON 1.1 deve ser tratada como erro e corrigida antes de implementar; não escolher silenciosamente um dos dois.

Para mapas: plantas em grade do protótipo orientam os testes de colisão. A arte conceitual orienta aparência e atmosfera. Não reconstruir cada pixel da ilustração como se fosse uma parede navegável.

13. **Bolsas fora de ordem.** Uma bolsa nova nunca reduz a capacidade atual. Fazer a missão do porto depois do farol mantém 1.500 Bronze.
14. **Primeira compra sem repetição.** Duas reservas de 10 Bronze no circuito inicial permitem comprar uma recarga restauradora sem repetir inimigos. Elas são coletas únicas.

## O que ainda falta de verdade

- Implementar os sistemas no motor e criar um executável.
- Produzir sprites com animações e tiles modulares; as ilustrações entregues não os substituem.
- Construir as salas detalhadas das Comportas em diante; este pacote especifica somente as 13 salas do primeiro protótipo em grade.
- Produzir efeitos sonoros, compor música e, se desejado, gravar vozes.
- Implementar e testar controles, salvamento, colisões, transições, combate, diálogo e acessibilidade.
- Medir desempenho e dificuldade em máquinas e com jogadores reais.
- Revisar a disponibilidade comercial do título e dos nomes antes de divulgação e distribuição; os nomes escolhidos foram preservados, não pesquisados como marcas neste trabalho.

Essas pendências não impedem o início: a primeira etapa usa formas provisórias e texto. Não está concluída a produção inteira nem foi comprovado que os números já estejam equilibrados.
