class_name JumpState
extends State
 
func enter() -> void:
	player.safe_play("jump")
	player.velocity.y = player.jump_force
 
func physics_process(delta: float) -> String:
	player.apply_horizontal(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	player.update_block_regen(delta)
	if player.velocity.y > 0.0:
		return "Fall"
	if player.block_held and not player.is_block_broken:
		return "Block"
	return ""
 
func input(event: InputEvent) -> String:
	if event.is_action_pressed("jump") and player.has_flip:
		player.velocity.y = player.jump_force
		player.has_flip = false
	if event.is_action_pressed("light_attack"):
		_queue_attack("light_attack")
		return "Attack"
	if event.is_action_pressed("medium_attack"):
		_queue_attack("medium_attack")
		return "Attack"
	if event.is_action_pressed("heavy_attack"):
		_queue_attack("heavy_attack")
		return "Attack"
	return ""
 
func _queue_attack(action: String) -> void:
	var attack_state := player.state_machine.get_node("Attack") as AttackState
	attack_state.current_attack = player.get_attack(action)
 
