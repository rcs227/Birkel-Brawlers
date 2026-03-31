class_name CharacterSelectScreen
extends Control

signal all_players_selected(selections: Array[int])

static var last_selections: Array[int] = []
static var last_player_count: int = 2
static var last_profile_names: Array[String] = []

@export var player_count: int = 2
@export var default_sprite_frames: SpriteFrames
@export var character_sprite_frames: Array[SpriteFrames] = []
@export var character_button_textures: Array[Texture2D] = []
@export var character_names: Array[String] = ["JP"]

@onready var button_grid: CharacterButtonGrid = $ButtonPanel/VBox/ButtonGrid
@onready var selection_slots: SelectionSlots = $SelectionSlots
@onready var title_label: Label = $TitleLabel
@onready var prompt_label: Label = $PromptLabel
@onready var _vs_label: Label = $VSLabel
@onready var _remove_btn: Button = $ButtonPanel/VBox/ActionBar/RemoveBtn
@onready var _add_btn: Button = $ButtonPanel/VBox/ActionBar/AddBtn
@onready var _start_btn: Button = $ButtonPanel/VBox/ActionBar/StartBtn
@onready var _add_profile_dialog: ConfirmationDialog = $AddProfileDialog
@onready var _profile_name_input: LineEdit = $AddProfileDialog/ProfileNameInput
@onready var _profile_dropdown_nodes: Array[ProfileDropdown] = [
	$ProfileDropdownP1,
	$ProfileDropdownP2,
	$ProfileDropdownP3,
	$ProfileDropdownP4,
]

const MIN_PLAYERS := 2
const MAX_PLAYERS := 4

const WARM_WHITE := Color(0.98, 0.95, 0.9, 1)

var current_player: int = 0
var selections: Array[int] = []


func _ready() -> void:
	selection_slots.setup(self, default_sprite_frames, character_sprite_frames, _profile_dropdown_nodes)
	selections.resize(player_count)
	selections.fill(-1)
	selection_slots.rebuild(player_count)
	_vs_label.visible = player_count == 2
	button_grid.build(character_sprite_frames.size(), character_button_textures, character_names)
	button_grid.character_pressed.connect(_on_character_pressed)
	_update_action_buttons()
	_update_prompt()
	selection_slots.start_active_pulse(current_player)


func _on_add_profile_pressed() -> void:
	_profile_name_input.clear()
	_add_profile_dialog.popup_centered()
	_profile_name_input.grab_focus()


func _on_profile_name_submitted(_text: String) -> void:
	_on_add_profile_confirmed()


func _on_add_profile_confirmed() -> void:
	var profile_name := _profile_name_input.text.strip_edges()
	if profile_name.is_empty():
		return
	if not SaveManager.save_profile(profile_name):
		return
	selection_slots.refresh_profile_dropdowns()
	_profile_name_input.clear()
	_add_profile_dialog.hide()


func _on_character_pressed(index: int) -> void:
	if current_player >= player_count:
		return

	selections[current_player] = index
	selection_slots.apply_character_pick(current_player, index)

	current_player += 1

	if current_player >= player_count:
		selection_slots.stop_active_pulse()
		prompt_label.text = "ALL READY"
		prompt_label.add_theme_color_override("font_color", WARM_WHITE)
		_flash_ready()
		_update_action_buttons()
		all_players_selected.emit(selections.duplicate())
	else:
		_update_prompt()
		_update_action_buttons()
		selection_slots.start_active_pulse(current_player)


func _update_prompt() -> void:
	var color: Color = selection_slots.get_player_color(current_player)
	prompt_label.text = "P" + str(current_player + 1) + "  SELECT"
	prompt_label.add_theme_color_override("font_color", color)


func _update_action_buttons() -> void:
	_remove_btn.disabled = player_count <= MIN_PLAYERS or current_player > 0
	_add_btn.disabled = player_count >= MAX_PLAYERS or current_player > 0
	_start_btn.disabled = current_player < player_count


func _on_add_player() -> void:
	if player_count >= MAX_PLAYERS:
		return
	player_count += 1
	_rebuild_all()


func _on_remove_player() -> void:
	if player_count <= MIN_PLAYERS:
		return
	player_count -= 1
	_rebuild_all()


func _on_start_pressed() -> void:
	if current_player < player_count:
		return
	last_selections = selections.duplicate()
	last_player_count = player_count
	last_profile_names = selection_slots.get_selected_profile_names(player_count)
	get_tree().change_scene_to_file("res://scenes/char_test.tscn")


func _rebuild_all() -> void:
	selection_slots.stop_active_pulse()

	current_player = 0
	selections.resize(player_count)
	selections.fill(-1)

	selection_slots.rebuild(player_count)
	_vs_label.visible = player_count == 2
	button_grid.build(character_sprite_frames.size(), character_button_textures, character_names)
	_update_prompt()
	_update_action_buttons()
	selection_slots.start_active_pulse(current_player)


func _flash_ready() -> void:
	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 0.3, 0.12)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.12)
	tween.tween_property(title_label, "modulate:a", 0.3, 0.12)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.12)
