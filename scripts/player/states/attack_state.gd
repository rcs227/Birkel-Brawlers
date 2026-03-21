class_name AttackState
extends State

# Set this before transitioning so enter() knows which attack to play
var current_attack: Attack

func enter() -> void:
	player.safe_play(current_attack.animation)

func physics_process(delta: float) -> String:
	# Locked out of everything — just apply gravity if airborne
	if not player.is_on_floor():
		player.apply_gravity(delta)
	player.apply_friction(delta)
	player.move_and_slide()
	return ""

# No input handled — attack is committed until animation ends
# _on_animation_finished in player.gd transitions back to Idle
