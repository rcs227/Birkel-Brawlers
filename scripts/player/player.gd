class_name Player
extends CharacterBody2D

# child nodes
@onready var anim_sprite = get_node("AnimatedSprite2D") as AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var state_machine: StateMachine = get_node("StateMachine")
@onready var hitbox: Hitbox = get_node("Hitbox")
@onready var hurtbox: CollisionShape2D = $Hurtbox/CollisionShape2D2

# constants
const STICK_DEADZONE := 0.8
const TRIGGER_THRESHOLD := 0.5
const CROUCH_THRESHOLD := .4


# exports

@export var device_id: int = 0 # assigned at game start

# MOVEMENT STATS
@export var speed := 150.0
@export var acceleration := 1000.0
@export var friction := 750.0
@export var jump_force := -225.0
@export var gravity := 600.0

var facing := 1.0

@export_group("UI")
@export var health_bar: ProgressBar

var original_hurtbox_size: Vector2
@export var crouch_size: Vector2
@export var crouch_offset: Vector2
var original_hurtbox_offset: Vector2

# --- State ---
var max_health := 100
var health := 100

var special_held := false
var block_held := false
var has_flip := true

var knockback := Vector2.ZERO

# Block stats
@export var max_block_health := 50
@export var block_drain_rate := 5.0        # per second while blocking
@export var block_regen_rate := 15        # per second when not blocking
@export var block_break_stun := 2.0         # stun duration on block break
@export var parry_window := 0.15            # seconds after starting block that counts as parry
@export var parry_stun_duration := 0.55      # stun applied to attacker on parry
@export var block_cost := 1.5                 # the amount it costs to block each time

var block_health := 0.0
var is_block_broken := false                # prevents re-blocking until trigger released
var parry_timer := 0.0                      # counts down from parry_window on block start
var block_regen_timer := 0.0               # delay before regen starts
@export var block_regen_delay := 1.5        # seconds before regen kicks in

@onready var block_bar: ProgressBar = get_node("BlockBar")

# Sounds
@export var hurt_sound: StringName

func _ready():
	hurtbox.shape = hurtbox.shape.duplicate()
	original_hurtbox_size = (hurtbox.shape as RectangleShape2D).size
	original_hurtbox_offset = hurtbox.position
	block_health = max_block_health
	block_bar.max_value = max_block_health
	block_bar.value = block_health
	anim_sprite.animation_finished.connect(_on_animation_finished)
	hitbox.owner_player = self
	hitbox.disable()
	health_bar.value = health
	state_machine.init(state_machine.get_node("Idle"))

func _process(delta: float) -> void:
	state_machine.process(delta)

func _physics_process(delta: float) -> void:
	# always read axes so any state can access them
	special_held = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT) > TRIGGER_THRESHOLD
	block_held   = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_THRESHOLD
	state_machine.physics_process(delta)
	if is_on_floor():
		has_flip = true

func _input(event: InputEvent) -> void:
	if event.device != device_id:
		return
	state_machine.input(event)


# ----- Helpers for States -------

func get_stick_x() -> float:
	var raw := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	return 0.0 if abs(raw) < STICK_DEADZONE else raw
 
func get_stick_y() -> float:
	return Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)

func apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta

func apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func apply_horizontal(delta: float) -> void:
	var raw := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var dir := 0.0 if abs(raw) < STICK_DEADZONE else raw
	if dir != 0.0:
		facing = sign(dir)
		anim_sprite.flip_h = dir < 0.0
	velocity.x = move_toward(velocity.x, dir * speed, acceleration * delta)

func apply_stun(duration: float):
	state_machine.get_node("Stun").duration = duration
	state_machine.transition_to("Stun")
	
func apply_knockback(force: Vector2):
	knockback = force

func damage_player(amount: float):
	SoundManager.play_sfx(hurt_sound)
	health -= amount
	health_bar.value = health
	if health <= 0:
		state_machine.transition_to("Dead")

