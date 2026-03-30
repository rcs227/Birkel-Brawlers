class_name SelectionSlots
extends Node

const PLAYER_COLORS := [
	Color(0.27, 0.53, 1.0),
	Color(1.0, 0.27, 0.27),
	Color(0.27, 0.87, 0.4),
	Color(0.87, 0.8, 0.27),
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

const BROWN_PRIMARY := Color(0.45, 0.28, 0.12, 1)
const WARM_WHITE := Color(0.98, 0.95, 0.9, 1)

var _screen: Control
var _default_sprite_frames: SpriteFrames
var _character_sprite_frames: Array[SpriteFrames] = []
var _profile_buttons: Array[ProfileDropdown] = []

var _previews: Array[AnimatedSprite2D] = []
var _player_labels: Array[Label] = []
var _slot_panels: Array[Panel] = []
var _slot_styles: Array[StyleBoxFlat] = []
var _highlight_bars: Array[ColorRect] = []

var _active_tween: Tween


func setup(
	screen: Control,
	default_frames: SpriteFrames,
	character_frames: Array[SpriteFrames],
	profile_nodes: Array[ProfileDropdown],
) -> void:
	_screen = screen
	_default_sprite_frames = default_frames
	_character_sprite_frames = character_frames
	_profile_buttons = profile_nodes


func rebuild(player_count: int) -> void:
	for node: Node in _previews + _player_labels + _slot_panels + _highlight_bars:
		node.queue_free()

	_previews.clear()
	_player_labels.clear()
	_slot_panels.clear()
	_slot_styles.clear()
	_highlight_bars.clear()

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
		_screen.add_child(slot)
		_slot_panels.append(slot)
		_slot_styles.append(style)

		var bar := ColorRect.new()
		bar.color = Color(color, 0.2)
		bar.size = Vector2(SLOT_WIDTH - 4, 1)
		bar.position = Vector2(cx - (SLOT_WIDTH - 4) / 2, SLOT_Y + SLOT_HEIGHT - 3)
		_screen.add_child(bar)
		_highlight_bars.append(bar)

		var label := Label.new()
		label.text = "P" + str(i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 7)
		label.add_theme_color_override("font_color", Color(WARM_WHITE, 0.5))
		label.position = Vector2(cx - SLOT_WIDTH / 2, SLOT_Y + 2)
		label.size = Vector2(SLOT_WIDTH, 10)
		_screen.add_child(label)
		_player_labels.append(label)

		var preview := AnimatedSprite2D.new()
		preview.sprite_frames = _default_sprite_frames
		preview.position = Vector2(cx, PREVIEW_Y)
		preview.scale = Vector2(0.25, 0.25)
		preview.visible = false
		_screen.add_child(preview)
		_previews.append(preview)

	refresh_profile_dropdowns()
	_position_profile_dropdowns(player_count)

	for i in range(_profile_buttons.size()):
		_profile_buttons[i].visible = i < player_count


func apply_character_pick(slot_index: int, character_index: int) -> void:
	var color: Color = PLAYER_COLORS[slot_index]

	var preview: AnimatedSprite2D = _previews[slot_index]
	var frames: SpriteFrames = _get_frames_for_character(character_index)
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

	_slot_styles[slot_index].bg_color = Color(color, 0.2)
	_slot_styles[slot_index].border_color = Color(color, 0.7)
	_highlight_bars[slot_index].color = color
	_player_labels[slot_index].add_theme_color_override("font_color", color)


func start_active_pulse(active_slot: int) -> void:
	_stop_active_pulse()
	if active_slot >= _highlight_bars.size():
		return

	var bar: ColorRect = _highlight_bars[active_slot]
	var color: Color = PLAYER_COLORS[active_slot]
	_active_tween = create_tween().set_loops()
	_active_tween.tween_property(bar, "color", Color(color, 0.8), 0.4)
	_active_tween.tween_property(bar, "color", Color(color, 0.2), 0.4)


func stop_active_pulse() -> void:
	_stop_active_pulse()


func refresh_profile_dropdowns() -> void:
	for btn in _profile_buttons:
		btn.refresh()


func get_selected_profile_names(player_count: int) -> Array[String]:
	var out: Array[String] = []
	for i in range(player_count):
		out.append(_profile_buttons[i].get_selected_profile())
	return out


func get_player_color(index: int) -> Color:
	return PLAYER_COLORS[index]


func _position_profile_dropdowns(player_count: int) -> void:
	var centers: Array = SLOT_CENTERS.get(player_count, SLOT_CENTERS[2])
	for i in range(_profile_buttons.size()):
		var btn := _profile_buttons[i]
		if i >= player_count:
			continue
		var cx: int = centers[i]
		btn.position = Vector2(cx - SLOT_WIDTH / 2, SLOT_Y + SLOT_HEIGHT + 2)
		btn.size = Vector2(SLOT_WIDTH, 14)
		btn.add_theme_font_size_override("font_size", 5)


func _get_frames_for_character(index: int) -> SpriteFrames:
	if index < _character_sprite_frames.size() and _character_sprite_frames[index] != null:
		return _character_sprite_frames[index]
	return _default_sprite_frames


func _get_anim_name(frames: SpriteFrames) -> String:
	if frames.has_animation("idle"):
		return "idle"
	return "default"


func _get_preview_scale(frames: SpriteFrames, anim_name: String) -> float:
	var tex: Texture2D = frames.get_frame_texture(anim_name, 0)
	if tex:
		return PREVIEW_FIT_HEIGHT / tex.get_size().y
	return 0.25


func _stop_active_pulse() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null
