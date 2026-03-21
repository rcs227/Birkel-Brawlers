class_name Player
extends CharacterBody2D

@export var device_id: int = 0 # assigned at game start

var special_held: bool = false
var block_held: bool = false

# MOVEMENT STATS
@export var speed := 150.0
@export var acceleration := 1000.0
@export var friction := 750.0
@export var jump_force := -225.0
@export var gravity := 600.0

@export var health_bar: ProgressBar

var max_health = 100
var health = 100

var has_flip: bool = true

var stun_timer: float = 0.0

var knockback: Vector2 = Vector2.ZERO

func _ready():
	health_bar.value = health

func _physics_process(delta: float) -> void:
	if stun_timer > 0.0:
		stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.y = gravity * delta
		move_and_slide()
		return
	
	special_held = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT) > 0.5
	block_held = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > 0.5
	
	# Horizontal movement
	# prevent stick drift
	var raw := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var direction := 0.0 if block_held or abs(raw) < 0.2 else raw

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# vertical movement
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		has_flip = true

	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.device != device_id or block_held or stun_timer > 0.0:
		return
	if event.is_action_pressed("jump"):
		if is_on_floor() or has_flip:
			velocity.y = jump_force
			if not is_on_floor():
				has_flip = false
	if event.is_action_pressed("light_attack"):
		light_attack()
	if event.is_action_pressed("medium_attack"):
		medium_attack()
	if event.is_action_pressed("heavy_attack"):
		heavy_attack()

func apply_stun(duration: float):
	stun_timer = duration
	
func apply_knockback(force: Vector2):
	knockback = force

func grab():
	print("grab")

func light_attack():
	if special_held:
		print("light special")
	else:
		print("light attack")

func medium_attack():
	if special_held:
		print("medium special")
	else:
		print("medium attack")

func heavy_attack():
	if special_held:
		print("heavy special")
	else:
		print("heavy attack")

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
