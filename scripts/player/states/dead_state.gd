class_name DeadState
extends State

func enter() -> void:
	SoundManager.play_sfx(player.death_sound)
	player.safe_play("death")
	# queue_free is called after the death animation
	# via _on_animation_finished in player.gd
