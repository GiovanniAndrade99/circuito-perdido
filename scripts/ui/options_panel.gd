class_name OptionsPanel
extends PanelContainer
## Responsável: Carlos Eduardo Peraçolli
## Painel de opções (volume da música, dos efeitos e tela cheia), usado no
## menu principal e no menu de pausa. As escolhas são salvas pelo SaveManager.

signal closed

var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen: CheckButton


func _ready() -> void:
	theme = UITheme.get_theme()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	box.add_child(UITheme.make_label("OPÇÕES", 36, UITheme.COLOR_ACCENT_LIGHT))

	_music_slider = _add_slider(box, "Música", SaveManager.get_value("music_volume", 0.7))
	_music_slider.value_changed.connect(func(v: float) -> void:
		AudioManager.set_bus_volume("Music", v)
		SaveManager.set_value("music_volume", v))

	_sfx_slider = _add_slider(box, "Efeitos sonoros", SaveManager.get_value("sfx_volume", 0.8))
	_sfx_slider.value_changed.connect(func(v: float) -> void:
		AudioManager.set_bus_volume("SFX", v)
		SaveManager.set_value("sfx_volume", v)
		AudioManager.play_sfx("cell"))

	_fullscreen = CheckButton.new()
	_fullscreen.text = "Tela cheia"
	_fullscreen.button_pressed = SaveManager.get_value("fullscreen", false)
	_fullscreen.toggled.connect(func(on: bool) -> void:
		AudioManager.play_sfx("ui_click")
		SaveManager.set_fullscreen(on))
	box.add_child(_fullscreen)

	box.add_child(UITheme.make_button("Voltar", close))


func open() -> void:
	visible = true
	_music_slider.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _add_slider(parent: Control, title: String, value: float) -> HSlider:
	parent.add_child(UITheme.make_label(title, 20, UITheme.COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(380, 28)
	slider.mouse_entered.connect(slider.grab_focus)
	parent.add_child(slider)
	return slider
