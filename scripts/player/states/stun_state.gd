class_name StunState
extends State

var duration := 0.0
var timer    := 0.0

func enter() -> void:
	player.anim_player.speed_scale = 1.0
	player.anim_sprite.speed_scale = 1.0
	timer = duration
	player.safe_play("stun")

func physics_process(delta: float) -> String:
	timer -= delta
	player.velocity = player.knockback
	player.knockback = player.knockback.move_toward(Vector2.ZERO, player.friction * delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	player.update_block_regen(delta)
	if timer <= 0.0:
		return "Idle"
	return ""

# No input handled while stunned