# --- Animation ---

# safely checks if an animation exists
func safe_play(anim: StringName) -> void:
	if anim_sprite.sprite_frames.has_animation(anim):
		anim_sprite.play(anim)
	else:
		push_error("Animation not found: " + anim)

func play_attack(anim: StringName) -> void:
	anim_sprite.play(anim)
	if anim_player.has_animation(anim):
		anim_player.play(anim)

func _on_animation_finished() -> void:
	if state_machine.current_state == state_machine.get_node("Dead"):
		queue_free()
	elif not is_on_floor():
		state_machine.transition_to("Fall")
	elif state_machine.current_state != state_machine.get_node("Stun"):
		state_machine.transition_to("Idle")

# ---- Attacks -----

# In player.gd — called by AnimationPlayer method track
func activate_hitbox() -> void:
	var atk := (state_machine.get_node("Attack") as AttackState).current_attack
	var offset := Vector2(atk.hitbox_offset.x * facing, atk.hitbox_offset.y)
	hitbox.enable(atk.hitbox_size, offset)

func deactivate_hitbox() -> void:
	hitbox.disable()

func start_block() -> void:
	parry_timer = parry_window
	block_bar.visible = true
	block_bar.max_value = max_block_health
	block_bar.value = block_health

func end_block() -> void:
	block_regen_timer = block_regen_delay

func is_parrying() -> bool:
	return parry_timer > 0.0

func update_block_health(delta: float) -> void:
	block_health -= block_drain_rate * delta
	block_health = maxf(block_health, 0.0)
	block_bar.value = block_health
	if parry_timer > 0.0:
		parry_timer -= delta
	if block_health <= 0.0:
		break_block()

func update_block_regen(delta: float) -> void:
	if is_block_broken:
		# Check if trigger released so block can be used again
		if not block_held:
			is_block_broken = false
		return
	if block_health >= max_block_health:
		block_bar.visible = false
		return
	if block_regen_timer > 0.0:
		block_regen_timer -= delta
		return
	block_health = minf(block_health + block_regen_rate * delta, max_block_health)
	block_bar.value = block_health
	if block_health >= max_block_health:
		block_bar.visible = false

func break_block() -> void:
	is_block_broken = true
	block_health = max_block_health
	block_bar.visible = false
	apply_stun(block_break_stun)

func take_block_damage(amount: float, attacker: Player) -> void:
	if is_parrying():
		attacker.apply_stun(parry_stun_duration)
		is_block_broken = true
		block_bar.visible = false
		state_machine.transition_to("Parry")
		return
	# Reduce block health by a fraction of the damage
	block_health -= amount * 0.5
	block_bar.value = block_health
	if block_health <= 0.0:
		break_block()

# duration: how long to freeze the player for
# attackee: if the player is the one being attacked
func apply_hit_stop(duration: float, attackee: bool = false) -> void:
	anim_sprite.pause()
	if not attackee:
		anim_player.pause()
	set_physics_process(false)
	set_process(false)
	await get_tree().create_timer(duration).timeout
	anim_sprite.play()
	if not attackee:
		anim_player.play()
	set_physics_process(true)
	set_process(true)
	state_machine.transition_to("Idle")

func apply_hit(amount: float, kb: Vector2, stun: float, hit_stop: float) -> void:
	damage_player(amount)
	if state_machine.current_state == state_machine.get_node("Dead"):
		return
	apply_hit_stop(hit_stop, true)
	await get_tree().create_timer(hit_stop).timeout
	apply_knockback(kb)
	apply_stun(stun)

func set_crouch_hurtbox() -> void:
	(hurtbox.shape as RectangleShape2D).size = crouch_size
	hurtbox.position = crouch_offset

func reset_hurtbox() -> void:
	(hurtbox.shape as RectangleShape2D).size = original_hurtbox_size
	hurtbox.position = original_hurtbox_offset
