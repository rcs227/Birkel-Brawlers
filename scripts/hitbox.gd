# the box that deals hits to players
class_name Hitbox
extends Area2D

@onready var collision := get_node("CollisionShape2D") as CollisionShape2D
@onready var owner_player: Player = owner as Player

var _is_active: bool = false
var is_grab_active: bool = false


func _ready() -> void:
	collision.shape = collision.shape.duplicate()
	area_entered.connect(_on_area_entered)
	SettingsManager.hitbox_debug_toggled.connect(_on_debug_toggled)
	# Draw on top of character sprites.
	z_index = 10


func _process(_delta: float) -> void:
	# Continuously redraw so the rect tracks the collision shape every frame.
	if SettingsManager.show_hitboxes:
		queue_redraw()


func enable(atk: Attack, i: int = 0) -> void:
	#print(owner_player.name + " hitbox enabled")
	set_hitbox_specs(atk, i)
	collision.disabled = false
	monitoring = true
	_is_active = true
	queue_redraw()

func set_hitbox_specs(atk: Attack, i: int) -> void:
	var spec = atk.hitbox_frames[i] as HitboxSpecs
	if spec.change_size:
		var size = spec.size
		(collision.shape as RectangleShape2D).size = size
	if spec.change_offset:
		var offset = Vector2(atk.hitbox_frames[i].offset.x * owner_player.facing, (atk.hitbox_frames[i] as HitboxSpecs).offset.y)
		collision.position = offset


func disable() -> void:
	#print(owner_player.name + " hitbox disabled")
	collision.disabled = true
	monitoring = false
	_is_active = false
	queue_redraw()


func _draw() -> void:
	if not SettingsManager.show_hitboxes or not _is_active:
		return
	if collision == null or not collision.shape is RectangleShape2D:
		return
	var shape := collision.shape as RectangleShape2D
	var rect  := Rect2(collision.position - shape.size * 0.5, shape.size)
	draw_rect(rect, Color(1.0, 0.1, 0.1, 0.28))            # filled tint
	draw_rect(rect, Color(1.0, 0.25, 0.25, 1.0), false, 1) # solid outline


func _on_debug_toggled(_show: bool) -> void:
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() == owner_player:
		return
	var target := area.get_parent()
	if not target is Player:
		return
	var attack_state := owner_player.state_machine.get_node("Attack") as AttackState
	var atk := attack_state.current_attack
	if atk == null:
		return
	
	# check block or death
	if target.state_machine.current_state == target.state_machine.get_node("Dead"):
		return
	
	call_deferred("disable")
	
	var dir := owner_player.facing
	var kb := Vector2(atk.knockback.x * dir, atk.knockback.y)
	
	if atk.is_grab:
		owner_player.grab_target = target
		attack_state.on_grab_hit()
		if atk.on_hit_sound != null:
			SoundManager.play_bgs(atk.on_hit_sound)
		target.apply_grab(owner_player, atk)
		return
	
	if target.state_machine.current_state == target.state_machine.get_node("Block"):
		owner_player.anim_player.speed_scale = owner_player.hit_speed_multiplier
		target.take_block_damage(atk.damage, owner_player)
		return
	
	owner_player.apply_hit_stop(atk.hit_stop)
	if atk.on_hit_sound != null:
		SoundManager.play_sfx(atk.on_hit_sound)
	owner_player.anim_player.speed_scale = owner_player.hit_speed_multiplier
	target.apply_hit(atk.damage, kb, atk.stun_duration, atk.hit_stop)
