## Global singleton that manages the settings overlay from any scene.
## Registered in Project → Project Settings → Autoload as "SettingsManager".
extends Node

## Emitted whenever the hitbox debug visibility is toggled.
signal hitbox_debug_toggled(show: bool)

## Whether in-game hitboxes should draw a visible debug rectangle.
var show_hitboxes: bool = false:
	set(value):
		show_hitboxes = value
		hitbox_debug_toggled.emit(value)

const _SETTINGS_SCENE := preload("res://scenes/settings.tscn")

var _overlay: CanvasLayer = null


func _ready() -> void:
	# Must be ALWAYS so _input() and the overlay keep working while the game
	# tree is paused.  Default is INHERIT which inherits PAUSABLE from root,
	# causing the manager (and every child overlay) to go silent when paused.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("settings"):
		get_viewport().set_input_as_handled()
		if _overlay:
			close_settings()
		else:
			open_settings()


## Open the settings panel as an overlay on top of the current scene.
## Pauses the scene tree so gameplay freezes underneath.
func open_settings() -> void:
	if _overlay:
		return
	get_tree().paused = true

	# PROCESS_MODE_ALWAYS on the CanvasLayer propagates to every child via
	# INHERIT, so all buttons receive _gui_input() even while the tree is paused.
	_overlay = CanvasLayer.new()
	_overlay.layer = 200
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)

	var settings: Control = _SETTINGS_SCENE.instantiate()
	_overlay.add_child(settings)


## Close the settings overlay and resume the scene tree.
func close_settings() -> void:
	if not _overlay:
		return
	get_tree().paused = false
	_overlay.queue_free()
	_overlay = null


## Close settings and navigate to the character selection screen.
## Called by the settings panel's "Return to Character Select" button.
func go_to_character_select() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")
