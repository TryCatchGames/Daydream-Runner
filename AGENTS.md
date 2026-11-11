# Daydream Runner — orientações para agentes

## Resumo do jogo

Daydream Runner é um runner 2D da Try Catch Games. O jogador controla o Sr. Ninjinha, amigo imaginário de uma criança, que acompanha um carro por uma versão estilizada de Pelotas. A experiência combina saltos, pulo duplo e dash, obstáculos, combates em semáforos e chefes, com cores vivas e a felicidade da infância como tema central.

A campanha prevista tem cinco fases: tutorial, ida à escola, chefe na janela da escola, volta para casa e chefe final na janela de casa. O arsenal começa com uma kunai; a katana vermelha chega no início da fase 3 e a shuriken é obtida ao vencer seu chefe. Há pontuação e ranking por fase, com identificação opcional de três letras.

## Documentos a consultar

1. Leia [docs/GDD.md](docs/GDD.md) antes de propor ou alterar regras, fases, personagens, progressão, pontuação ou direção audiovisual. É a referência consolidada de design no repositório e distingue decisões confirmadas, ideias em discussão e informações a validar.
2. Consulte [README.md](README.md) para a apresentação do projeto e a composição da equipe.
3. Para referências visuais e materiais de apresentação, consulte o [One-Sheet](GDD/One-Sheet_%20Daydream%20Runner%20-%20V2.3.png), o [pitch](GDD/DayDream%20Runner%20Pitch.pdf) e o [rascunho do GDD no Figma](https://www.figma.com/design/spt98GfmGCnoWJVtwND3mM/GDD?node-id=0-1). O Ten-Pager foi lido na consolidação de 10/11/2026; seus complementos e divergências estão registrados na seção 8 do GDD local.
4. Para trabalho técnico, consulte [Projeto/project.godot](Projeto/project.godot), as cenas em `Projeto/Scenes/` e os scripts em `Projeto/Scripts/` relacionados à mudança. O projeto Godot de Daydream Runner está em `Projeto/`; há outro projeto em `pong/`, que não deve ser confundido com o jogo principal.

## Como interpretar e atualizar a documentação

- Siga as instruções atuais da equipe e preserve a distinção de estados do GDD. “Confirmado” significa decisão de design, não prova de implementação.
- Use o GDD local como referência de design. Ao encontrar uma diferença com o Figma, materiais de apresentação ou código, registre a divergência e sua fonte; não transforme uma hipótese em regra confirmada silenciosamente.
- Não trate itens “Em discussão” ou “A validar” como escopo aprovado. Para mudanças autorizadas que dependam de detalhes ausentes, explicite as suposições e mantenha-as identificadas como tal.
- Não deduza mecânicas apenas pela presença de sprites, cenas ou scripts. Verifique o comportamento relevante no projeto antes de afirmar que algo está implementado.
- Quando a equipe decidir ou revisar uma regra, atualize `docs/GDD.md` com a decisão, seu estado e a origem ou data pertinente. Evite duplicar especificações detalhadas neste arquivo.
- Escreva a documentação em português, com codificação UTF-8, conforme [.editorconfig](.editorconfig). Preserve nomes de arquivos, classes e recursos existentes ao referenciá-los.
- Em mudanças de documentação, confira links, consistência entre os estados e fidelidade às fontes. Em mudanças no jogo, valide as cenas e os comportamentos afetados e relate o que foi efetivamente verificado.
