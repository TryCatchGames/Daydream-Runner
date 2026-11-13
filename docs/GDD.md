# Daydream Runner — Game Design Document

**Subtítulo:** That Guy Who Runs Next to the Car  
**Equipe:** Try Catch Games  
**Consolidação:** 10/11/2026

## 1. Fontes e estado das decisões

Este GDD organiza o resumo fornecido pela equipe e a consulta às dez páginas do [Ten-Pager no Figma](https://www.figma.com/design/spt98GfmGCnoWJVtwND3mM/GDD?node-id=0-1), realizada em 10/11/2026.

Os estados usados neste documento são:

- **Confirmado:** decisão de design expressa no resumo fornecido ou em uma revisão posterior da equipe, identificada neste documento. Não significa que a funcionalidade já esteja implementada ou validada no jogo.
- **Em discussão:** possibilidade mencionada pela equipe, ainda sem definição final.
- **A validar:** informação adicional do rascunho no Figma ou detalhe não especificado no resumo. Sua ausência no resumo não significa rejeição, mas também não permite tratá-la como decisão confirmada nesta consolidação.

O resumo orienta as regras confirmadas. Complementos e diferenças do Figma estão separados na seção 8, com indicação da página de origem. Novas decisões da equipe devem atualizar o conteúdo e seu estado explicitamente.

**Revisão da equipe em 10/11/2026:** o pedido de implementação inicial de score e quatro power-ups, com os esclarecimentos posteriores sobre as cenas, a renovação dos efeitos e o semáforo na `Level_1`, confirma as regras e o escopo inicial registrados na seção 3. Os parâmetros de balanceamento ainda não aprovados continuam em aberto.

## 2. Visão geral — confirmado

Daydream Runner é um runner 2D no qual o jogador controla o **Sr. Ninjinha**, amigo imaginário de um garoto. Enquanto a criança observa pela janela, o ninja corre ao lado do carro pelas ruas de Pelotas, enfrenta inimigos imaginários e amplia seu arsenal ao longo da viagem.

A campanha tem **cinco fases**, acompanhando o tutorial, a ida à escola, um confronto visto pela janela da escola, a volta para casa e o confronto final visto pela janela de casa. Não há uma história anterior elaborada: a premissa e os acontecimentos dessas fases sustentam a aventura.

### Experiência desejada

- **Felicidade da infância:** transmitir a alegria de transformar situações cotidianas em aventuras imaginárias.
- **Liberdade de movimento:** permitir saltos, pulo duplo, dash e deslocamento para frente e para trás durante a corrida.
- **Ação rápida e lúdica:** combinar desvio de obstáculos, combate e progressão de armas.
- **Mundo vivo e colorido:** representar a imaginação infantil e dar identidade local ao cenário.

### Mundo e personagens

| Elemento | Definição confirmada |
| --- | --- |
| Pelotas | Interpretação da cidade, com prédios que fazem referência a construções locais. As ruas não precisam reproduzir fielmente o mapa real. |
| Sr. Ninjinha | Protagonista jogável, ágil e calado, com a personalidade de um ninja durão. É o amigo imaginário da criança. |
| A criança | Garoto que imagina o ninja e seus adversários enquanto olha pela janela. “A Criança” é uma identificação provisória; dar-lhe um nome continua em discussão. |
| Pai | Conduz o carro e, na volta para casa, segue uma rota diferente da ida. |
| Adversários | Monstros imaginados pela criança, incluindo pequenos demônios voadores e chefes. |

## 3. Regras de jogo confirmadas

### Movimentação e obstáculos

- O jogador pode se deslocar para frente e para trás, pular, executar pulo duplo e usar dash.
- Pulo duplo e dash estão disponíveis desde o início; o tutorial ensina essas ações.
- Nas fases de corrida, os carros são obstáculos a superar com saltos para evitar dano.
- O movimento deve transmitir agilidade e liberdade, mesmo acompanhando um carro em alta velocidade.

A referência a **80 km/h** no resumo descreve a fantasia de velocidade. Ela não estabelece um parâmetro técnico de movimento, uma conversão para pixels por segundo ou uma regra de balanceamento.

### Corrida e combate

- Os trechos de corrida alternam com combates nas paradas em semáforos.
- Pequenos demônios voadores aparecem para atacar o ninja durante esses encontros.
- Derrotar inimigos gera pontuação. No semáforo da fase 2, o objetivo é derrotar o maior número possível em **60 segundos**.
- A fase 3 interrompe a corrida para uma batalha contra chefe com ataques predefinidos, executados independentemente das ações do jogador.
- A fase 5 contém o chefe final e encerra o jogo; seu comportamento ainda está em discussão.

Além do encontro descrito na fase 2 da campanha, a equipe confirmou em **10/11/2026** uma parada de **60 segundos dentro da cena `Level_1`**, após **20 segundos de corrida**, retomando a corrida na mesma cena ao terminar. O tempo de corrida até a parada e a duração da parada devem ser configuráveis. Essa decisão se refere à cena atual; a duração dos semáforos do tutorial e da volta para casa na campanha ainda precisa ser validada. O Figma apresenta uma regra mais abrangente, registrada na seção 8.

### Power-ups

Power-ups aparecem **aleatoriamente durante as fases de corrida** e concedem benefícios variados. Os quatro efeitos abaixo foram confirmados para a implementação inicial pelo pedido e pelos esclarecimentos da equipe em **10/11/2026**.

| Item | Regra confirmada |
| --- | --- |
| **+1 coração** | Recuperar um coração cheio, equivalente a **2 pontos de vida** na representação existente, sem ultrapassar a capacidade atual. Se a vida estiver cheia, conceder um coração extra temporário, consumido pelo dano, sem duração por tempo nem alteração da vida máxima padrão. Permitir até **3 corações extras** inicialmente, com limite configurável no Inspetor (revisão da equipe em **12/11/2026**). |
| **Invencibilidade** | Impedir dano por **10 segundos**, com duração configurável no Inspetor (revisão de **12/11/2026**). Tocar em inimigos comuns durante o efeito os derrota e concede pontuação normalmente, incluindo Double Points quando ativo. Exibir uma leve aura vermelha, diferenciada do feedback de dano, e restaurar o comportamento e o visual normais ao terminar. |
| **Double Points** | Dobrar os pontos concedidos por derrotar inimigos por **10 segundos**, com duração configurável no Inspetor (revisão de **12/11/2026**), aplicando o multiplicador no cálculo do ganho sem alterar o valor base do inimigo. Mostrar no HUD o efeito ativo e o tempo restante. Ao expirar, retomar o ganho normal. |
| **+10 segundos** | Acrescentar **10 segundos** ao tempo restante da parada no semáforo, uma única vez por coleta, atualizando imediatamente o HUD do tempo. A coleta ou ativação desse item fica restrita à parada ativa. |

Recoletar **Invencibilidade** ou **Double Points** enquanto o respectivo efeito está ativo **renova sua duração, sem somar tempo**. Os dois efeitos podem atuar simultaneamente. As durações iniciais de 10 segundos foram aprovadas em **12/11/2026** e permanecem configuráveis. Outros ajustes de balanceamento continuam em aberto.

A equivalência de 2 pontos por coração já é usada por [vida.gd](../Projeto/Scripts/vida.gd). A implementação existente em [player.gd](../Projeto/Scripts/player.gd) parte de 6 pontos de vida; preservar esse limite por padrão não estabelece o balanceamento definitivo da campanha. Os corações extras usam um limite separado, inicialmente 3; a capacidade exibida diminui quando eles são consumidos. Um extra pela metade permanece no HUD até perder o ponto restante.

**Revisão de 12/11/2026 — cenas reutilizáveis (pedido da equipe):** Double Points, +1 Vida e Invencibilidade compartilham uma cena-base com coleta única, sprites existentes e flutuação vertical contínua (amplitude e velocidade ajustáveis). Na corrida, deslocam-se para a esquerda com velocidade configurável; na batalha, mantêm a posição horizontal. Os efeitos são independentes e devem ser encerrados na morte, no reinício e no fim da fase. A vida extra usa os mesmos estados cheio, pela metade e vazio do HUD. Consulte [Power-ups](POWER_UPS.md) para cenas, parâmetros e integração.

### Pontuação durante a partida — escopo inicial confirmado

Decisão da equipe em **10/11/2026**:

- Cada inimigo derrotado concede pontos **uma única vez**, mesmo com múltiplos sinais, colisões ou eventos de animação. O valor base deve ser configurável por tipo de inimigo ou em uma configuração central.
- Mostrar o score atual no HUD com boa legibilidade e uma animação curta ao aumentar.
- Exibir perto do inimigo derrotado um pop-up animado que surge, sobe ou flutua e desaparece suavemente. O texto deve mostrar o **valor efetivamente concedido**, já incluindo Double Points quando ativo.
- Manter o score somente durante a partida atual. Esta entrega não inclui persistência, recordes, leaderboard, entrada de identificação nem tela de resultados ou fim de fase.

### Cenas da implementação inicial — confirmado

**Revisão de 11/11/2026 — HUD e API de score (pedido da equipe):** mostrar o score no canto superior direito do HUD, com sprite de inspiração 16 bits, início em zero e teto padrão de **99999**, modificável. Permitir adicionar e desativar fontes de pontos de forma centralizada e disponibilizar o total para outros sistemas. A apresentação inicial usa `00000`.

**Ajuste provisório de implementação, a validar:** a fonte `enemy_defeated` começa com 100 pontos por inimigo comum, editáveis no Inspector. Esse valor não define o balanceamento final. O estado pertence ao HUD da fase e reinicia ao recriar a cena; `reset()` permite reinício explícito. A API e as instruções estão em [Sistema de score](SCORE.md). A entrega de 11/11 forneceu o painel e a API. Em **12/11/2026**, Double Points passou a integrar esta API; pop-ups de derrota continuam fora desta implementação.

Esclarecimento da equipe em **10/11/2026**: a única cena de fase atualmente destinada ao produto final é [Level_1.tscn](../Projeto/Scenes/Fases/Level_1.tscn). A integração inicial de score, power-ups e semáforo deve ocorrer nela. [FaseBatalha.tscn](../Projeto/Scenes/Fases/FaseBatalha.tscn) é exclusivamente uma cena de teste de combate para os chefes das fases 3 e 5; não integra o produto final nem funciona como a parada da corrida. Essa delimitação das cenas atuais preserva o planejamento de cinco fases da seção 4.

**Escopo técnico confirmado pelo pedido da equipe em 13/11/2026:** substituir o comprimento fixo do looping da `Level_1` por camadas visuais reutilizáveis com limites automáticos, incluindo estrada, prédios e fundo, preservando a relação de velocidades existente. A repetição visual deve permanecer independente de cruzamentos e eventos de progressão, com objetos de gameplay fora das faixas repetíveis. A organização e o fluxo de edição estão em [Loop visual dos cenários](SCENERY_LOOP.md).

**Diferença de implementação, verificada em 13/11/2026:** `Level_1` contém os sprites de cruzamento e semáforo, mas não possui controlador de batalha ou gatilho de parada conectado. A refatoração fornece parada e retomada do cenário sem implementar esse fluxo ausente. A regra confirmada de 20 segundos de corrida e 60 segundos de combate permanece como requisito, sem ser apresentada como comportamento já validado.

### Pontuação e ranking — planejamento da campanha

- Ao final de **cada fase**, exibir a pontuação obtida e um ranking dos maiores resultados daquela fase específica.
- Solicitar, ao final de cada fase, uma identificação de **três letras**, inspirada nos arcades.
- O preenchimento dessa identificação é **opcional**.
- Os valores finais por inimigo, outras fontes de pontuação e o comportamento ao não informar as três letras ainda precisam de definição. As regras iniciais de ganho por derrota e Double Points estão descritas acima.

Esses requisitos de fim de fase continuam no planejamento da campanha e ficam fora da entrega inicial de score e power-ups. O armazenamento local do ranking é descrito no Figma e está separado como informação a validar na seção 8.

## 4. Estrutura das cinco fases

| Fase | Contexto | Conteúdo confirmado | Limites da definição |
| --- | --- | --- | --- |
| **1 — Tutorial** | Introdução às ações do ninja. | Ensinar deslocamento para frente e para trás, salto sobre carros, pulo duplo e dash. Introduzir o combate contra poucos inimigos em um semáforo. | Duração, número de inimigos e sequência detalhada das instruções não especificados. |
| **2 — Ida à escola** | Viagem de casa até a escola. | Começar com um trecho de corrida em que o desafio é saltar sobre carros para evitar dano. Depois, parar em um semáforo e enfrentar demônios voadores por 60 segundos, buscando o máximo de eliminações para pontuar. | “Primeiros minutos” não determina duração exata. Quantidade total de encontros e duração total da fase não especificadas. |
| **3 — Janela da escola** | A criança observa pela janela da escola. | Batalha sem corrida contra um chefe com ataques predefinidos, na linha das referências Hollow Knight e The Messenger. Receber a katana vermelha no início, imaginada pela criança como auxílio ao ninja. Ao derrotar o chefe, obter a shuriken que ele deixa. | Aparência, ataques concretos, vida e balanceamento do chefe não especificados. |
| **4 — Volta para casa** | O pai escolhe uma rota diferente da ida. | Fase mais difícil e mais rápida, com mais semáforos no percurso e mais inimigos por semáforo do que na ida. A shuriken já integra o arsenal. | Velocidade, quantidade e duração dos encontros, composição de inimigos e balanceamento não especificados. |
| **5 — Janela de casa** | A criança imagina um adversário muito poderoso pela janela de casa. | Confronto com o último chefe e encerramento do jogo. | Conceito da fase, visual, ataques e comportamento do chefe continuam em discussão. Não aplicar automaticamente o padrão do chefe da fase 3. |

## 5. Progressão e arsenal — confirmado

| Momento | Arma ou habilidade | Papel definido |
| --- | --- | --- |
| Início do jogo | Kunai | Arma inicial de combate. |
| Início do jogo | Pulo duplo e dash | Recursos de movimentação disponíveis desde o começo. |
| Início da batalha da fase 3 | Katana vermelha | Nova arma recebida como auxílio imaginado pela criança. |
| Vitória sobre o chefe da fase 3 | Shuriken | Recompensa deixada pelo chefe; torna-se arma secundária de disparo, utilizável nas fases seguintes. |

A intenção é que o ninja descubra poderes e fique mais forte ao longo da aventura. Além dos marcos acima, não há uma lista confirmada de habilidades por fase. Dano, alcance, cadência, munição e regras de troca de armas ainda precisam de definição.

## 6. Direção visual e sonora — confirmado

O jogo deve ser colorido e vivo, com ação rápida e lúdica que reflita a imaginação de uma criança. A felicidade da infância é a emoção central da experiência.

A direção musical busca uma atmosfera de **16 bits**. O resumo relata a seleção de músicas gratuitas encontradas no YouTube ou no itch.io por combinarem com essa proposta; não apresenta uma lista de faixas ou suas licenças. A descrição mais específica de pixel art aparece no rascunho do Figma, registrada na seção 8.

## 7. Ideias em discussão

Os itens abaixo são possibilidades, não requisitos aprovados nem funcionalidades garantidas para a entrega.

| Tema | Ideia ou decisão pendente |
| --- | --- |
| Nome da criança | Escolher um nome ou manter a identificação “A Criança”. |
| Cutscenes | Incluir uma apresentação para contextualizar a aventura. É desejável, mas depende do tempo disponível; narrativa e cutscenes não são o núcleo do jogo. |
| Fase e chefe finais | Desenvolver o conceito da última fase e do adversário. Sua posição como confronto final está confirmada; os detalhes não estão. |
| Power-up de dash ofensivo | Fazer o dash causar dano. Não implica dano no dash padrão. |

Os quatro efeitos da entrega inicial e a renovação de Invencibilidade e Double Points foram confirmados e estão na seção 3. Permanecem em discussão outros power-ups e os valores finais de chances de aparição, durações dos efeitos, capacidade de vida e balanceamento.

## 8. Complementos do Figma a validar

O Ten-Pager foi acessado e lido. Os pontos abaixo aparecem nele, mas não estão confirmados pelo resumo ou ampliam seu escopo. Permanecem como referências para decisão da equipe, sem substituir as regras das seções anteriores.

| Tema | Informação do rascunho | Origem no Ten-Pager e tratamento |
| --- | --- | --- |
| Plataforma e público | PC, engine Godot, pixel art de inspiração 16 bits e público de todas as idades. | Página 1. Validar plataforma de entrega, público e especificação visual; a presença do projeto Godot no repositório é um fato técnico, não confirmação dos demais itens. |
| Personagens | Ninja em vermelho e preto; criança explicitamente não jogável. | Página 3. Complementos de caracterização a validar. |
| Duração dos semáforos | Encontros de 60 segundos como regra geral. | Página 4. O resumo confirma esse tempo para o encontro da fase 2; a revisão da equipe de 10/11/2026 também confirma 60 segundos para a parada da cena atual `Level_1`. A generalização para as demais fases da campanha continua a validar. |
| População de inimigos | Máximo de cinco inimigos simultâneos; reposição pode ocorrer fora da tela após uma eliminação. | Páginas 4 e 8. Quantidades e lógica de aparecimento a validar. |
| Fim do semáforo | Inimigos sobreviventes perseguem o ninja quando a corrida recomeça. | Página 4. Comportamento ausente do resumo, a validar. |
| Padrões dos chefes | Ataques predefinidos para os chefes das fases 3 e 5. | Página 4. A página 8 e o resumo deixam o chefe final em definição; manter seus ataques em aberto. |
| Moedas | Recolher moedas também gera pontuação. | Página 7. Sistema adicional ausente do resumo, a validar. |
| Variedade de inimigos | Novos tipos de inimigos nas fases posteriores. | Página 8. Validar escopo e comportamentos antes de considerar novos tipos obrigatórios. |
| Ranking e número de jogadores | Um jogador por vez, ranking local no próprio computador, sem depender de internet, contas ou servidores. | Página 9. Validar alcance do ranking e persistência. O ranking por fase e a identificação opcional de três letras já estão confirmados pelo resumo. |
| Distribuição e apresentação | Projeto acadêmico para exposição nos computadores da turma, sem comercialização, microtransações ou conteúdos pagos previstos. Distribuição pública posterior a decidir. | Páginas 9 e 10. Contexto e escopo de distribuição a validar. |
| Prazos | Entrega do GDD em **18/11/2026** e do jogo em **09/12/2026**, sem equivaler a uma data de lançamento público. | Página 10. Datas do rascunho a confirmar com a equipe. |

As referências a HUD, recuperação de vida e power-ups das páginas 6 e 7 deixaram de ser tratadas aqui como propostas pendentes para a entrega inicial. As regras aprovadas posteriormente pela equipe em **10/11/2026** estão na seção 3; essa aprovação não estende automaticamente o escopo a todos os detalhes do rascunho.

## 9. Detalhes ainda não especificados

Estas lacunas indicam decisões necessárias para detalhar a implementação, sem sugerir soluções obrigatórias:

- **Controles e movimento:** teclas ou botões, funcionamento da corrida, velocidades, altura dos saltos, duração e recarga do dash.
- **Vida e falha:** balanceamento definitivo da vida inicial e máxima da campanha, dano dos carros e inimigos, efeitos do dano, condições de derrota, reinício e continuidade entre fases. A representação e a regra do coração da entrega inicial estão na seção 3.
- **Combate:** valores e limites das armas, ataques concretos dos inimigos e chefes, intervalos e quantidades de aparecimento.
- **Fases:** duração total dos percursos, posicionamento de obstáculos, transições entre fases e critérios precisos de conclusão. Para a cena atual `Level_1`, já estão confirmados 20 segundos de corrida até a parada e 60 segundos de parada, ambos configuráveis.
- **Pontuação e ranking:** valores, desempates, tamanho da lista, persistência, registro sem identificação e eventual pontuação de moedas.
- **Progressão:** outros poderes além dos descritos, regras de troca de armas e eventual salvamento do progresso.
- **Áudio:** relação final de faixas, fontes e créditos correspondentes.

## 10. Documentos relacionados

- [README do projeto](../README.md): apresentação, equipe e materiais visuais.
- [Loop visual dos cenários](SCENERY_LOOP.md): camadas, limites automáticos, edição na Godot, reutilização e validação técnica.
- [GDD no Figma — Ten-Pager](https://www.figma.com/design/spt98GfmGCnoWJVtwND3mM/GDD?node-id=0-1): rascunho consultado como referência complementar.
- [One-Sheet local](../GDD/One-Sheet_%20Daydream%20Runner%20-%20V2.3.png) e [pitch local](../GDD/DayDream%20Runner%20Pitch.pdf): materiais de apresentação existentes. Não foram usados para estabelecer novas regras nesta consolidação.
