extends Node

const PROFILE_DIR := "user://profiles"
const PROFILE_EXT := ".tres"

func _ready() -> void:
	_ensure_profile_dir()

func get_profile_names() -> Array[String]:
	_ensure_profile_dir()
	var names: Array[String] = []
	var dir := DirAccess.open(PROFILE_DIR)
	if dir == null:
		return names
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(PROFILE_EXT):
			var path := PROFILE_DIR + "/" + file_name
			var data := ResourceLoader.load(path) as ProfileData
			if data and not data.profile_name.is_empty() and not names.has(data.profile_name):
				names.append(data.profile_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	return names

func save_profile(profile_name: String) -> bool:
	var name := profile_name.strip_edges()
	if name.is_empty():
		return false
	_ensure_profile_dir()
	var data := ProfileData.new()
	data.profile_name = name
	var path := _profile_path_for_name(name)
	var result := ResourceSaver.save(data, path)
	return result == OK

func _ensure_profile_dir() -> void:
	var abs_dir := ProjectSettings.globalize_path(PROFILE_DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		return
	DirAccess.make_dir_recursive_absolute(abs_dir)

func _profile_path_for_name(profile_name: String) -> String:
	var safe := ""
	for i in range(profile_name.length()):
		var ch := profile_name[i]
		if ch.is_valid_filename():
			safe += ch
		else:
			safe += "_"
	if safe.is_empty():
		safe = "profile"
	return PROFILE_DIR + "/" + safe + PROFILE_EXT
