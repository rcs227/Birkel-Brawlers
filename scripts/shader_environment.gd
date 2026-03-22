@tool
extends CanvasLayer

## Path to the Node2D (or Marker2D) that acts as the movable sun position.
## Assign this to the "Sun" node in the scene to drive the shader's light source.
@export_node_path("Node2D") var sun_path: NodePath:
	set(value):
		sun_path = value
		_sync_sun_pos()

@export_group("Sun Light")
@export var sun_color: Color = Color(1.0, 0.88, 0.55, 1.0):
	set(value):
		sun_color = value
		_set_param("sun_color", value)

@export_range(0.0, 5.0, 0.05) var sun_intensity: float = 2.0:
	set(value):
		sun_intensity = value
		_set_param("sun_intensity", value)

@export_range(0.01, 2.0, 0.01) var sun_radius: float = 1.0:
	set(value):
		sun_radius = value
		_set_param("sun_radius", value)

@export_group("Ambient")
@export var ambient_color: Color = Color(0.12, 0.08, 0.22, 1.0):
	set(value):
		ambient_color = value
		_set_param("ambient_color", value)

@export_range(0.0, 2.0, 0.05) var ambient_intensity: float = 0.7:
	set(value):
		ambient_intensity = value
		_set_param("ambient_intensity", value)

@export_group("Vignette")
@export_range(0.0, 3.0, 0.05) var vignette_intensity: float = 1.4:
	set(value):
		vignette_intensity = value
		_set_param("vignette_intensity", value)

@export_range(0.01, 1.0, 0.01) var vignette_smoothness: float = 0.45:
	set(value):
		vignette_smoothness = value
		_set_param("vignette_smoothness", value)

@export_group("Color Grading")
@export_range(0.5, 2.0, 0.01) var contrast: float = 1.15:
	set(value):
		contrast = value
		_set_param("contrast", value)

@export_range(0.0, 2.0, 0.01) var saturation: float = 0.8:
	set(value):
		saturation = value
		_set_param("saturation", value)

@export var tint_color: Color = Color(0.88, 0.82, 1.0, 1.0):
	set(value):
		tint_color = value
		_set_param("tint_color", value)

@export_group("God Rays")
@export_range(0.0, 1.0, 0.01) var ray_intensity: float = 0.2:
	set(value):
		ray_intensity = value
		_set_param("ray_intensity", value)

# Canvas size used to convert world-space positions to UV (0-1)
var CANVAS_SIZE := Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width", 320),
	ProjectSettings.get_setting("display/window/size/viewport_height", 180)
)

var _rect: ColorRect


func _ready() -> void:
	_rect = get_node_or_null("ColorRect") as ColorRect
	_push_all_params()


func _process(_delta: float) -> void:
	_sync_sun_pos()


func _sync_sun_pos() -> void:
	if sun_path.is_empty():
		return
	var sun := get_node_or_null(sun_path) as Node2D
	if sun == null:
		return
	var sun_uv := sun.global_position / CANVAS_SIZE
	_set_param("sun_position", sun_uv)


func _push_all_params() -> void:
	_set_param("sun_color", sun_color)
	_set_param("sun_intensity", sun_intensity)
	_set_param("sun_radius", sun_radius)
	_set_param("ambient_color", ambient_color)
	_set_param("ambient_intensity", ambient_intensity)
	_set_param("vignette_intensity", vignette_intensity)
	_set_param("vignette_smoothness", vignette_smoothness)
	_set_param("contrast", contrast)
	_set_param("saturation", saturation)
	_set_param("tint_color", tint_color)
	_set_param("ray_intensity", ray_intensity)


func _set_param(param: String, value: Variant) -> void:
	if _rect == null:
		_rect = get_node_or_null("ColorRect") as ColorRect
	if _rect and _rect.material:
		(_rect.material as ShaderMaterial).set_shader_parameter(param, value)
