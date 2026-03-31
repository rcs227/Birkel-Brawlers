class_name CharacterButtonGrid
extends GridContainer

signal character_pressed(index: int)

const BUTTON_ICON_SIZE := Vector2(20, 20)
const BUTTON_ICON_CROP := 0.5


func build(character_count: int, button_textures: Array[Texture2D], names: Array[String]) -> void:
	for child in get_children():
		child.queue_free()
	for i in range(character_count):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(18, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): character_pressed.emit(i))

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(vbox)

		var tex: Texture2D = button_textures[i] if i < button_textures.size() else null
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
		lbl.text = names[i] if i < names.size() else str(i + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)

		add_child(btn)


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
