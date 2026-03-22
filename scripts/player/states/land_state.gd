# land_state.gd
class_name LandState
extends State

func enter() -> void:
	player.safe_play("land")

func physics_process(delta: float) -> String:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	return ""

# No input handled — player is committed to the landing animation
# _on_animation_finished transitions back to Idle automatically
