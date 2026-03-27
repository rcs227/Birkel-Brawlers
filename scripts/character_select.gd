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

@onready var button_grid: GridContainer = $ButtonPanel/VBox/ButtonGrid
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

const PLAYER_COLORS := [
	Color(0.27, 0.53, 1.0),   # P1 blue
	Color(1.0, 0.27, 0.27),   # P2 red
	Color(0.27, 0.87, 0.4),   # P3 green
	Color(0.87, 0.8, 0.27),   # P4 yellow
]

const SLOT_CENTERS := {
	1: [160],
	2: [85, 235],
	3: [60, 160, 260],
	4: [46, 122, 198, 274],
}

const SLOT_WIDTH := 44
const SLOT_HEIGHT := 52
const SLOT_Y := 24
const PREVIEW_Y := 54
const PREVIEW_FIT_HEIGHT := 40.0

const MIN_PLAYERS := 2
const MAX_PLAYERS := 4

const BROWN_PRIMARY := Color(0.45, 0.28, 0.12, 1)
const WARM_WHITE := Color(0.98, 0.95, 0.9, 1)

const BUTTON_ICON_SIZE := Vector2(20, 20)
const BUTTON_ICON_CROP := 0.5

var current_player: int = 0
var selections: Array[int] = []

var _previews: Array[AnimatedSprite2D] = []
var _player_labels: Array[Label] = []
var _slot_panels: Array[Panel] = []
var _slot_styles: Array[StyleBoxFlat] = []
var _highlight_bars: Array[ColorRect] = []
var _profile_buttons: Array[ProfileDropdown] = []

var _active_tween: Tween


func _ready() -> void:
	_profile_buttons = _profile_dropdown_nodes
	selections.resize(player_count)
	selections.fill(-1)
	_create_preview_slots()
	_vs_label.visible = player_count == 2
	_build_buttons()
	_update_action_buttons()
	_update_prompt()
	_start_active_pulse()


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
	_refresh_profile_dropdowns()
	_profile_name_input.clear()
	_add_profile_dialog.hide()


func _get_frames_for_character(index: int) -> SpriteFrames:
	if index < character_sprite_frames.size() and character_sprite_frames[index] != null:
		return character_sprite_frames[index]
	return default_sprite_frames


func _crop_top_half(src: Texture2D) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	var full_size := src.get_size()
	var crop_h := full_size.y * BUTTON_ICON_CROP
	if src is AtlasTexture:
		atlas.atlas = (src as AtlasTexture).atlas
		var r: Rect2 = (src as AtlasTexture).region
		atlas.region = Rect2(r.position, Vector2(r.size.x, r.size.y * BUTTON_ICON_CROP))
	else:
		atlas.atlas = src
		atlas.region = Rect2(0, 0, full_size.x, crop_h)
	return atlas


func _get_anim_name(frames: SpriteFrames) -> String:
	if frames.has_animation("idle"):
		return "idle"
	return "default"


func _get_preview_scale(frames: SpriteFrames, anim_name: String) -> float:
	var tex: Texture2D = frames.get_frame_texture(anim_name, 0)
	if tex:
		return PREVIEW_FIT_HEIGHT / tex.get_size().y
	return 0.25


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

		var preview := AnimatedSprite2D.new()
		preview.sprite_frames = default_sprite_frames
		preview.position = Vector2(cx, PREVIEW_Y)
		preview.scale = Vector2(0.25, 0.25)
		preview.visible = false
		add_child(preview)
		_previews.append(preview)

	_refresh_profile_dropdowns()
	_position_profile_dropdowns()

	for i in range(_profile_buttons.size()):
		_profile_buttons[i].visible = i < player_count


func _build_buttons() -> void:
	for child in button_grid.get_children():
		child.queue_free()
	var count := character_sprite_frames.size()
	for i in range(count):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(18, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_button_pressed.bind(i))

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(vbox)

		var tex: Texture2D = character_button_textures[i] if i < character_button_textures.size() else null
		if tex:
			var cropped := _crop_top_half(tex)
			var icon := TextureRect.new()
			icon.texture = cropped
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = BUTTON_ICON_SIZE
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(icon)

		var lbl := Label.new()
		lbl.text = character_names[i] if i < character_names.size() else str(i + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)

		button_grid.add_child(btn)


func _on_button_pressed(index: int) -> void:
	if current_player >= player_count:
		return

	selections[current_player] = index
	var color: Color = PLAYER_COLORS[current_player]

	var preview: AnimatedSprite2D = _previews[current_player]
	var frames: SpriteFrames = _get_frames_for_character(index)
	preview.sprite_frames = frames.duplicate(true)

	var anim_name: String = _get_anim_name(frames)
	var s: float = _get_preview_scale(frames, anim_name)

	preview.visible = true
	preview.play(anim_name)
	preview.scale = Vector2.ZERO
	preview.modulate = Color(1, 1, 1, 0)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(preview, "scale", Vector2(s, s), 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(preview, "modulate", Color.WHITE, 0.15)

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
		all_players_selected.emit(selections.duplicate())
	else:
		_update_prompt()
		_update_action_buttons()
		_start_active_pulse()


func _update_prompt() -> void:
	var color: Color = PLAYER_COLORS[current_player]
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
	last_profile_names = _get_selected_profile_names()
	get_tree().change_scene_to_file("res://scenes/char_test.tscn")


func _rebuild_all() -> void:
	_stop_active_pulse()

	# for node: Node in _previews + _player_labels + _slot_panels + _highlight_bars + _profile_buttons:
	for node: Node in _previews + _player_labels + _slot_panels + _highlight_bars:
		node.queue_free()

	_previews.clear()
	_player_labels.clear()
	_slot_panels.clear()
	_slot_styles.clear()
	_highlight_bars.clear()
	# _profile_buttons are created in-editor, never cleared or freed.

	current_player = 0
	selections.resize(player_count)
	selections.fill(-1)

	_create_preview_slots()
	_vs_label.visible = player_count == 2
	_update_prompt()
	_update_action_buttons()
	_start_active_pulse()


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


func _flash_ready() -> void:
	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 0.3, 0.12)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.12)
	tween.tween_property(title_label, "modulate:a", 0.3, 0.12)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.12)


func _refresh_profile_dropdowns() -> void:
	for btn in _profile_buttons:
		btn.refresh()

func _position_profile_dropdowns() -> void:
	var centers: Array = SLOT_CENTERS.get(player_count, SLOT_CENTERS[2])
	for i in range(_profile_buttons.size()):
		var btn := _profile_buttons[i]
		if i >= player_count:
			continue
		var cx: int = centers[i]
		btn.position = Vector2(cx - SLOT_WIDTH / 2, SLOT_Y + SLOT_HEIGHT + 2)
		btn.size = Vector2(SLOT_WIDTH, 14)
		btn.add_theme_font_size_override("font_size", 5)


func _get_selected_profile_names() -> Array[String]:
	var out: Array[String] = []
	for i in range(player_count):
		out.append(_profile_buttons[i].get_selected_profile())
	return out
