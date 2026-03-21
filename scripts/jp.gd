extends Player
func medium_attack():
	if special_held:
		safe_play("special_medium")
func light_attack():
	safe_play("light_attack")
