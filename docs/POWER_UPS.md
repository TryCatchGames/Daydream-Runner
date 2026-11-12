# Power-ups reutilizáveis

Arraste uma destas cenas para a fase, como filha da raiz e irmã da esteira:

| Cena | Efeito | Parâmetros |
| --- | --- | --- |
| [DoublePoints.tscn](../Projeto/Scenes/PowerUps/DoublePoints.tscn) | Dobra a fonte `enemy_defeated` no `ScoreSystem` existente. | `Duration`: 10 segundos. |
| [ExtraHeart.tscn](../Projeto/Scenes/PowerUps/ExtraHeart.tscn) | Cura 2 pontos, até a capacidade atual. Se já estiver cheia, concede um coração extra. | No jogador, selecione `PowerUps`: `Max Extra Hearts` começa em 3. |
| [Invincibility.tscn](../Projeto/Scenes/PowerUps/Invincibility.tscn) | Bloqueia dano e derrota inimigos comuns por contato, usando a morte e a pontuação existentes. Exibe uma aura vermelha. | `Duration`: 10 segundos. |

As três herdam [PowerUp.tscn](../Projeto/Scenes/PowerUps/PowerUp.tscn). No nó raiz, `Float Amplitude` regula a distância vertical em pixels; `Float Speed`, a frequência angular em radianos por segundo; `Scroll Speed`, o deslocamento horizontal em pixels por segundo (400 inicialmente). Os sprites existentes são reduzidos para aproximadamente 50 × 50 pixels. A coleta usa `Area2D`, exige um jogador vivo e possui trava contra chamadas repetidas.

## Vida, duração e HUD

Os efeitos pertencem ao nó `PowerUps` da cena existente do jogador, também herdado pelo tutorial. Double Points e Invencibilidade têm contadores independentes; recoletar substitui o tempo restante pela duração da nova coleta. A pausa da árvore também pausa os efeitos. O HUD mostra os tempos restantes.

A constante `MAX_HEALTH` permanece em 6. A vida atual pode excedê-la em até 6 pontos por padrão. O HUD mantém um extra pela metade e remove o coração quando ele é totalmente consumido; os três corações padrão continuam mostrando também os estados vazios. Cura parcial não transborda para outro coração. Recolher vida com todos os extras cheios consome o item sem aumentar a vida. Corações extras não expiram por tempo.

A invencibilidade não altera máscaras de colisão, movimentação nem material do sprite; a aura é desenhada separadamente e desaparece ao expirar. O dano volta a funcionar pelo caminho habitual. A derrota por contato utiliza `inimigo.gd`, cuja proteção contra pontuação repetida é preservada. Chefes continuam com as regras próprias já existentes no GDD.

## Detecção da fase e ciclo de vida

O movimento consulta o grupo `esteira` a cada passo de física. Uma esteira processando e com `get_scroll_speed() > 0` indica corrida; sem esteira ou com ela parada, os itens apenas flutuam. `esteira.gd` e `esteiraTutorial.gd` expõem essa consulta. Instancie os itens fora da esteira para evitar somar o movimento do pai ao deles.

Morrer ou remover o jogador da árvore limpa os efeitos e os extras. Recarregar/trocar a cena cria contadores zerados. Se um controlador encerrar ou reiniciar a fase **mantendo o mesmo jogador na árvore**, deve chamar:

```gdscript
$Player/PowerUps.clear_effects()
```

Essa chamada não restaura a vida perdida nem zera o score. Para reinício completo, prefira recarregar a cena; `ScoreSystem.reset()` continua sendo apenas uma operação de pontuação.

**Estado verificado em 12/11/2026:** `Level_1` não possui controlador de conclusão nem semáforo ativo. O script antigo `level_1.gd` está desconectado e referencia recursos ausentes. Esta entrega fornece as cenas prontas para posicionamento/instanciação, sem ligar esse controlador antigo ou adicionar geração aleatória. A cena de teste `FaseBatalha` usa o mesmo jogador e HUD e aceita os mesmos itens.

## Validação

O roteiro local foi executado com Godot 4.7.1. A pasta `Projeto/Tests` já é ignorada pelo `.gitignore` do projeto; o roteiro permanece disponível neste workspace, sem alterar essa configuração:

```text
Godot --headless --path Projeto --script res://Tests/power_ups_test.gd
```

O teste usa cenas reais e cobre cura, limite de extras, dano atravessando extras, estados do HUD, coleta física, repetição de coleta, temporizadores independentes, invencibilidade, derrota por contato, pontuação, expiração, limpeza e carregamento das cenas de corrida e batalha. Também verifica o jogador com o script do tutorial. A cena completa do tutorial apresenta avisos preexistentes de `VisibleOnScreenNotifier2D` ausente nos carros; essa cena não integra o teste automatizado dos efeitos.
