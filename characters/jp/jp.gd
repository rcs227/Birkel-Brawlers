class_name JP
extends Player

@export var light_attack_data:  Attack
@export var medium_attack_data: Attack
@export var heavy_attack_data:  Attack
@export var light_special_data: Attack
@export var medium_special_data: Attack
@export var heavy_special_data: Attack

func get_attack(action: String) -> Attack:
	match action:
		"light_attack":  return light_special_data if special_held else light_attack_data
		"medium_attack": return medium_special_data if special_held else medium_attack_data
		"heavy_attack":  return heavy_special_data if special_held else heavy_attack_data
	return null
