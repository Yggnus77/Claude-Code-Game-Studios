# A Lenda de Yggnus — roteiro do teste de jogo (Etapa 10)

Fonte: `design/kit/plano-implementacao.md` § Etapa 10 e `mecanicas-e-dificuldade.md` §13.
A ficha de cada pessoa segue o modelo do estúdio (`/playtest-report new`), em português e com as
perguntas da etapa.

## O que a etapa precisa responder

1. Não há travamentos de campanha: ninguém fica preso sem conseguir seguir.
2. A maioria consegue explicar o que fazer com o gancho.
3. Os ataques são percebidos antes do dano.
4. Igris exige aprendizado. Uma hipótese a observar, não uma meta: algo entre 2 e 5 tentativas.
5. O retorno à oficina encerra a fatia corretamente.

Metas de triagem do kit, que não são resultados: quatro de cinco entendem o gancho sem ajuda; a maioria
chega a Igris em até 35 min; nenhuma morte vem de algo que não se via.

## Como conduzir

- **Quem:** cinco pessoas que não conhecem o projeto. Cada sessão dura de 30 a 45 min.
- **Sem instrução falada.** Não explique controles nem o objetivo. Deixe a pessoa ler a tela. Se ela
  pedir ajuda, anote o que pediu e responda só "faça o que acha que deve".
- **Antes:** use um espaço vazio na tela de título (um espaço por pessoa, ou apague a pasta `saves`
  entre pessoas). A pessoa escolhe teclado ou controle.
- **Durante:** fique atrás, sem apontar. Anote na ficha os momentos de confusão e o que a pessoa disse.
  Peça que ela pense em voz alta.
- **Depois:** faça as perguntas da ficha. A mais importante: "quando um comando não fez nada, o que você
  queria fazer?"
- **Encerrar:** Esc → "Salvar e sair do jogo". O registro da sessão é gravado ao sair.

## O que o jogo registra sozinho

Ao jogar num espaço, o jogo grava em `registros de teste` (Esc → "Abrir a pasta dos registros de teste")
um arquivo `.txt` legível e um `.json` por sessão. No Windows a pasta fica em
`%APPDATA%\Godot\app_userdata\A Lenda de Yggnus\playtest`. O registro traz:

- mortes por sala e o que deu o último golpe;
- golpes recebidos sem morrer, por origem (ajuda a ver se os ataques são percebidos antes do dano);
- quando a pessoa acertou a espada, defendeu com o escudo, fez uma defesa precisa e atravessou com o
  gancho pela primeira vez;
- cada tentativa contra Igris, com o resultado e a duração;
- comandos que não fizeram nada (espada antes de tê-la, examinar sem nada à frente, porta fechada,
  gancho sem lugar seguro, curar com a vida cheia ou sem frasco);
- as vezes em que a sala foi reiniciada (R), que costumam indicar que a pessoa ficou presa;
- cada entrada numa sala, com a hora de chegada e o tempo que a pessoa ficou nela (inclui o tempo até
  chegar à Câmara de Igris, que o kit espera em até 35 min), e o tempo até o fim da fatia.

O relógio começa quando a pessoa escolhe o espaço na tela de título.

O registro não percebe tudo: um ataque apertado durante a recuperação, o gancho lançado no vazio ou uma
tecla que a pessoa achou que faria algo ficam por conta da observação (pergunta 4 da ficha).

O registro só fica no computador. Nada é enviado.

## Como me mandar o resultado

Compacte a pasta `playtest` e as cinco fichas e mande aqui no projeto. Eu junto tudo com
`/playtest-report analyze` e separo o que é ajuste de tempo, o que é clareza e o que é defeito, antes de
mexer em qualquer número.

---

## Ficha de observação (uma por pessoa)

**Pessoa:** ______ **Data:** ______ **Duração:** ______ **Teclado ou controle:** ______
**Arquivo do registro:** `sessao-…-espaco_.txt`

### Primeiros 5 minutos
- Entendeu o objetivo? ( ) sim ( ) não ( ) em parte
- Entendeu os controles? ( ) sim ( ) não ( ) em parte
- Reação: ( ) envolvida ( ) confusa ( ) entediada ( ) frustrada ( ) animada
- Observações:

### Durante o jogo
| Momento | O que a pessoa fez ou disse | Confusa? | Levou golpe sem ver? | Parada mais de 2 min sem progresso? |
|---|---|---|---|---|
| Oficina e invasão de Yame | | | | |
| Praça e estrada | | | | |
| Guardas (atacar quando a arma bate no chão) | | | | |
| Primeiro gancho | | | | |
| Contrapeso e sinos | | | | |
| Igris | | | | |
| Volta à oficina | | | | |

### Perguntas depois da sessão
1. O que o gancho faz e quando dá para usar? (anote as palavras da pessoa)
2. Você via os ataques vindo antes de levar dano? Algum golpe pareceu vir do nada?
3. Contra Igris: o que você aprendeu entre uma tentativa e outra?
4. Quando um comando não fez nada, o que você queria fazer?
5. Em algum momento você não sabia para onde ir?
6. Jogaria de novo? ( ) sim ( ) não ( ) talvez
7. Dificuldade: ( ) fácil ( ) na medida ( ) difícil · Ritmo: ( ) lento ( ) bom ( ) rápido

### Defeitos vistos
| # | O que aconteceu | Gravidade | Repetiu? |
|---|---|---|---|

### As 3 coisas mais importantes desta sessão
1.
2.
3.
