class_name AttackState
extends State

# Set this before transitioning so enter() knows which attack to play
var current_attack: Attack

func enter() -> void:
	player.deactivate_hitbox()
	player.anim_player.stop()
	if current_attack.sound_effect != null:
		SoundManager.play_sfx(current_attack.sound_effect)
	player.play_attack(current_attack.animation)

func physics_process(delta: float) -> String:
	# Locked out of everything — just apply gravity if airborne
	player.update_block_regen(delta)
	if not player.is_on_floor():
		player.apply_horizontal(delta)
		player.apply_gravity(delta)
	else:
		player.apply_friction(delta)
	player.move_and_slide()
	return ""

# No input handled — attack is committed until animation ends
# _on_animation_finished in player.gd transitions back to Idle
