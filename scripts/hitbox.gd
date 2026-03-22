# the box that deals hits to players
class_name Hitbox
extends Area2D

@onready var collision := get_node("CollisionShape2D") as CollisionShape2D

@onready var owner_player: Player = owner

func _ready():
	print("hitbox owner: ", owner_player)
	print("hitbox layer: ", collision_layer)
	print("hitbox mask: ", collision_mask)
	collision.shape = collision.shape.duplicate()
	area_entered.connect(_on_area_entered)

func enable(size: Vector2, offset: Vector2) -> void:
	(collision.shape as RectangleShape2D).size = size
	collision.position = offset
	collision.disabled = false
	monitoring = true

func disable() -> void:
	collision.disabled = true
	monitoring = false

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() == owner_player:
		return
	var target := area.get_parent()
	if not target is Player:
		return
	print("hitting " + target.name)
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
