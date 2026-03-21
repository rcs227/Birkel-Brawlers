# the box that deals hits to players
class_name Hitbox
extends Area2D

@onready var collision := get_node("CollisionShape2D") as CollisionShape2D

var owner_player: Player

func enable(size: Vector2, offset: Vector2) -> void:
	(collision.shape as RectangleShape2D).size = size
	collision.position = offset
	collision.disabled = false
	monitoring = true
	print("hitbox enabled!")

func disable() -> void:
	collision.disabled = true
	monitoring = false
	print("hitbox disabled!")

func _on_area_entered(area: Area2D) -> void:
	# Ignore if it's our own hurtbox
	if area.get_parent() == owner_player:
		return
	var target := area.get_parent()
	if not target is Player:
		return
	var attack_state := owner_player.state_machine.get_node("Attack") as AttackState
	var atk := attack_state.current_attack
	if atk == null:
		return
	# Flip knockback if target is to the left
	var dir := signf(target.global_position.x - owner_player.global_position.x)
	var kb := Vector2(atk.knockback.x * dir, atk.knockback.y)
	target.damage_player(atk.damage)
	target.apply_knockback(kb)
	target.apply_stun(atk.stun_duration)
