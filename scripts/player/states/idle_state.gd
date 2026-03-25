class_name IdleState
extends State

func enter() -> void:
	player.safe_play("idle")

func physics_process(delta: float) -> String:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.update_block_regen(delta)
	if not player.is_on_floor():
		return "Fall"
	if player.block_held and not player.is_block_broken and player.block_timer >= player.block_cooldown:
		return "Block"
	player.move_and_slide()
	return ""

func input(event: InputEvent) -> String:
	if event.is_action_pressed("jump"):
		return "Jump"
	if event.is_action_pressed("light_attack"):
		_queue_attack("light_attack")
		return "Attack"
	if event.is_action_pressed("medium_attack"):
		_queue_attack("medium_attack")
		return "Attack"
	if event.is_action_pressed("heavy_attack"):
		_queue_attack("heavy_attack")
		return "Attack"
	if event.is_action_pressed("grab"):
		_queue_attack("grab")
		return "Attack"
	return ""
 
func _queue_attack(action: String) -> void:
	var attack_state := player.state_machine.get_node("Attack") as AttackState
	attack_state.current_attack = player.get_attack(action)

func process(_delta: float) -> String:
	if player.get_stick_y() > player.CROUCH_THRESHOLD and player.is_on_floor():
		return "Crouch"
	if player.get_stick_x() != 0.0:
		return "Walk"
	return ""
