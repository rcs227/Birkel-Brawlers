extends Control

# Emitted when every player has chosen a character.
# selections is an Array[int] of character indices, one per player.
signal all_players_selected(selections: Array[int])

# character_count and grid_columns control how many character buttons appear and how they're laid out.
# player_count is the starting number of players (can be changed with +/- PLAYER buttons at runtime).
# character_sprite_frames maps each character index to its SpriteFrames resource.
# Assign them in the Inspector on the CharacterSelect node in character_select.tscn.
@export var character_count: int = 4
@export var grid_columns: int = 4
@export var player_count: int = 2
@export var default_sprite_frames: SpriteFrames
@export var character_sprite_frames: Array[SpriteFrames] = []

# These nodes are defined in character_select.tscn.
@onready var button_grid: GridContainer = $ButtonPanel/VBox/ButtonGrid
@onready var action_bar: HBoxContainer = $ButtonPanel/VBox/ActionBar
@onready var title_label: Label = $TitleLabel
@onready var prompt_label: Label = $PromptLabel

# Colors used to identify each player's slot and highlight bar.
# Edit these to change the per-player tint colors.
const PLAYER_COLORS := [
	Color(0.27, 0.53, 1.0),   # P1 blue
	Color(1.0, 0.27, 0.27),   # P2 red
	Color(0.27, 0.87, 0.4),   # P3 green
	Color(0.87, 0.8, 0.27),   # P4 yellow
]

# X positions (in pixels) for each slot depending on how many players there are.
# Edit these if you need to reposition the preview slots.
const SLOT_CENTERS := {
	1: [160],
	2: [85, 235],
	3: [60, 160, 260],
	4: [46, 122, 198, 274],
}

# Slot panel size and position constants.
# SLOT_Y is distance from the top of the screen. SLOT_HEIGHT is the panel height.
# PREVIEW_Y is where the character sprite is centered vertically.
# PREVIEW_FIT_HEIGHT is the target height the sprite is scaled to fit.
const SLOT_WIDTH := 44
const SLOT_HEIGHT := 52
const SLOT_Y := 24
const PREVIEW_Y := 54
const PREVIEW_FIT_HEIGHT := 40.0

# Hard limits on how many players can be added or removed.
const MIN_PLAYERS := 2
const MAX_PLAYERS := 4

# Edit these to change the color scheme of the character select screen.
const BROWN_PRIMARY := Color(0.45, 0.28, 0.12, 1)
const WARM_WHITE := Color(0.98, 0.95, 0.9, 1)

# Button label for each character slot. Falls back to the slot number if a name isn't listed.
const CHARACTER_NAMES := ["JP"]

# Runtime state tracking.
var current_player: int = 0       # whose turn it is to pick
var selections: Array[int] = []   # chosen character index per player (-1 = not yet chosen)

# These arrays are parallel — index i refers to player i's slot, label, sprite, etc.
var _previews: Array[AnimatedSprite2D] = []
var _player_labels: Array[Label] = []
var _slot_panels: Array[Panel] = []
var _slot_styles: Array[StyleBoxFlat] = []  # held so colors can be updated after selection
var _highlight_bars: Array[ColorRect] = []  # thin bar at the bottom of each slot that pulses

var _active_tween: Tween   # the pulsing bar animation for the current player
var _vs_label: Label
var _add_btn: Button
var _remove_btn: Button
var _start_btn: Button


func _ready() -> void:
	selections.resize(player_count)
	selections.fill(-1)
	_create_preview_slots()
	_create_vs_label()
	_build_buttons()
	_build_action_bar()
	_update_prompt()
	_start_active_pulse()


# Returns the SpriteFrames for a character index.
# Falls back to default_sprite_frames if none is assigned for that index.
func _get_frames_for_character(index: int) -> SpriteFrames:
	if index < character_sprite_frames.size() and character_sprite_frames[index] != null:
		return character_sprite_frames[index]
	return default_sprite_frames


# Checks whether the SpriteFrames has an animation named "idle", otherwise uses "default".
# Make sure new characters have an animation named "idle" to show in the preview.
func _get_anim_name(frames: SpriteFrames) -> String:
	if frames.has_animation("idle"):
		return "idle"
	return "default"


# Scales the preview sprite so its height matches PREVIEW_FIT_HEIGHT.
# If the texture is missing, falls back to 0.25.
func _get_preview_scale(frames: SpriteFrames, anim_name: String) -> float:
	var tex: Texture2D = frames.get_frame_texture(anim_name, 0)
	if tex:
		return PREVIEW_FIT_HEIGHT / tex.get_size().y
	return 0.25


