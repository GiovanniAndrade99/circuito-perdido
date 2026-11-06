extends Control
## Responsável: Carlos Eduardo Peraçolli
## Tela de abertura com os nomes da equipe. Qualquer tecla pula.

const NEXT_SCENE := "res://scenes/main/MainMenu.tscn"

var _done := false


func _ready() -> void:
	theme = UITheme.get_theme()
	var bg := ColorRect.new()
	bg.color = UITheme.COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := UITheme.make_center()
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	box.add_child(UITheme.make_label("Giovanni Anicezio Andrade", 30))
	box.add_child(UITheme.make_label("&", 24, UITheme.COLOR_ACCENT))
	box.add_child(UITheme.make_label("Carlos Eduardo Peraçolli", 30))
	box.add_child(UITheme.make_label("apresentam", 20, UITheme.COLOR_ACCENT_LIGHT))
	box.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(box, "modulate:a", 1.0, 0.8)
	tween.tween_interval(1.6)
	tween.tween_property(box, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_next)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		_next()


func _next() -> void:
	if _done:
		return
	_done = true
	SceneLoader.change_scene(NEXT_SCENE)
