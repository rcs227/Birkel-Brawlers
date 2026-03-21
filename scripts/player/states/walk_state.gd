class_name WalkState
extends State

func enter() -> void:
	player.safe_play("walk")

func physics_process(delta: float) -> String:
	player.apply_horizontal(delta)
	player.apply_gravity(delta)
	if not player.is_on_floor():
		return "Fall"
	if player.block_held:
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
	return ""
 
func _queue_attack(action: String) -> void:
	var attack_state := player.state_machine.get_node("Attack") as AttackState
	attack_state.current_attack = player.get_attack(action)

func process(_delta: float) -> String:
	if player.get_stick_x() == 0.0:
		return "Idle"
	if player.get_stick_y() > player.CROUCH_THRESHOLD and player.is_on_floor():
		return "Crouch"
	return ""
