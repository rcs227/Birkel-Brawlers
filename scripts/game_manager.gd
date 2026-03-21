extends Node2D

var connected := Input.get_connected_joypads()

@export var players: Array

func _ready() -> void:
	var i = 0
	while i < connected.size() and i < players.size():
		players[i].device_id = connected[i]
		i += 1
