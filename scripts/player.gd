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

func _physics_process(delta: float) -> void:
	special_held = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT) > 0.5
	block_held = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > 0.5
	
	
	# Horizontal movement
	
	var direction := 0.0 if block_held else Input.get_axis("left", "right")

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# vertical movement
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and !block_held:
			velocity.y = jump_force
	else:
		# apply gravity while airborne
		velocity.y += gravity * delta

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.device != device_id or block_held:
		return
	if event.is_action_pressed("light_attack"):
		light_attack()
	if event.is_action_pressed("medium_attack"):
		medium_attack()
	if event.is_action_pressed("heavy_attack"):
		heavy_attack()

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
