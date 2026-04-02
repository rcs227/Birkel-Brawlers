# the state where the player successfully hits a parry
class_name ParryState
extends State

func enter() -> void:
	player.anim_player.speed_scale = 1.0
	player.anim_sprite.speed_scale = 1.0
	SoundManager.play_sfx("chirp")
	player.safe_play("parry")

func physics_process(delta: float) -> String:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.update_block_regen(delta)
	player.move_and_slide()
	return ""
