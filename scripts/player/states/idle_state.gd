class_name IdleState
extends State

func enter() -> void:
	player.safe_play("default")

func physics_process(delta: float) -> String:
	player.apply_friction(delta)
	if not player.is_on_floor():
		return "Fall"
	if player.block_held:
		return "Block"
	player.apply_gravity(delta)
	player.move_and_slide()
	return ""

func input(event: InputEvent) -> String:
	if event.is_action_pressed("jump"):
		return "Jump"
	if event.is_action_pressed("light_attack") or event.is_action_pressed("medium_attack") or event.is_action_pressed("heavy_attack"):
		return "Attack"
	return ""

func process(_delta: float) -> String:
	if player.get_stick_x() != 0.0:
		return "Walk"
	return ""
