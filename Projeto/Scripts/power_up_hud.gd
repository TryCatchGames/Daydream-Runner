extends Label

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var effects := player.get_node_or_null("PowerUps") as PlayerPowerUps if player != null else null
	var lines := PackedStringArray()
	if effects != null:
		if effects.double_points_remaining > 0.0:
			lines.append("PONTOS x2  %ds" % ceili(effects.double_points_remaining))
		if effects.is_invincible():
			lines.append("INVENCÍVEL  %ds" % ceili(effects.invincibility_remaining))
	text = "\n".join(lines)
