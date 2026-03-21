extends Control

# The ButtonBox VBoxContainer is defined in main_menu.tscn.
# Buttons are added to it at runtime by _build_buttons().
@onready var button_box: VBoxContainer = $ButtonBox


func _ready() -> void:
	_build_buttons()


# To add a new menu button, call _make_menu_btn() and connect its pressed signal here.
func _build_buttons() -> void:
	var play_btn := _make_menu_btn("PLAY")
	play_btn.pressed.connect(_on_play)
	button_box.add_child(play_btn)

	var settings_btn := _make_menu_btn("SETTINGS")
	settings_btn.pressed.connect(_on_settings)
	button_box.add_child(settings_btn)


# All button visuals (colors, border, font) come from menu_theme.tres on the root Control.
# Change custom_minimum_size.y to adjust button height.
# Change font_size here to resize button text.
func _make_menu_btn(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 24)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 10)
	return btn


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")
