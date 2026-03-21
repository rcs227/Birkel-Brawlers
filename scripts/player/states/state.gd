class_name State
extends Node

# Reference to the player — set by StateMachine on ready
var player: Player

func enter() -> void:
	pass

func exit() -> void:
	pass

# Return "" to stay, or "idle"/"walk"/etc. to transition
func process(delta: float) -> String:
	return ""

func physics_process(delta: float) -> String:
	return ""

func input(event: InputEvent) -> String:
	return ""
