extends Node2D

@export var player: Player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("M") and player != null:
		player.damage_player(1)
