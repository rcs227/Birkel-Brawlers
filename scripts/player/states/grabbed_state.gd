class_name GrabbedState
extends State

var damage: float
var knockback: Vector2
var stun_duration: float

func enter() -> void:
	player.safe_play("grabbed")

func physics_process(delta: float) -> String:
	# Lock the grabbed player in place
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	return ""
