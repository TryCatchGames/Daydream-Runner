# Loop visual dos cenários

A [Level_1](../Projeto/Scenes/Fases/Level_1.tscn) usa camadas com limites calculados a partir da composição editada na Godot. Adicionar, remover ou reposicionar sprites antes de executar a fase atualiza o período de repetição, sem informar um comprimento total em pixels.

## Do sistema antigo à composição por camadas

Antes, [esteira.gd](../Projeto/Scripts/esteira.gd) movia o nó `Esteira` inteiro a 400 px/s e somava `8865` à sua posição quando ultrapassava esse limite. Esse valor correspondia à largura de uma textura de estrada, mas não acompanhava a extensão real da fase editada. Prédios, cruzamento, fundo e até o corpo físico do chão recebiam o mesmo reposicionamento.

Agora a raiz permanece fixa e coordena três faixas independentes. Cada faixa usa [SceneryLoopLayer](../Projeto/Scripts/scenery_loop_layer.gd), que mede os visuais e configura um [Parallax2D](https://docs.godotengine.org/en/stable/classes/class_parallax2d.html) interno. O recurso nativo repete o desenho, sem instanciar cópias dos nós. Não é preciso criar um gerenciador diferente por fase.

Camadas independentes permitem que a estrada e os prédios tenham extensões diferentes: editar uma não muda o período da outra. Agrupar toda a fase em um único trecho exigiria compatibilizar extensões sem necessidade. A separação também permite configurar velocidades por camada futuramente. Nesta migração, todas continuam com multiplicador 1 e velocidade de 400 px/s; não foi introduzida diferença de parallax.

| Nó em `Esteira` | Responsabilidade |
| --- | --- |
| `Ceu` | Repete a composição de fundo existente em `Painel`, incluindo as duas `TextureRect`. |
| `Predios` | Repete as fachadas usando seus próprios limites. |
| `Estrada` | Repete apenas os sprites da estrada, com extensão própria. |
| `Chao` | Mantém o `StaticBody2D` e sua colisão fixos, na altura existente. |
| `EventosVisuais` | Desloca `Esquina` e `Semáforo` uma vez ao longo da corrida, sem reciclagem. |

Carros, jogador, HUD e power-ups continuam fora das faixas repetíveis. Os carros mantêm seu movimento próprio de 700 px/s e seus corpos e áreas de dano existentes. A refatoração não acrescenta spawners nem altera pulo, dash, dano ou combate.

## Como os limites são obtidos

Cada filho direto da camada é um trecho: um `Sprite2D` ou um grupo `Node2D` contendo visuais estáticos. O sistema percorre seus descendentes e transforma os retângulos desenhados para o espaço local da camada.

- Para `Sprite2D`, usa `get_rect()`, incluindo centralização, offset, região e dimensões do frame.
- Aplica as transformações dos grupos e sprites, incluindo escala, espelhamento, rotação e posição.
- Para `TextureRect`, mede o retângulo do controle transformado. São aceitos os modos `Scale` e `Tile`; coloque o controle dentro de um grupo `Node2D`.
- Visuais ocultos ou sem textura não ampliam os limites.
- A largura entre a menor borda esquerda e a maior borda direita determina o período. Não há soma manual nem constante de comprimento.

Ao iniciar, o conteúdo é normalizado em X dentro do repetidor. A altura, escala, `z_index` e ordem de desenho dos elementos são mantidos. O deslocamento fica limitado ao período por uma operação modular, inclusive quando um passo atravessa várias voltas. A fase usa um `float` de 64 bits separado do `Vector2` de renderização para evitar acumular arredondamentos a cada passo. A quantidade de repetições visuais é ajustada à janela e à transformação da camada, permitindo faixas menores que a tela.

Os limites são calculados ao iniciar a fase. Este fluxo cobre a edição no editor seguida de uma nova execução; não fornece reconstrução automática para adicionar, remover ou redimensionar trechos durante a partida.

## Editar a fase na Godot

1. Abra `Projeto/project.godot` e a cena `Level_1.tscn`.
2. Adicione, duplique ou instancie um sprite em `Esteira/Estrada` ou `Esteira/Predios`. Para um trecho com várias peças decorativas, agrupe-as em um `Node2D` filho da camada.
3. Posicione os trechos visualmente. A ordem espacial em X define a sequência; a ordem dos nós na árvore continua definindo a ordem de desenho.
4. Confira os contornos e os avisos da camada. Se desejar uma faixa sem espaços entre os retângulos dos trechos, selecione a camada e use **Encaixar trechos no eixo X** no Inspetor.
5. Salve e execute a fase. Os limites são reconhecidos automaticamente.

Remover um trecho só exige removê-lo da cena. Se a remoção deixar um espaço entre os restantes, reposicione-os ou use o botão de encaixe. Para reorganizar, mova os trechos no eixo X e, se necessário, encaixe novamente.

O botão ordena os trechos pela borda esquerda atual e aproxima cada um do anterior, preservando o início da faixa. Altera somente a posição X dos filhos diretos; mantém Y, escalas, espelhamento e a ordem da árvore. No editor, a operação participa do histórico de desfazer/refazer. Ele não é executado automaticamente durante a partida e não corrige o desenho da arte.

Na migração da `Level_1`, os prédios e os cinco sprites de estrada foram encaixados horizontalmente, preservando os sprites adicionados na composição existente. As pequenas diferenças de posição e escala vertical entre os sprites de estrada foram uniformizadas pelo primeiro sprite para corrigir as emendas; as alturas dos prédios, do cruzamento e do semáforo foram preservadas.

### Avisos e opções do Inspetor

| Opção da camada | Uso |
| --- | --- |
| `Speed Multiplier` | Multiplica o deslocamento recebido da esteira; começa em 1 em todas as camadas. |
| `Warn Overlaps` | Avisa sobre sobreposições entre os retângulos dos trechos. Desative somente quando elas fizerem parte da composição desejada. |
| `Warn Vertical Seams` | Compara as bordas superior e inferior de trechos vizinhos; está ligado na estrada. |
| `Seam Tolerance` | Tolerância dos avisos geométricos, inicialmente 0,25 px. Não altera o comprimento nem move os sprites. |
| `Show Editor Bounds` | Exibe contornos dos trechos e da faixa; espaços horizontais aparecem em vermelho. |

Os avisos indicam o nome do trecho e o tamanho da lacuna ou sobreposição, incluindo lacunas horizontais entre os retângulos de sprites dentro de um grupo. Rotação, inclinação e textura ausente também geram avisos. O sistema mantém a posição editada e informa o problema; não preenche espaços silenciosamente.

Os retângulos incluem as margens transparentes das texturas. Além disso, um grupo com várias peças pode ter espaços internos, e o retângulo de um sprite rotacionado pode conter áreas sem desenho. Por isso, limites corretos não comprovam que as cores, silhuetas ou marcações de duas artes encaixam. Confira visualmente as emendas, inclusive a passagem do último trecho para o primeiro. Para encaixes horizontais de estrada, prefira peças sem rotação e com bordas compatíveis.

## Cruzamentos, parada e retomada

`Esquina` fica sobre a estrada contínua em `EventosVisuais`, junto do sprite `Semáforo`. Essa composição acompanha o deslocamento da corrida uma vez e não retorna quando qualquer camada completa uma volta. O loop não emite eventos de progressão nem cria uma nova ocorrência do cruzamento.

A raiz conserva o grupo `esteira`, a propriedade `CAR_SPEED` e `get_scroll_speed()`, usados pelos sistemas existentes. Um controlador pode parar e retomar as camadas e os visuais de eventos por esta API:

```gdscript
$Esteira.set_scrolling_enabled(false)
# Ao retomar a corrida:
$Esteira.set_scrolling_enabled(true)
```

Zerar `CAR_SPEED` ou desativar o processamento de física da esteira também impede seu deslocamento. `get_scroll_speed()` retorna zero quando a esteira está parada, preservando a consulta dos power-ups. A retomada continua da posição atual; nenhuma faixa é reiniciada. Essa API controla o cenário e não substitui o controle próprio de carros, inimigos ou outros sistemas de uma batalha.

**Lacuna preexistente, verificada em 13/11/2026:** a cena `Level_1` não possui controlador de batalha, temporizador de parada ou spawner conectado. `Esquina` e `Semáforo` são sprites sem gatilhos. O script `level_1.gd` permanece desconectado e referencia recursos ausentes. A regra de 20 segundos de corrida seguidos de 60 segundos de combate continua confirmada no [GDD](GDD.md), mas não é um fluxo implementado ou validado por esta refatoração.

Eventos futuros de gameplay devem ficar fora das faixas repetíveis e conservar seu próprio estado. Não vincule a progressão da fase à posição modular de uma camada visual.

## Conteúdo permitido e reutilização

Dentro de uma camada, use somente `Node2D`, `Sprite2D` e `TextureRect` estáticos, sem scripts próprios. Corpos físicos, `Area2D`, temporizadores e outros tipos são identificados como incompatíveis: a camada avisa e não ativa a repetição. A opção `Top Level` também é recusada, pois ignora a transformação do grupo.

Para outra fase de corrida:

1. Crie uma raiz `Esteira` com `esteira.gd`.
2. Adicione filhos `Node2D` com `scenery_loop_layer.gd` para cada faixa visual independente e construa seus trechos no editor.
3. Mantenha a colisão do chão fixa e os objetos de gameplay fora das camadas. Se houver visuais que devam passar uma vez, coloque-os no filho `EventosVisuais`.
4. Preserve `Speed Multiplier = 1` para acompanhar a velocidade principal, ou configure outra relação somente quando o design da fase exigir.
5. Integre a API de parada ao controlador da fase e verifique as emendas e a transição para batalha.

O controlador reconhece suas camadas filhas ao iniciar; não depende dos nomes `Ceu`, `Predios` ou `Estrada`. O tutorial conserva seu script próprio e não foi convertido nesta entrega.

## Arquivos da refatoração

| Arquivo | Alteração |
| --- | --- |
| [scenery_loop_layer.gd](../Projeto/Scripts/scenery_loop_layer.gd) | Medição automática, repetição nativa, diagnósticos e encaixe no editor. |
| [esteira.gd](../Projeto/Scripts/esteira.gd) | Coordenação do deslocamento e API de parada, sem comprimento fixo nem movimento da raiz. |
| [Level_1.tscn](../Projeto/Scenes/Fases/Level_1.tscn) | Camadas visuais, composição encaixada e separação entre estrada, piso físico e cruzamento. |
| [scenery_loop_test.gd](../Projeto/Verification/scenery_loop_test.gd) | Verificações automatizadas de geometria e integração. |
| [GDD.md](GDD.md) | Registro do escopo técnico autorizado e da diferença entre regra de batalha e implementação atual. |

## Validação

O roteiro versionável está em `Projeto/Verification`, pois a pasta `Projeto/Tests` já é ignorada pelo repositório. Execute a partir da raiz:

```text
Godot --headless --path Projeto --script res://Verification/scenery_loop_test.gd
```

O teste cobre limites com dimensões, regiões, offsets, escalas negativas e grupos transformados; adição, remoção e reorganização; encaixe preservando alturas e ordem; identificação de conteúdo incompatível; várias voltas e passos grandes; fases menores que a janela; pausa e retomada; identidade dos nós de gameplay; chão fixo; e movimento próprio de 700 px/s dos carros.

**Resultado da execução em 13/11/2026:** 72 verificações aprovadas no Godot 4.7.1 em modo headless, incluindo 18.000 passos numa faixa de 44.325 px, com erro de fase inferior a 0,02 px, e parada/retomada do power-up real da cena preservando sua velocidade própria. A cobertura automatizada verifica geometria e estado dos nós, sem comprovar aparência nem uma sessão prática de colisões. A `Level_1` também carregou e executou por 180 passos em modo headless.

O motor registrou um erro preexistente ao ler os certificados do Windows. Os testes de conteúdo inválido produziram os avisos esperados. Na execução direta da cena, o áudio MP3 ativo também deixou um aviso de recurso em uso ao sair; a bateria desliga o autoplay antes de instanciar a fase e encerra sem esse aviso.

A regressão pelo roteiro local antigo `Projeto/Tests/power_ups_test.gd` foi tentada, mas interrompida: ele referencia `res://Scenes/Personagens/inimigo.tscn`, ausente no checkout atual. Esse impedimento é anterior à refatoração e não permite afirmar aprovação daquela bateria completa.

Permanecem para teste manual:

- Rodar por várias voltas de cada camada e inspecionar emendas, transparências, lacunas, sobreposições, tremores e marcações da estrada.
- Adicionar e remover artes reais de larguras diferentes no editor, reorganizar, usar encaixe e desfazer/refazer, salvar e executar novamente.
- Parar e retomar a esteira antes, durante e depois da passagem do cruzamento; conferir todas as alturas e a ordem visual.
- Jogar as interações com veículos: subir, andar, saltar, sair, colidir lateralmente e usar dash, verificando também dano e coleta de power-ups.
- Quando houver controlador de batalha conectado, testar a transição completa de corrida para combate e retorno, com seus gatilhos e spawns. Esse fluxo não existe na cena atual e não é comprovado pelo teste de pausa do cenário.
