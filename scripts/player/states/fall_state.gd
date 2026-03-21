class_name FallState
extends State

func enter() -> void:
	player.safe_play("fall")

func physics_process(delta: float) -> String:
	player.apply_horizontal(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	if player.is_on_floor():
		player.has_flip = true
		return "Idle"
	return ""

func input(event: InputEvent) -> String:
	if event.is_action_pressed("jump") and player.has_flip:
		player.has_flip = false
		return "Jump"
	if event.is_action_pressed("light_attack") or \
	   event.is_action_pressed("medium_attack") or \
	   event.is_action_pressed("heavy_attack"):
		return "Attack"
	return ""
