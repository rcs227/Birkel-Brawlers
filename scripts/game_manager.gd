extends Node2D

## Every fighter instance (including multiple copies of the same character) is parented here,
## so they are all children of this match .tscn.
@onready var fighters_parent: Node2D = $Players

## character index from character select → PackedScene. Unset entries fall back to `_default_character_scenes`.
@export var character_scenes: Array[PackedScene] = []

## One path per player slot to a ProgressBar (siblings of `Players` under this root).
@export var player_health_bar_paths: Array[NodePath] = [
	NodePath("health_bar"),
	NodePath("health_bar2"),
]

@export var spawn_positions: Array[Vector2] = [
	Vector2(80, 150),
	Vector2(240, 150),
]

## 1,1 uses the character scene’s authored size (no extra shrinking).
@export var spawn_scale: Vector2 = Vector2(1, 1)

## When this scene is opened without going through character select (e.g. F6 from editor).
@export var fallback_selections: Array[int] = [0, 0]

const _default_character_scenes: Array[PackedScene] = [
	preload("res://characters/jp/jp.tscn"),
]

var _spawned_fighters: Array[Player] = []


func _ready() -> void:
	var selections: Array[int] = CharacterSelectScreen.last_selections.duplicate()
	if selections.is_empty():
		selections = fallback_selections.duplicate()
	for i in range(selections.size()):
		var char_idx: int = selections[i]
		var pack: PackedScene = _get_pack_for_character_index(char_idx)
		if pack == null:
			push_error("Missing PackedScene for character index %d" % char_idx)
			continue
		var fighter: Player = pack.instantiate() as Player
		if fighter == null:
			push_error("Character scene root must extend Player")
			continue
		var pos: Vector2 = spawn_positions[i] if i < spawn_positions.size() else Vector2(100 + i * 100, 150)
		fighter.position = pos
		fighter.scale = spawn_scale
		if i < player_health_bar_paths.size():
			var hb: ProgressBar = get_node_or_null(player_health_bar_paths[i]) as ProgressBar
			if hb:
				fighter.health_bar = hb
		fighters_parent.add_child(fighter)
		_spawned_fighters.append(fighter)
	_assign_input_devices()


func _get_pack_for_character_index(char_idx: int) -> PackedScene:
	if char_idx < 0:
		return null
	if char_idx < character_scenes.size() and character_scenes[char_idx] != null:
		return character_scenes[char_idx]
	if char_idx < _default_character_scenes.size():
		return _default_character_scenes[char_idx]
	return null


func _assign_input_devices() -> void:
	# P1 → joypad 0, P2 → joypad 1, etc. (matches Godot's device indices for connected gamepads.)
	for i in range(_spawned_fighters.size()):
		_spawned_fighters[i].device_id = i
