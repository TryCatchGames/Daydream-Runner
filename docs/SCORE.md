# Sistema de score

Na cena [hud.tscn](../Projeto/Scenes/Menus/hud.tscn), selecione **ScoreSystem**:

- `Max Score`: teto padrão 99999. O total começa em zero e nunca ultrapassa esse teto. Reduzir o teto também limita o total atual.
- `Sources`: lista de recursos `ScoreSource`. Cada entrada possui `Id` único, `Enabled` e `Points`. Para criar outra fonte, adicione um recurso e preencha esses campos. Desmarcar `Enabled` ou remover a entrada impede novos ganhos dessa origem sem alterar seus emissores.
- A fonte `enemy_defeated` já recebe as mortes de `inimigo.gd`, uma vez por inimigo. Os 100 pontos iniciais são um ajuste provisório. As cenas que compartilham o HUD também exibem o painel.

## Integrar outro evento

Adicione, por exemplo, a fonte `meu_evento` no Inspector e chame uma vez quando o evento ocorrer:

```gdscript
var score := get_tree().get_first_node_in_group("score_system") as ScoreSystem
if score != null:
    var ganho_real := score.award(&"meu_evento")
```

`award(id, valor)` permite informar um valor calculado (por exemplo, pontos por tipo de alvo). A fonte ainda precisa existir e estar habilitada. A chamada retorna o ganho efetivo após aplicar o teto. Valores negativos, exceto o sentinela padrão `-1` que usa `Points`, não concedem pontos. Use IDs únicos: a primeira entrada correspondente é usada. A prevenção de eventos repetidos pertence ao emissor; o inimigo comum já faz essa proteção.

```gdscript
score.set_source_enabled(&"enemy_defeated", false)
score.set_source_enabled(&"enemy_defeated", true)
```

Essas alterações em execução não modificam os recursos compartilhados nem subtraem pontos anteriores.

O [Double Points](POWER_UPS.md) multiplica somente `enemy_defeated` por 2, antes de aplicar o teto. O multiplicador também vale para valores informados em `award(id, valor)`, sem alterar `ScoreSource.Points`. A derrota por contato durante a invencibilidade passa pelo mesmo caminho de pontuação; fontes desativadas continuam sem conceder pontos.

## Consultar e exportar

```gdscript
var total: int = score.get_score()
var dados: Dictionary = score.export_score() # {"score": 0, "max_score": 99999}
var json: String = JSON.stringify(dados)
score.score_changed.connect(_on_score_changed) # total, maximum
score.points_awarded.connect(_on_points_awarded) # source_id, amount, total
score.reset()
```

O dicionário é uma cópia independente. Leia/exporte antes de trocar a cena, pois o estado é local à fase. Não há gravação automática em disco. `reset()` zera apenas o total, preservando as fontes e suas opções em execução. Recriar a cena restaura a configuração do Inspector.

O painel usa a fonte existente `PressStart2P-Regular.ttf`, atualiza por sinal e pisca brevemente ao ganhar pontos. O número de dígitos acompanha limites maiores (mínimo de cinco posições), reduzindo a fonte para caber.

## Arte

Sprite: [score_panel.png](../Projeto/Sprites/HUD/score_panel.png), gerado pela ferramenta integrada imagegen. Os números são desenhados pelo Godot, não fazem parte da imagem. Prompt utilizado:

> Use case: stylized-concept. Asset type: transparent game HUD sprite for Daydream Runner. Create a single horizontal 16-bit pixel-art score panel, aspect ratio 3:1, tightly framed with tiny transparent margin. Dark navy interior, crisp stepped pixel borders in warm cream and bright red, playful colorful arcade ninja aesthetic. Small pixel lettering "SCORE" centered in the upper quarter. Lower two thirds must be completely empty dark navy space for runtime digits overlaid by the game. No numbers, no icons, no characters, no additional words, no glow or blurred edges. Flat front view, true transparent background outside panel. Pixel-art limited palette.
