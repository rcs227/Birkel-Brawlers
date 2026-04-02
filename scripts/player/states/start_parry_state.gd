# the state where the player attempts a parry
class_name StartParryState
extends State

func enter() -> void:
	player.safe_play("start_parry")
	player.parry_timer = 0.0

func exit() -> void:
	player.parry_cooldown_timer = 0.0

func physics_process(delta: float) -> String:
	player.velocity.x = player.knockback.x
	player.knockback = player.knockback.move_toward(Vector2.ZERO, player.friction * delta)
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	return ""

func process(delta: float) -> String:
	player.parry_timer += delta
	return ""
