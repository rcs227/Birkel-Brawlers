class_name Player
extends CharacterBody2D

# child nodes
@onready var anim_sprite = get_node("AnimatedSprite2D")

# constants
const STICK_DEADZONE := 0.2
const TRIGGER_THRESHOLD := 0.5
const CROUCH_THRESHOLD := 0.6

# exports

@export var device_id: int = 0 # assigned at game start

# MOVEMENT STATS
@export var speed := 150.0
@export var acceleration := 1000.0
@export var friction := 750.0
@export var jump_force := -225.0
@export var gravity := 600.0

@export_group("UI")
@export var health_bar: ProgressBar

# --- State ---
var max_health := 100
var health := 100

var special_held := false
var block_held := false
var is_crouching := false
var has_flip := true
var jump_grace_timer := 0.0
const JUMP_GRACE_TIME := 0.1

var stun_timer := 0.0
var knockback := Vector2.ZERO

func _ready():
	health_bar.value = health
	anim_sprite.animation_finished.connect(_on_animation_finished)
	safe_play("default")

func _physics_process(delta: float) -> void:
	_read_axes()
	if jump_grace_timer > 0.0:
		jump_grace_timer -= delta

	if stun_timer > 0.0:
		_process_stun(delta)
		return

	_process_crouch()
	_process_horizontal(delta)
	_process_vertical(delta)
	_process_knockback(delta)
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.device != device_id or block_held or stun_timer > 0.0:
		return
	if event.is_action_pressed("jump"):
		_try_jump()
	if event.is_action_pressed("light_attack"):
		if !special_held:
			light_attack()
		else:
			light_special()
	if event.is_action_pressed("medium_attack"):
		if !special_held:
			medium_attack()
		else:
			medium_special()
	if event.is_action_pressed("heavy_attack"):
		if !special_held:
			heavy_attack()
		else:
			heavy_special()
	if event.is_action_pressed("grab") and jump_grace_timer == 0:
		grab()

# ---- Input Reading -----
func _read_axes() -> void:
	special_held = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT) > TRIGGER_THRESHOLD
	block_held = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_THRESHOLD

func _process_crouch() -> void:
	if jump_grace_timer > 0.0:
		return
	var down := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y) > CROUCH_THRESHOLD
	if down and not is_crouching and is_on_floor():
		crouch()
	elif not down and is_crouching:
		uncrouch()


# ----- Movement -------

func _process_stun(delta: float) -> void:
	stun_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	velocity.y += gravity * delta
	move_and_slide()

func _process_horizontal(delta: float) -> void:
	var raw := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var direction := 0.0 if block_held or abs(raw) < STICK_DEADZONE or is_crouching else raw
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _process_vertical(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		has_flip = true

func _process_knockback(delta: float) -> void:
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, friction * delta)

func _try_jump() -> void:
	if is_on_floor() or has_flip:
		if is_crouching:
			uncrouch()
		jump_grace_timer = JUMP_GRACE_TIME
		velocity.y = jump_force
		if not is_on_floor():
			has_flip = false

func apply_stun(duration: float):
	stun_timer = duration
	
func apply_knockback(force: Vector2):
	knockback = force

func grab():
	print("grab")

func light_attack():
	print("light attack")

func medium_attack():
	print("medium attack")

func heavy_attack():
	print("heavy attack")

func light_special():
	print("light special")

func medium_special():
	print("medium special")

func heavy_special():
	print("heavy special")

func damage_player(amount: float):
	health -= amount
	health_bar.value = health
	if health <= 0:
		die()

func die():
	print("u died lol")
	queue_free()

func execute_attack(attack: Attack):
	pass

func crouch():
	is_crouching = true
	safe_play("crouch")

func uncrouch():
	is_crouching = false
	safe_play("default")

# --- Animation ---

# safely checks if an animation exists
func safe_play(animation: StringName) -> void:
	if anim_sprite.sprite_frames.has_animation(animation):
		anim_sprite.play(animation)
		
func _on_animation_finished() -> void:
	safe_play("default")
