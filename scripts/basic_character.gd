class_name BasicCharacter
extends CharacterBody2D


# MOVEMENT STATS
@export var speed := 150.0
@export var acceleration := 1000.0
@export var friction := 750.0
@export var jump_force := -225.0
@export var gravity := 600.0

func _physics_process(delta: float) -> void:
	# Horizontal movement
	var direction := Input.get_axis("left", "right")

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# vertical movement
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
	else:
		# apply gravity while airborne
		velocity.y += gravity * delta

	move_and_slide()
