class_name BlockState
extends State

func enter() -> void:
	player.safe_play("block")

func physics_process(delta: float) -> String:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	if not player.block_held:
		if not player.is_on_floor():
			return "Fall"
		else:
			return "Idle"
	return ""

# No attacking, jumping, or moving while blocking
