extends Node
## Responsável: Carlos Eduardo Peraçolli
## Autoload "SaveManager": salva recorde e configurações em user://save.json
## (no Windows: %APPDATA%/Godot/app_userdata/Circuito Perdido/).

const SAVE_PATH := "user://save.json"

var data := {
	"high_score": 0,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"fullscreen": false,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_data()
	set_fullscreen(data["fullscreen"], false)


func get_value(key: String, default_value: Variant = null) -> Variant:
	return data.get(key, default_value)


func set_value(key: String, value: Variant) -> void:
	data[key] = value
	save_data()


## Registra a pontuação final. Retorna true se for um novo recorde.
func submit_score(score: int) -> bool:
	if score > int(data["high_score"]):
		set_value("high_score", score)
		return true
	return false


func set_fullscreen(enabled: bool, persist: bool = true) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	if persist:
		set_value("fullscreen", enabled)


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		for key in parsed:
			data[key] = parsed[key]


func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
