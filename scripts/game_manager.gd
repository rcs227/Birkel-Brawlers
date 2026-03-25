extends Node2D

@onready var fighters_parent: Node2D = $Players

@export var character_scenes: Array[PackedScene] = []

@export var player_health_bar_paths: Array[NodePath] = [
	NodePath("health_bar"),
	NodePath("health_bar2"),
]

@export var spawn_positions: Array[Vector2] = [
	Vector2(80, 150),
	Vector2(240, 150),
]

@export var spawn_scale: Vector2 = Vector2(1, 1)
@export var fallback_selections: Array[int] = [0, 0]
@export var rounds_to_win: int = 2  # best of 3
@export var round_reset_delay: float = 2.0  # seconds before next round starts

const _default_character_scenes: Array[PackedScene] = [
	preload("res://characters/jp/jp.tscn"),
]

var _spawned_fighters: Array[Player] = []
var _round_wins: Array[int] = []
var _current_round: int = 1
var _total_rounds: int = 3
var _round_in_progress: bool = false


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
		fighter.died.connect(_on_player_died)
		fighters_parent.add_child(fighter)
		_spawned_fighters.append(fighter)
		_round_wins.append(0)

	_assign_input_devices()
	_round_in_progress = true
	print("Round %d — Fight!" % _current_round)


func _on_player_died(dead_player: Player) -> void:
	if not _round_in_progress:
		return
	_round_in_progress = false

	# Find the winner of this round (the one who didn't die)
	var winner_index := -1
	for i in range(_spawned_fighters.size()):
		if _spawned_fighters[i] != dead_player:
			winner_index = i
			break

	if winner_index == -1:
		print("Draw!")
	else:
		_round_wins[winner_index] += 1
		print("Round %d over — Player %d wins the round! (Score: %s)" % [
			_current_round,
			winner_index + 1,
			_get_score_string()
		])

	# Check if someone has won enough rounds
	for i in range(_spawned_fighters.size()):
		if _round_wins[i] >= rounds_to_win:
			print("Player %d wins the match!" % (i + 1))
			return

	# Check if all rounds are done
	if _current_round >= _total_rounds:
		_declare_match_winner()
		return

	# Start next round after delay
	_current_round += 1
	await get_tree().create_timer(round_reset_delay).timeout
	_reset_round()


func _reset_round() -> void:
	print("Round %d — Fight!" % _current_round)
	for i in range(_spawned_fighters.size()):
		var pos: Vector2 = spawn_positions[i] if i < spawn_positions.size() else Vector2(100 + i * 100, 150)
		_spawned_fighters[i].reset(pos)
	_round_in_progress = true


func _declare_match_winner() -> void:
	var max_wins := 0
	var winner_index := -1
	for i in range(_round_wins.size()):
		if _round_wins[i] > max_wins:
			max_wins = _round_wins[i]
			winner_index = i
		elif _round_wins[i] == max_wins:
			winner_index = -1  # tie

	if winner_index == -1:
		print("Match over — It's a draw! Final score: %s" % _get_score_string())
	else:
		print("Match over — Player %d wins! Final score: %s" % [winner_index + 1, _get_score_string()])


func _get_score_string() -> String:
	var parts: Array[String] = []
	for i in range(_round_wins.size()):
		parts.append("P%d: %d" % [i + 1, _round_wins[i]])
	return " | ".join(parts)


func _get_pack_for_character_index(char_idx: int) -> PackedScene:
	if char_idx < 0:
		return null
	if char_idx < character_scenes.size() and character_scenes[char_idx] != null:
		return character_scenes[char_idx]
	if char_idx < _default_character_scenes.size():
		return _default_character_scenes[char_idx]
	return null


func _assign_input_devices() -> void:
	for i in range(_spawned_fighters.size()):
		_spawned_fighters[i].device_id = i
