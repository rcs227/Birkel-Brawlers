extends Control

# The VBox inside SettingsPanel is defined in settings.tscn.
# All rows are built dynamically at runtime and added to it.
@onready var settings_box: VBoxContainer = $SettingsPanel/VBox

# These track the actual current state of each setting.
# _master_vol is read from AudioServer on _ready so it reflects the real volume.
var _master_vol: int = 100
var _fullscreen: bool = true
var _vsync: bool = false

# References held so we can update the labels/buttons when values change.
var _vol_value_label: Label
var _fullscreen_btn: Button
var _vsync_btn: Button

# Edit these constants to change the color scheme across all settings UI.
const BROWN_PRIMARY := Color(0.45, 0.28, 0.12, 1)
const BROWN_DARK := Color(0.25, 0.14, 0.05, 1)
const BROWN_MUTED := Color(0.6, 0.45, 0.28, 1)
const WARM_WHITE := Color(0.98, 0.95, 0.9, 1)


func _ready() -> void:
	# Read real system state so the UI matches what is actually active.
	_master_vol = roundi(db_to_linear(AudioServer.get_bus_volume_db(0)) * 100)
	_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_vsync = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	_build_settings()


# To add a new setting, call _add_volume_row() or _add_toggle_row() here
# and connect the returned button/labels to your logic.
func _build_settings() -> void:
	var vol := _add_volume_row("MASTER VOLUME", _master_vol)
	_vol_value_label = vol["value"]
	vol["left"].pressed.connect(func(): _adjust_volume(-10))
	vol["right"].pressed.connect(func(): _adjust_volume(10))

	_fullscreen_btn = _add_toggle_row("FULLSCREEN", _fullscreen)
	_fullscreen_btn.pressed.connect(_toggle_fullscreen)

	_vsync_btn = _add_toggle_row("VSYNC", _vsync)
	_vsync_btn.pressed.connect(_toggle_vsync)

	# Thin separator line above the back button.
	var sep := ColorRect.new()
	sep.color = Color(BROWN_PRIMARY, 0.3)
	sep.custom_minimum_size = Vector2(0, 1)
	settings_box.add_child(sep)

	var back_btn := _make_back_btn()
	back_btn.pressed.connect(_on_back)
	settings_box.add_child(back_btn)


# Creates a row with a label, < and > arrow buttons, and a value label in between.
# Returns a dict with keys "value" (Label), "left" (Button), "right" (Button).
# Change font_size overrides here to resize text in volume rows.
func _add_volume_row(label_text: String, initial: int) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", BROWN_PRIMARY)
	row.add_child(label)

	var left_btn := _make_arrow_btn("<")
	row.add_child(left_btn)

	# This label shows the current numeric value and is updated by _adjust_volume().
	var value_label := Label.new()
	value_label.text = str(initial)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(28, 0)
	value_label.add_theme_font_size_override("font_size", 7)
	value_label.add_theme_color_override("font_color", BROWN_DARK)
	row.add_child(value_label)

	var right_btn := _make_arrow_btn(">")
	row.add_child(right_btn)

	settings_box.add_child(row)
	return {"value": value_label, "left": left_btn, "right": right_btn}


# Creates a row with a label and a single ON/OFF button.
# Returns the button so the caller can connect its pressed signal.
func _add_toggle_row(label_text: String, initial: bool) -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", BROWN_PRIMARY)
	row.add_child(label)

	# custom_minimum_size controls the width/height of the toggle button.
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(32, 16)
	btn.add_theme_font_size_override("font_size", 7)
	_apply_toggle_look(btn, initial)
	row.add_child(btn)

	settings_box.add_child(row)
	return btn


# Swaps the button's colors and text between ON and OFF states.
# ON = brown bg with white text. OFF = white bg with muted brown text.
# Edit the _make_style() calls here to change the toggle button appearance.
func _apply_toggle_look(btn: Button, active: bool) -> void:
	if active:
		btn.text = "ON"
		btn.add_theme_stylebox_override("normal", _make_style(
			BROWN_PRIMARY, Color(0.08, 0.05, 0.02, 1), 1))
		btn.add_theme_stylebox_override("hover", _make_style(
			Color(0.57, 0.37, 0.17, 1), Color(0.08, 0.05, 0.02, 1), 1))
		btn.add_theme_color_override("font_color", WARM_WHITE)
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_pressed_color", Color(0.88, 0.82, 0.72, 1))
	else:
		btn.text = "OFF"
		btn.add_theme_stylebox_override("normal", _make_style(
			WARM_WHITE, BROWN_MUTED, 1))
		btn.add_theme_stylebox_override("hover", _make_style(
			Color(0.93, 0.88, 0.8, 1), BROWN_PRIMARY, 1))
		btn.add_theme_color_override("font_color", BROWN_MUTED)
		btn.add_theme_color_override("font_hover_color", BROWN_PRIMARY)
		btn.add_theme_color_override("font_pressed_color", BROWN_DARK)


# Small < or > button used in the volume row.
# custom_minimum_size controls its width and height.
func _make_arrow_btn(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(16, 16)
	btn.add_theme_font_size_override("font_size", 7)
	return btn


# Full-width back button at the bottom of the panel.
# Change custom_minimum_size.y or font_size to resize it.
func _make_back_btn() -> Button:
	var btn := Button.new()
	btn.text = "BACK"
	btn.custom_minimum_size = Vector2(0, 18)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 8)
	return btn


# Shared helper that builds a StyleBoxFlat with a solid bg, colored border, and inner padding.
# width is the border thickness in pixels. content_margin_* controls inner padding.
func _make_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = 2.0
	s.content_margin_right = 2.0
	s.content_margin_top = 2.0
	s.content_margin_bottom = 2.0
	return s


# Volume steps by 10 each click. Change the delta values in _build_settings() to adjust step size.
# Clamped to 0-100. AudioServer bus 0 is the Master bus.
func _adjust_volume(delta: int) -> void:
	_master_vol = clampi(_master_vol + delta, 0, 100)
	_vol_value_label.text = str(_master_vol)
	AudioServer.set_bus_volume_db(0, linear_to_db(_master_vol / 100.0))


func _toggle_fullscreen() -> void:
	_fullscreen = not _fullscreen
	if _fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_apply_toggle_look(_fullscreen_btn, _fullscreen)


func _toggle_vsync() -> void:
	_vsync = not _vsync
	if _vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_apply_toggle_look(_vsync_btn, _vsync)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
