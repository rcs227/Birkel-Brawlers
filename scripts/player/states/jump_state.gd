class_name JumpState
extends State
 
func enter() -> void:
	player.safe_play("jump")
	player.velocity.y = player.jump_force
	player.has_flip = true
 
func physics_process(delta: float) -> String:
	player.apply_horizontal(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	if player.velocity.y > 0.0:
		return "Fall"
	return ""
 
func input(event: InputEvent) -> String:
	if event.is_action_pressed("jump") and player.has_flip:
		player.velocity.y = player.jump_force
		player.has_flip = false
	if event.is_action_pressed("light_attack") or \
	   event.is_action_pressed("medium_attack") or \
	   event.is_action_pressed("heavy_attack"):
		return "Attack"
	return ""
 
