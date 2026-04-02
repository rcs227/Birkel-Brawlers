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
	_clash_processed = false
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
	# --- Clash: two hitboxes met in the same frame ---
	if area is Hitbox:
		# Ignore our own hitboxes (e.g. multi-part attacks)
		if area.owner_player == owner_player:
			return

		# Only process a clash once — whichever signal fires second skips out
		if _clash_processed or area._clash_processed:
			return

		# A clash only happens when the two hitboxes point INTO each other.
		# If they share the same hit_direction (e.g. a backwards kick vs a
		# forward punch both pointing left), there's no clash — fall through
		# so the hit logic can handle it instead.
		if hit_direction == area.hit_direction:
			return

		_clash_processed = true
		area._clash_processed = true
		call_deferred("disable")
		area.call_deferred("disable")
		owner_player.state_machine.transition_to("Idle")
		area.owner_player.state_machine.transition_to("Idle")
		owner_player.play_sfx(Player.parry_sound)
		return
	
	
	# --- Hit: this hitbox entered the target's hurtbox or body ---
	if area is not Hitbox and target is Player and target != owner_player:
		var attack_state := owner_player.state_machine.get_node("Attack") as AttackState
		var atk := attack_state.current_attack
		if atk == null:
			return

		# Can't hit a dead player
		if target.state_machine.current_state == target.state_machine.get_node("Dead"):
			return

		# Guard against the simultaneous hitbox+hurtbox overlap edge case.
		# If the two hitboxes are pointing toward each other AND the target's
		# hitbox is already overlapping us this frame, the clash path owns it —
		# the hitbox signal will fire (or already fired) and handle the cancel.
		# We only skip here when the directions oppose; same-direction hits
		# (cross-ups, backwards kicks) should always land.
		if hit_direction != target.hitbox.hit_direction:
			for overlapping in get_overlapping_areas():
				if overlapping is Hitbox and overlapping.owner_player == target:
					return

		call_deferred("disable")

		var dir := owner_player.facing
		var kb  := Vector2(atk.knockback.x * dir, atk.knockback.y)

		# Grab handling — skip normal hit/block logic entirely
		if atk.is_grab:
			owner_player.grab_target = target
			attack_state.on_grab_hit()
			if atk.on_hit_sound != null:
				owner_player.play_sfx(atk.on_hit_sound)
			owner_player.grab_landed.emit(owner_player)
			target.apply_grab(owner_player, atk)
			return

		# Block handling — reduced damage, no stun, push back attacker
		if target.state_machine.current_state == target.state_machine.get_node("Block"):
			owner_player.apply_hit_stop(atk.hit_stop, false, true)
			target.take_block_damage(atk.damage, kb.x, owner_player)
			return

		# Normal hit
		owner_player.apply_hit_stop(atk.hit_stop)
		if atk.on_hit_sound != null:
			owner_player.play_sfx(atk.on_hit_sound)
		owner_player.anim_player.speed_scale = owner_player.hit_speed_multiplier
		target.apply_hit(atk.damage, kb, atk.stun_duration, atk.hit_stop)
