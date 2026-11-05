# Continuidade para Claude — A Lenda de Yggnus

Quero desenvolver um jogo 2D de ação e aventura em visão superior, chamado A Lenda de Yggnus, usando Godot 4 estável e GDScript. Este pacote contém a história, a arte de referência, diálogos estruturados, mecânicas e dados iniciais. Ele ainda não contém um jogo executável. Não afirme que existe uma implementação sem inspecionar os arquivos.

Leia primeiro:
1. documentacao/auditoria-e-decisoes.md
2. documentacao/mecanicas-e-dificuldade.md
3. documentacao/plano-implementacao.md
4. documentacao/integracao-e-salvamento.md
5. dados/resumo-conteudo.json
6. dados/dialogos.pt-BR.json e dados/missoes.json
7. mapas e dados/mapas-prototipo.json

Execute validar_conteudo.py antes de alterar os dados. O teste é de conteúdo, não de jogabilidade. Leia o relatório de validação e corrija referências quebradas sem mudar silenciosamente a história.

Construa primeiro somente a fatia: oficina de Versalhes → invasão de Yame Black → praça e estrada → Torre Akurame → libertação de Igris → retorno. Use arte provisória. A primeira versão precisa de movimento, espada, defesa, esquiva, quatro inimigos, gancho, portas, baú, marcos, diálogo e salvamento. Depois acrescente os dois primeiros mistérios. Não tente fazer a campanha inteira numa única etapa.

Requisitos:
- Movimento responsivo, sem diagonal mais rápida e sem atravessar paredes na esquiva.
- Combate usa estados e parâmetros do JSON; cada ataque só acerta um alvo uma vez por janela.
- Guarda pode ser vencido antes de obter gancho, usando a abertura após a pancada.
- Aquisições, recompensas e diálogos são idempotentes. Pular fala aplica os mesmos efeitos de concluir.
- As 13 plantas são grades de protótipo, não cenas prontas. Monte as colisões e conecte os eventos.
- O vão ~ exige a travessia do gancho; não pode virar piso normal.
- Igris tem dois ciclos de libertação e escolhe sair. Não morre na luta.
- As imagens são conceitos e não spritesheets animados. Não finja que possuem quadros de animação.
- Salvar com arquivo temporário e backup, preservando itens, missões e recibos.
- Testar no motor antes de chamar qualquer sistema de funcional.

Decisões de história que não devem mudar: Yggnus e Ádally são protagonistas; Exódia assume responsabilidade; Melissa perdeu Lívia e editou sua gravação; Ádally preserva a privacidade de Lívia; Yame Black é libertado e fica com Igris; Melissa libera as memórias e permanece no Núcleo Zero; seu destino fica incerto; Aurélis retorna danificada; o relógio final bate doze vezes e funciona normalmente.

A dificuldade padrão deve ser exigente e justa. Não tornar difícil apenas aumentando vida e dano, escondendo avisos ou tirando controle. Testar com pessoas e ajustar clareza, intervalos e combinações.

Depois da fatia, ainda será necessário: mapas detalhados das regiões posteriores, sistemas restantes, animações, tiles, ícones das oito relíquias, efeitos, música, missões finais, testes de campanha, desempenho e exportação.

Trabalhe por marcos verificáveis. Em cada entrega, informe o que foi implementado, o que foi executado no motor, os testes feitos e as pendências. Se o motor ou uma ferramenta não estiver disponível, diga isso e não substitua execução real por uma afirmação de sucesso.
