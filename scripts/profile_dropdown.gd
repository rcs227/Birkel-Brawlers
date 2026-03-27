class_name ProfileDropdown
extends OptionButton

signal profile_selected(profile_name: String)

var _placeholder_text: String = "choose your profile"


func _ready() -> void:
	refresh()
	item_selected.connect(_on_item_selected)


func refresh() -> void:
	var previous := get_selected_profile()
	clear()
	add_item(_placeholder_text)
	for p in SaveManager.get_profile_names():
		add_item(p)
	var restore_idx := 0
	for i in range(item_count):
		if get_item_text(i) == previous:
			restore_idx = i
			break
	select(restore_idx)


func get_selected_profile() -> String:
	if selected <= 0:
		return ""
	return get_item_text(selected)


func _on_item_selected(index: int) -> void:
	if index <= 0:
		profile_selected.emit("")
	else:
		profile_selected.emit(get_item_text(index))
