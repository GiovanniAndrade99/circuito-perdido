extends Control
## Responsável: Carlos Eduardo Peraçolli
## Menu principal: Jogar, Opções, Créditos e Sair.

const CREDITS_SCENE := "res://scenes/main/Credits.tscn"

var _menu: VBoxContainer
var _options: OptionsPanel
var _play_button: Button
var _title: Label


func _ready() -> void:
	theme = UITheme.get_theme()
	var background := GameBackground.new()
	background.auto_scroll = 40.0
	add_child(background)

	# Robô correndo como enfeite.
	var robot := AnimatedSprite2D.new()
	robot.sprite_frames = SpriteLib.frames("player")
	robot.play("run")
	robot.scale = Vector2(4, 4)
	robot.position = Vector2(1010, 470)
	add_child(robot)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var top := MarginContainer.new()
	top.add_theme_constant_override("margin_top", 70)
	root.add_child(top)
	var title_box := VBoxContainer.new()
	top.add_child(title_box)
	_title = UITheme.make_label("CIRCUITO PERDIDO", 72, UITheme.COLOR_ACCENT_LIGHT)
	title_box.add_child(_title)
	title_box.add_child(UITheme.make_label("Ajude VOLT a recuperar os núcleos de energia e escapar da fábrica", 22))

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 12)
	center.add_child(_menu)
	_play_button = UITheme.make_button("Jogar", _on_play)
	_menu.add_child(_play_button)
	_menu.add_child(UITheme.make_button("Opções", _on_options))
	_menu.add_child(UITheme.make_button("Créditos", func() -> void: SceneLoader.change_scene(CREDITS_SCENE)))
	_menu.add_child(UITheme.make_button("Sair", func() -> void: get_tree().quit()))

	_options = OptionsPanel.new()
	_options.visible = false
	_options.closed.connect(func() -> void:
		_menu.visible = true
		_play_button.grab_focus())
	center.add_child(_options)

	var footer := MarginContainer.new()
	footer.add_theme_constant_override("margin_bottom", 18)
	root.add_child(footer)
	var footer_box := VBoxContainer.new()
	footer.add_child(footer_box)
	footer_box.add_child(UITheme.make_label("Recorde: %d pontos" % int(SaveManager.get_value("high_score", 0)),
		20, UITheme.COLOR_WARNING))
	footer_box.add_child(UITheme.make_label(
		"A/D ou setas: mover  •  Espaço: pular  •  J ou clique: atirar  •  Esc: pausar", 18))

	AudioManager.play_music("menu")
	_play_button.grab_focus()


func _process(_delta: float) -> void:
	# Leve "respiração" no título.
	var pulse := 1.0 + sin(Time.get_ticks_msec() / 400.0) * 0.02
	_title.pivot_offset = _title.size * 0.5
	_title.scale = Vector2(pulse, pulse)


func _on_play() -> void:
	GameManager.new_game()


func _on_options() -> void:
	_menu.visible = false
	_options.open()
