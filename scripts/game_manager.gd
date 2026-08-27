extends Node

const SAVE_PATH = "user://savegame.json"

var is_new_game: bool = true
var saved_battle_data: Dictionary = {}

func has_saved_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var content := file.get_as_text()
	var json := JSON.new()
	var err := json.parse(content)
	if err == OK and json.data is Dictionary:
		var data: Dictionary = json.data
		var units: Array = data.get("units", [])
		return units.size() > 0
	return false

func start_new_game() -> void:
	is_new_game = true
	saved_battle_data = {}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func continue_game() -> void:
	if not has_saved_game():
		start_new_game()
		return
	is_new_game = false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content := file.get_as_text()
		var json := JSON.new()
		if json.parse(content) == OK and json.data is Dictionary:
			saved_battle_data = json.data
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func save_battle_state(state: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(state, "  "))
	file.close()
	return true

func clear_save() -> void:
	saved_battle_data = {}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
