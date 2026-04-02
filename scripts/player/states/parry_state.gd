# the state where the player successfully hits a parry
class_name ParryState
extends State

func enter() -> void:
	player.play_sfx(Player.parry_sound)
	player.safe_play("parry")
	player.parry_cooldown_timer = player.parry_cooldown

func physics_process(delta: float) -> String:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.update_block_regen(delta)
	player.move_and_slide()
	return ""
