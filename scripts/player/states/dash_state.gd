class_name DashState
extends State

func enter() -> void:
	player.safe_play("dash")
	# Apply impulse in facing direction
	player.velocity.x = player.dash_force * player.facing
	player.velocity.y = player.dash_up_force

func physics_process(delta: float) -> String:
	# Let physics take over — just apply gravity and friction naturally
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	player.move_and_slide()
	if player.is_on_floor():
		return "Idle"
	if player.velocity.y > 0.0:
		return "Fall"
	return ""

func input(event: InputEvent) -> String:
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

func exit() -> void:
	player.dash_timer = 0.0
