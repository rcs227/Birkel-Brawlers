class_name CrouchState
extends State

func enter() -> void:
	player.anim_player.speed_scale = 1.0
	player.anim_sprite.speed_scale = 1.0
	player.safe_play("crouch")
	player.set_crouch_hurtbox()

func exit() -> void:
	player.reset_hurtbox()

func physics_process(delta: float) -> String:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.update_block_regen(delta)
	player.move_and_slide()
	if not player.is_on_floor():
		return "Fall"
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
	# Stop crouching if stick is released
	if player.get_stick_y() < player.CROUCH_THRESHOLD:
		return "Idle"
	return ""