# Builds one slot per player. Each slot contains:
#   - A Panel (the box outline, styled via _slot_styles)
#   - A ColorRect highlight bar at the bottom that pulses for the active player
#   - A "P1"/"P2" label at the top
#   - An AnimatedSprite2D that appears when the player makes a selection
# To change slot size or position, edit the SLOT_* and PREVIEW_* constants above.
func _create_preview_slots() -> void:
	var centers: Array = SLOT_CENTERS.get(player_count, SLOT_CENTERS[2])

	for i in range(player_count):
		var cx: int = centers[i]
		var color: Color = PLAYER_COLORS[i]

		var style := StyleBoxFlat.new()
		style.bg_color = Color(BROWN_PRIMARY, 0.3)
		style.border_color = Color(0.08, 0.05, 0.02, 0.4)
		style.set_border_width_all(1)

		var slot := Panel.new()
		slot.add_theme_stylebox_override("panel", style)
		slot.position = Vector2(cx - SLOT_WIDTH / 2, SLOT_Y)
		slot.size = Vector2(SLOT_WIDTH, SLOT_HEIGHT)
		add_child(slot)
		_slot_panels.append(slot)
		_slot_styles.append(style)

		# 1px bar at the bottom of the slot — animated by _start_active_pulse().
		var bar := ColorRect.new()
		bar.color = Color(color, 0.2)
		bar.size = Vector2(SLOT_WIDTH - 4, 1)
		bar.position = Vector2(cx - (SLOT_WIDTH - 4) / 2, SLOT_Y + SLOT_HEIGHT - 3)
		add_child(bar)
		_highlight_bars.append(bar)

		var label := Label.new()
		label.text = "P" + str(i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 7)
		label.add_theme_color_override("font_color", Color(WARM_WHITE, 0.5))
		label.position = Vector2(cx - SLOT_WIDTH / 2, SLOT_Y + 2)
		label.size = Vector2(SLOT_WIDTH, 10)
		add_child(label)
		_player_labels.append(label)

		# Starts hidden. Made visible with a pop-in tween when a character is selected.
		var preview := AnimatedSprite2D.new()
		preview.sprite_frames = default_sprite_frames
		preview.position = Vector2(cx, PREVIEW_Y)
		preview.scale = Vector2(0.25, 0.25)
		preview.visible = false
		add_child(preview)
		_previews.append(preview)


# Only shown in 2-player mode. Centered between the two slots.
# Change the position Vector2 or font_size to reposition/resize it.
func _create_vs_label() -> void:
	if player_count != 2:
		return
	_vs_label = Label.new()
	_vs_label.text = "VS"
	_vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vs_label.add_theme_font_size_override("font_size", 14)
	_vs_label.add_theme_color_override("font_color", Color(WARM_WHITE, 0.5))
	_vs_label.position = Vector2(144, 44)
	_vs_label.size = Vector2(32, 16)
	add_child(_vs_label)


# Populates the ButtonGrid with one button per character.
# Button labels are just the character index number (1, 2, 3...).
# To use character names instead, replace str(i + 1) with a name lookup.
# Button visuals come from character_selection_theme.tres — edit that file to restyle them.
func _build_buttons() -> void:
	for child in button_grid.get_children():
		child.queue_free()

	button_grid.columns = grid_columns

	for i in range(character_count):
		var btn := Button.new()
		btn.text = CHARACTER_NAMES[i] if i < CHARACTER_NAMES.size() else str(i + 1)
		btn.custom_minimum_size = Vector2(28, 24)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_button_pressed.bind(i))
		button_grid.add_child(btn)


# Builds the three action buttons at the bottom: - PLAYER, + PLAYER, START.
# START is wider than the others (size_flags_stretch_ratio = 1.5).
func _build_action_bar() -> void:
	_remove_btn = _make_action_btn("- PLAYER")
	_remove_btn.pressed.connect(_on_remove_player)
	action_bar.add_child(_remove_btn)

	_add_btn = _make_action_btn("+ PLAYER")
	_add_btn.pressed.connect(_on_add_player)
	action_bar.add_child(_add_btn)

	_start_btn = _make_action_btn("START")
	_start_btn.size_flags_stretch_ratio = 1.5
	_start_btn.add_theme_font_size_override("font_size", 8)
	_start_btn.pressed.connect(_on_start_pressed)
	action_bar.add_child(_start_btn)

	_update_action_buttons()


# Base factory for action bar buttons. Visual style comes from character_selection_theme.tres.
# Change custom_minimum_size.y to adjust the action bar button height.
func _make_action_btn(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 16)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 7)
	return btn


