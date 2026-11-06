extends CanvasLayer
## Responsável: Carlos Eduardo Peraçolli
## Menu de pausa (Esc / P / Start). Pausa a árvore de cena inteira; este nó
## continua funcionando por usar PROCESS_MODE_ALWAYS.

var _menu: Control
var _options: OptionsPanel
var _first_button: Button


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.05, 0.1, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := UITheme.make_center()
	center.theme = UITheme.get_theme()
	add_child(center)

	_menu = PanelContainer.new()
	center.add_child(_menu)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_menu.add_child(box)
	box.add_child(UITheme.make_label("PAUSADO", 44, UITheme.COLOR_ACCENT_LIGHT))
	_first_button = UITheme.make_button("Continuar", _resume)
	box.add_child(_first_button)
	box.add_child(UITheme.make_button("Opções", _open_options))
	box.add_child(UITheme.make_button("Reiniciar fase", _restart))
	box.add_child(UITheme.make_button("Menu principal", _to_menu))

	_options = OptionsPanel.new()
	_options.visible = false
	_options.closed.connect(func() -> void:
		_menu.visible = true
		_first_button.grab_focus())
	center.add_child(_options)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		get_viewport().set_input_as_handled()
		_resume()
	elif GameManager.in_level and not get_tree().paused:
		get_viewport().set_input_as_handled()
		_open()


func _open() -> void:
	visible = true
	_menu.visible = true
	_options.visible = false
	get_tree().paused = true
	AudioManager.play_sfx("ui_click")
	_first_button.grab_focus()


func _resume() -> void:
	visible = false
	get_tree().paused = false


func _open_options() -> void:
	_menu.visible = false
	_options.open()


func _restart() -> void:
	visible = false
	GameManager.restart_level()


func _to_menu() -> void:
	visible = false
	GameManager.go_to_menu()
