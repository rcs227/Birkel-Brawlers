class_name StunState
extends State

var duration := 0.0
var timer    := 0.0

func enter() -> void:
	timer = duration
	player.safe_play("stun")

func physics_process(delta: float) -> String:
	timer -= delta
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	if timer <= 0.0:
		return "Idle"
	return ""

# No input handled while stunned
