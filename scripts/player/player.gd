class_name Player
extends CharacterBody2D

# child nodes
@onready var anim_sprite = get_node("AnimatedSprite2D") as AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var state_machine: StateMachine = get_node("StateMachine")
@onready var hitbox: Hitbox = get_node("Hitbox")

# constants
const STICK_DEADZONE := 0.3
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

# --- State ---
var max_health := 100
var health := 100

var special_held := false
var block_held := false
var has_flip := true

var knockback := Vector2.ZERO

func _ready():
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
	state_machine.transition_to("Stun")
	state_machine.get_node("Stun").duration = duration
	
func apply_knockback(force: Vector2):
	knockback = force

func damage_player(amount: float):
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
	else:
		state_machine.transition_to("Idle")

# ---- Attacks -----

# In player.gd — called by AnimationPlayer method track
func activate_hitbox() -> void:
	var atk := (state_machine.get_node("Attack") as AttackState).current_attack
	var offset := Vector2(atk.hitbox_offset.x * facing, atk.hitbox_offset.y)
	hitbox.enable(atk.hitbox_size, offset)

func deactivate_hitbox() -> void:
	hitbox.disable()
