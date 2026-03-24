class_name ParryState
extends State

func enter() -> void:
	SoundManager.play_sfx("chirp")
	player.safe_play("parry")

func physics_process(delta: float) -> String:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.update_block_regen(delta)
	player.move_and_slide()
	return ""
