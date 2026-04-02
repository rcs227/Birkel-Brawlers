class_name StateMachine
extends Node

var current_state: State

func init(initial_state: State):
	for child in get_children():
		child.player = owner
	
	current_state = initial_state
	current_state.enter()

func transition_to(new_state_name: String) -> void:
	var new_state = get_node_or_null(new_state_name)
	if new_state == null:
		push_error("State not found: " + new_state_name)
		return
	elif current_state == get_node("Dead"):
		return
	current_state.exit()
	current_state = new_state
	owner.anim_player.speed_scale = 1.0
	owner.anim_sprite.speed_scale = 1.0
	current_state.enter()

func process(delta: float) -> void:
	var next := current_state.process(delta)
	if next != "":
		transition_to(next)

func physics_process(delta: float) -> void:
	var next := current_state.physics_process(delta)
	if next != "":
		transition_to(next)

func input(event: InputEvent) -> void:
	var next := current_state.input(event)
	if next != "":
		transition_to(next)
