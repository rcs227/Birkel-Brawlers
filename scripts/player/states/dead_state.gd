class_name DeadState
extends State

func enter() -> void:
	SoundManager.play_sfx(player.death_sound)
	player.safe_play("death")
	# queue_free is called after the death animation
	# via _on_animation_finished in player.gd


func exit() -> void:
	player.anim_sprite.stop()
	player.anim_player.stop()

func physics_process(delta: float) -> String:
	player.apply_gravity(delta)
	player.apply_friction(delta)
	player.move_and_slide()
	return ""
