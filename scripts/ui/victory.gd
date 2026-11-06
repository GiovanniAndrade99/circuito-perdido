extends Control
## Responsável: Carlos Eduardo Peraçolli
## Tela de vitória com o resumo da partida e indicação de novo recorde.

const CREDITS_SCENE := "res://scenes/main/Credits.tscn"


func _ready() -> void:
	theme = UITheme.get_theme()
	var background := GameBackground.new()
	background.auto_scroll = 60.0
	background.sky_bottom = Color("257179")
	add_child(background)
	var center := UITheme.make_center()
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var result: Dictionary = GameManager.last_result
	box.add_child(UITheme.make_label("VOCÊ VENCEU!", 64, UITheme.COLOR_GOOD))
	box.add_child(UITheme.make_label("VOLT reativou o reator e escapou da fábrica!", 24))
	box.add_child(UITheme.make_label("Pontuação final: %d" % int(result.get("score", 0)), 32, UITheme.COLOR_WARNING))
	if result.get("record", false):
		var record := UITheme.make_label("NOVO RECORDE!", 28, UITheme.COLOR_ACCENT_LIGHT)
		box.add_child(record)
		var tween := create_tween().set_loops()
		tween.tween_property(record, "modulate:a", 0.3, 0.4)
		tween.tween_property(record, "modulate:a", 1.0, 0.4)
	var seconds := int(result.get("time", 0.0))
	box.add_child(UITheme.make_label("Tempo total: %02d:%02d" % [seconds / 60, seconds % 60], 22))
	box.add_child(UITheme.make_label("Células coletadas: %d   •   Núcleos: %d/%d   •   Quedas: %d" % [
		int(result.get("cells", 0)), int(result.get("cores", 0)), GameManager.TOTAL_CORES,
		int(result.get("deaths", 0))], 22))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	box.add_child(spacer)
	var credits := UITheme.make_button("Créditos", func() -> void: SceneLoader.change_scene(CREDITS_SCENE))
	box.add_child(credits)
	box.add_child(UITheme.make_button("Menu principal", GameManager.go_to_menu))

	AudioManager.stop_music(0.2)
	AudioManager.play_sfx("victory")
	get_tree().create_timer(2.0).timeout.connect(func() -> void: AudioManager.play_music("menu"))
	credits.grab_focus()
