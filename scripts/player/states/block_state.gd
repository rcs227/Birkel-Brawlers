class_name BlockState
extends State

func enter() -> void:
	player.safe_play("block")
	player.block_health -= player.block_cost
	player.start_block()

func exit() -> void:
	player.end_block()

func physics_process(delta: float) -> String:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	player.update_block_health(delta)
	if player.is_block_broken:
		return ""
	if not player.block_held:
		if not player.is_on_floor():
			return "Fall"
		return "Idle"
	return ""

# No attacking, jumping, or moving while blocking
