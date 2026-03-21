class_name CrouchState
extends State

func enter() -> void:
	player.safe_play("crouch")

func physics_process(delta: float) -> String:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	if not player.is_on_floor():
		return "Fall"
	return ""

func input(event: InputEvent) -> String:
	if event.is_action_pressed("jump"):
		return "Jump"
	return ""

func process(_delta: float) -> String:
	# Stop crouching if stick is released or moved horizontally
	if player.get_stick_y() < player.CROUCH_THRESHOLD:
		return "Idle"
	if player.get_stick_x() != 0.0:
		return "Walk"
	return ""
