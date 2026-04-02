# the box that deals hits to players
class_name Hitbox
extends Area2D

@onready var collision := get_node("CollisionShape2D") as CollisionShape2D
@onready var owner_player: Player = owner as Player

var _clash_processed: bool = false
var _is_active: bool = false
var is_grab_active: bool = false

var hit_direction: int = 1 # world-space direction this hitbox is pointing


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
	_clash_processed = false
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
	
	if collision.position.x != 0:
		hit_direction = sign(collision.position.x)
	else:
		hit_direction = owner_player.facing


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
	var target := area.get_parent()
	if target == owner_player:
		return

	# 1. DIRECT HITBOX CLASH (Hitbox touches Hitbox)
	if area is Hitbox:
		if _clash_processed or area._clash_processed:
			return
		
		if hit_direction != area.hit_direction:
			_trigger_clash(area)
		return

	# 2. POTENTIAL INDIRECT CLASH (Hitbox touches Hurtbox)
	if target is Player:
		var opponent_hitbox = target.hitbox 
		
		# If their hitbox is out and facing us, it's a clash, even if the boxes didn't touch yet
		if opponent_hitbox._is_active and opponent_hitbox.hit_direction != hit_direction:
			_trigger_clash(opponent_hitbox)
		else:
			# Normal hit: defer to ensure all area signals are checked
			call_deferred("_process_hit", area)


func _trigger_clash(other: Hitbox) -> void:
	if _clash_processed or other._clash_processed:
		return
		
	_clash_processed = true
	other._clash_processed = true
	
	call_deferred("disable")
	other.call_deferred("disable")
	
	owner_player.state_machine.transition_to("Idle")
	other.owner_player.state_machine.transition_to("Idle")
	
	owner_player.play_sfx(Player.parry_sound)


func _process_hit(area: Area2D) -> void:
	var target := area.get_parent()

	# A clash was resolved this frame — suppress the hit entirely
	if _clash_processed:
		return

	var attack_state := owner_player.state_machine.get_node("Attack") as AttackState
	var atk := attack_state.current_attack
	if atk == null:
		return

	if target.state_machine.current_state == target.state_machine.get_node("Dead"):
		return

	# Secondary guard: if their hitbox is still active and pointing at us, let
	# the clash handle it. Covers the case where hitboxes didn't directly overlap
	# but both hit the other's hurtbox.
	if hit_direction != target.hitbox.hit_direction:
		for overlapping in get_overlapping_areas():
			if overlapping is Hitbox and overlapping.owner_player == target:
				return

	call_deferred("disable")

	var dir := owner_player.facing
	var kb  := Vector2(atk.knockback.x * dir, atk.knockback.y)

	if atk.is_grab:
		owner_player.grab_target = target
		attack_state.on_grab_hit()
		if atk.on_hit_sound != null:
			owner_player.play_sfx(atk.on_hit_sound)
		owner_player.grab_landed.emit(owner_player)
		target.apply_grab(owner_player, atk)
		return

	if target.state_machine.current_state == target.state_machine.get_node("Block"):
		owner_player.apply_hit_stop(atk.hit_stop, false, true)
		target.take_block_damage(atk.damage, kb.x, owner_player)
		return

	owner_player.apply_hit_stop(atk.hit_stop)
	if atk.on_hit_sound != null:
		owner_player.play_sfx(atk.on_hit_sound)
	owner_player.anim_player.speed_scale = owner_player.hit_speed_multiplier
	target.apply_hit(atk.damage, kb, atk.stun_duration, atk.hit_stop)
