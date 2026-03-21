class_name Player
extends CharacterBody2D

# child nodes
@onready var anim_sprite = get_node("AnimatedSprite2D")
@onready var state_machine: StateMachine = get_node("StateMachine")

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
var has_flip := true

var knockback := Vector2.ZERO

func _ready():
	health_bar.value = health
	anim_sprite.animation_finished.connect(_on_animation_finished)
	state_machine.init(state_machine.get_node("Idle"))

func _process(delta: float) -> void:
	state_machine.process(delta)

func _physics_process(delta: float) -> void:
	# always read axes so any state can access them
	special_held = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT) > TRIGGER_THRESHOLD
	block_held   = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_THRESHOLD
	state_machine.physics_process(delta)

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
func safe_play(animation: StringName) -> void:
	if anim_sprite.sprite_frames.has_animation(animation):
		anim_sprite.play(animation)
		
func _on_animation_finished() -> void:
	if state_machine.current_state == state_machine.get_node("Dead"):
		queue_free()
	else:
		state_machine.transition_to("Idle")

# ---- Attacks -----
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
