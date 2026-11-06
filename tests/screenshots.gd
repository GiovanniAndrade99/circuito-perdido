extends Node
## Responsável: Carlos Eduardo Peraçolli
## Ferramenta de verificação visual: percorre cada fase e salva capturas de tela.
## Uso: Godot_v4.3-stable_win64_console.exe --path . res://tests/Screenshots.tscn
const OUT := "user://screenshots"  ## %APPDATA%/Godot/app_userdata/Circuito Perdido/screenshots

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	get_tree().current_scene = null
	await get_tree().process_frame
	for path in ["res://scenes/main/MainMenu.tscn"]:
		get_tree().change_scene_to_file(path)
		for i in 40: await get_tree().process_frame
		_save("menu")
	for i in GameManager.LEVELS.size():
		GameManager.reset_run()
		GameManager.prepare_level(i)
		get_tree().change_scene_to_file(GameManager.LEVELS[i])
		for f in 10: await get_tree().process_frame
		var level := get_tree().current_scene as LevelBase
		level.player.set_physics_process(false)
		var x := 640.0
		var n := 0
		while true:
			level.player.global_position = Vector2(x, 400)
			level.player.camera.reset_smoothing()
			for f in 30: await get_tree().process_frame
			_save("level%d_%d" % [i, n])
			n += 1
			if x + 640.0 >= level.map_size.x * 32:
				break
			x += 1280.0
	get_tree().quit()

func _save(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(OUT + "/" + name + ".png")
	print("salvo ", name)
