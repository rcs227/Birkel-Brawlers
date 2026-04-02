class_name FallState
extends State

func enter() -> void:
	player.safe_play("fall")

func physics_process(delta: float) -> String:
	player.apply_horizontal(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	player.update_block_regen(delta)
	if player.is_on_floor():
		player.has_flip = true
		return "Land"
	if player.block_held and not player.is_block_broken and player.block_timer >= player.block_cooldown:
		return "Block"
	return ""

func input(event: InputEvent) -> String:
	if event.is_action_pressed("jump") and player.has_flip:
		player.has_flip = false
		return "Jump"
	if event.is_action_pressed("dash") and player.dash_timer >= player.dash_cooldown:
		return "Dash"
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