# Shared helper for building a StyleBoxFlat — only used for slot panels in this script.
func _make_btn_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = 2.0
	s.content_margin_right = 2.0
	s.content_margin_top = 2.0
	s.content_margin_bottom = 2.0
	return s


# Called when a character button is pressed for the current player.
# Plays a pop-in tween on the preview sprite: scales from zero and fades in over 0.25s.
# After selection, the slot panel border and highlight bar switch to that player's color.
# Change the tween duration (0.25) or easing to adjust the pop-in feel.
func _on_button_pressed(index: int) -> void:
	if current_player >= player_count:
		return

	selections[current_player] = index
	var color: Color = PLAYER_COLORS[current_player]

	var preview: AnimatedSprite2D = _previews[current_player]
	var frames: SpriteFrames = _get_frames_for_character(index)
	preview.sprite_frames = frames

	var anim_name: String = _get_anim_name(frames)
	var s: float = _get_preview_scale(frames, anim_name)

	preview.visible = true
	preview.play(anim_name)
	preview.scale = Vector2.ZERO
	preview.modulate = Color(1, 1, 1, 0)

	# Pop-in: scale from 0 to final size with a bouncy ease, fade in simultaneously.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(preview, "scale", Vector2(s, s), 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(preview, "modulate", Color.WHITE, 0.15)

	# Slot border and bar switch to the player's color once they've chosen.
	_slot_styles[current_player].bg_color = Color(color, 0.2)
	_slot_styles[current_player].border_color = Color(color, 0.7)
	_highlight_bars[current_player].color = color
	_player_labels[current_player].add_theme_color_override("font_color", color)

	current_player += 1

	if current_player >= player_count:
		_stop_active_pulse()
		prompt_label.text = "ALL READY"
		prompt_label.add_theme_color_override("font_color", WARM_WHITE)
		_flash_ready()
		_update_action_buttons()
		all_players_selected.emit(selections)
	else:
		_update_prompt()
		_update_action_buttons()
		_start_active_pulse()


# Updates the prompt label to show which player needs to pick.
# Text color matches that player's PLAYER_COLORS entry.
func _update_prompt() -> void:
	var color: Color = PLAYER_COLORS[current_player]
	prompt_label.text = "P" + str(current_player + 1) + "  SELECT"
	prompt_label.add_theme_color_override("font_color", color)


# Enables/disables the action buttons based on the current state.
# +/- PLAYER are locked once any player has made a selection.
# START is locked until all players have chosen.
func _update_action_buttons() -> void:
	if not _remove_btn:
		return
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
	get_tree().change_scene_to_file("res://scenes/char_test.tscn")


# Tears down and recreates all dynamic UI when the player count changes.
# Resets selections and current_player back to the start.
func _rebuild_all() -> void:
	_stop_active_pulse()

	for node: Node in _previews + _player_labels + _slot_panels + _highlight_bars:
		if node.get_parent():
			node.get_parent().remove_child(node)
		node.queue_free()

	if _vs_label:
		if _vs_label.get_parent():
			_vs_label.get_parent().remove_child(_vs_label)
		_vs_label.queue_free()
		_vs_label = null

	_previews.clear()
	_player_labels.clear()
	_slot_panels.clear()
	_slot_styles.clear()
	_highlight_bars.clear()

	current_player = 0
	selections.resize(player_count)
	selections.fill(-1)

	_create_preview_slots()
	_create_vs_label()
	_update_prompt()
	_update_action_buttons()
	_start_active_pulse()


# Animates the highlight bar of the currently selecting player, fading between 0.2 and 0.8 alpha.
# Change the tween durations (0.4s each) to speed up or slow down the pulse.
func _start_active_pulse() -> void:
	_stop_active_pulse()
	if current_player >= player_count:
		return

	var bar: ColorRect = _highlight_bars[current_player]
	var color: Color = PLAYER_COLORS[current_player]
	_active_tween = create_tween().set_loops()
	_active_tween.tween_property(bar, "color", Color(color, 0.8), 0.4)
	_active_tween.tween_property(bar, "color", Color(color, 0.2), 0.4)


func _stop_active_pulse() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null


# Flashes the title label's alpha twice when all players are ready.
# Change the values (0.3 = dim, 1.0 = full, 0.12 = duration per step) to adjust the flash.
func _flash_ready() -> void:
	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 0.3, 0.12)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.12)
	tween.tween_property(title_label, "modulate:a", 0.3, 0.12)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.12)
