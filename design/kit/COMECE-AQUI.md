# COMEÇAR POR AQUI — A LENDA DE YGGNUS

Este pacote prepara o início do desenvolvimento. Contém conteúdo, regras, plantas e dados estruturados. Ainda não é um jogo executável e não inclui um projeto Godot funcional.

## Leitura recomendada

1. Abra index.html para consultar o portal do projeto.
2. Leia a auditoria: documentacao/auditoria-e-decisoes.md.
3. Leia as mecânicas: documentacao/mecanicas-e-dificuldade.md.
4. Consulte a ordem de implementação: documentacao/plano-implementacao.md.
5. Experimente a prévia das conversas em dialogos.html.
6. Use os mapas em mapas/ e os dados em dados/ ao montar o projeto Godot.
7. Execute validar_conteudo.py com Python 3 antes de alterar ou importar conteúdo.

## Conteúdo consolidado

147 cenas, 491 falas e indicações, 30 missões, oito mistérios opcionais e oito relíquias. Inclui 13 salas de protótipo em grade, 16 tipos de inimigo, catálogo de 40 itens e definições de chefes, habilidades, economia e salvamento.

As referências anteriores de história e arte estão em referencias/roteiro e referencias/atlas. Não substituem sprites animados, colisões ou mapas prontos para o motor.

## O que fazer primeiro

Criar projeto Godot 4 estável em 2D e implementar movimento/colisão numa sala provisória. Depois: espada, defesa, esquiva e um inimigo. Só então montar as 13 salas e integrar os textos. O objetivo é fechar a sequência da oficina até Igris antes de expandir a campanha.

## O que ainda falta

Programação no motor, cenas e executável; sprites animados e tiles; ícones das oito relíquias novas; sons e músicas; plantas detalhadas posteriores a Akurame; posição exata de 24 fragmentos nas regiões seguintes; testes de controles, dificuldade, campanha e desempenho. Há uma lista detalhada em arte-e-audio-pendentes.md e no plano de implementação.

## Continuidade com outro assistente

PROMPT-PARA-CLAUDE.md contém instruções prontas para entregar a outro assistente. Envie o ZIP completo, não apenas o prompt, para que ele tenha dados, plantas e referências.

## Validação

O relatório verifica coerência de conteúdo e simula transações de recompensa. Não testa o motor, não mede latência e não comprova diversão. Os testes reais estão descritos no plano. Os arquivos anteriores foram preservados em referencias; as regras 1.1 resolvem as divergências documentadas.
