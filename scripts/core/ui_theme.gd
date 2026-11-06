class_name UITheme
## Responsável: Carlos Eduardo Peraçolli
## Tema visual único de toda a interface (botões, painéis, rótulos) e
## funções auxiliares para criar elementos com o mesmo estilo.

const COLOR_BG := Color("1a1c2c")
const COLOR_PANEL := Color("29366f")
const COLOR_ACCENT := Color("41a6f6")
const COLOR_ACCENT_LIGHT := Color("73eff7")
const COLOR_TEXT := Color("f4f4f4")
const COLOR_WARNING := Color("ffcd75")
const COLOR_DANGER := Color("e04a5f")
const COLOR_GOOD := Color("a7f070")

static var _theme: Theme = null


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var theme := Theme.new()
	theme.default_font_size = 22

	theme.set_stylebox("normal", "Button", _box(COLOR_PANEL, COLOR_ACCENT, 2))
	theme.set_stylebox("hover", "Button", _box(Color("3b5dc9"), COLOR_ACCENT_LIGHT, 3))
	theme.set_stylebox("focus", "Button", _box(Color("3b5dc9"), COLOR_ACCENT_LIGHT, 3))
	theme.set_stylebox("pressed", "Button", _box(COLOR_ACCENT, COLOR_TEXT, 3))
	theme.set_stylebox("disabled", "Button", _box(Color("333c57"), Color("566c86"), 2))
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		theme.set_color(state, "Button", COLOR_TEXT)

	var panel := _box(Color(0.10, 0.11, 0.17, 0.94), COLOR_ACCENT, 3)
	panel.content_margin_left = 28
	panel.content_margin_right = 28
	panel.content_margin_top = 22
	panel.content_margin_bottom = 22
	theme.set_stylebox("panel", "PanelContainer", panel)

	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_color("font_outline_color", "Label", COLOR_BG)
	theme.set_constant("outline_size", "Label", 4)

	theme.set_color("font_color", "CheckButton", COLOR_TEXT)
	theme.set_color("font_hover_color", "CheckButton", COLOR_ACCENT_LIGHT)
	theme.set_color("font_focus_color", "CheckButton", COLOR_ACCENT_LIGHT)
	_theme = theme
	return theme


static func _box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(6)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


## Botão padrão com sons de foco/clique. O mouse também move o foco, assim
## teclado, gamepad e mouse destacam o botão da mesma forma.
static func make_button(text: String, on_pressed: Callable, min_width: float = 340.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 52)
	button.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		on_pressed.call())
	button.mouse_entered.connect(button.grab_focus)
	button.focus_entered.connect(func() -> void: AudioManager.play_sfx("ui_hover"))
	return button


static func make_label(text: String, size: int = 22, color: Color = COLOR_TEXT,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if size >= 40:
		label.add_theme_constant_override("outline_size", 10)
	return label


## Container de tela inteira que centraliza o conteúdo.
static func make_center() -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return center
