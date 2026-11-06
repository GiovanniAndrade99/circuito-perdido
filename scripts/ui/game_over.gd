extends Control
## Responsável: Carlos Eduardo Peraçolli
## Tela de derrota (sem vidas): tentar a fase novamente ou voltar ao menu.


func _ready() -> void:
	theme = UITheme.get_theme()
	var bg := ColorRect.new()
	bg.color = Color("1a1c2c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := UITheme.make_center()
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	box.add_child(UITheme.make_label("FIM DE JOGO", 72, UITheme.COLOR_DANGER))
	box.add_child(UITheme.make_label("VOLT ficou sem energia...", 24))
	box.add_child(UITheme.make_label("Pontos: %d" % GameManager.score, 26, UITheme.COLOR_WARNING))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	box.add_child(spacer)
	var retry := UITheme.make_button("Tentar novamente", GameManager.retry_level)
	box.add_child(retry)
	box.add_child(UITheme.make_button("Menu principal", GameManager.go_to_menu))
	AudioManager.stop_music()
	AudioManager.play_sfx("game_over")
	retry.grab_focus()
