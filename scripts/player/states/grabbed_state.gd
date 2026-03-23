class_name GrabbedState
extends State

var damage: float
var knockback: Vector2
var stun_duration: float
var target_position: Vector2
var travel_duration: float
var travel_timer: float = 0.0
var start_position: Vector2
var is_traveling: bool = false

func enter() -> void:
	player.safe_play("grabbed")

func start_travel(world_target: Vector2, duration: float) -> void:
	start_position = player.global_position
	target_position = world_target
	travel_duration = duration
	travel_timer = 0.0
	is_traveling = true

func physics_process(delta: float) -> String:
	if is_traveling and travel_timer < travel_duration:
		travel_timer += delta
		var t := clampf(travel_timer / travel_duration, 0.0, 1.0)
		player.global_position = start_position.lerp(target_position, t)
		if t >= 1.0:
			is_traveling = false
	else:
		player.velocity = Vector2.ZERO
	player.move_and_slide()
	return ""
