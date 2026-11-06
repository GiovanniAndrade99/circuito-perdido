class_name GameHUD
extends CanvasLayer
## Responsável: Carlos Eduardo Peraçolli
## HUD da fase: corações, vidas, células, núcleos, pontuação, tempo, barra
## de vida do chefe, título da fase e mensagens. Atualiza-se ouvindo os
## sinais do GameManager (não precisa conhecer o jogador nem as fases).

var _hearts: HBoxContainer
var _lives_label: Label
var _cells_label: Label
var _cores_label: Label
var _score_label: Label
var _time_label: Label
var _banner: VBoxContainer
var _banner_title: Label
var _banner_subtitle: Label
var _message: Label
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _heart_full: Texture2D
var _heart_empty: Texture2D
var _banner_tween: Tween
var _message_tween: Tween


func _ready() -> void:
	layer = 10
	_heart_full = SpriteLib.texture("items", SpriteLib.ITEM_HEART)
	_heart_empty = SpriteLib.texture("items", SpriteLib.ITEM_HEART_EMPTY)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	add_child(root)
	_build_top_left(root)
	_build_top_right(root)
	_build_center(root)
	_build_boss_bar(root)

	GameManager.score_changed.connect(_on_score_changed)
	GameManager.cells_changed.connect(func(v: int) -> void: _cells_label.text = "x %d" % v)
	GameManager.cores_changed.connect(func(v: int) -> void:
		_cores_label.text = "%d/%d" % [v, GameManager.TOTAL_CORES])
	GameManager.lives_changed.connect(func(v: int) -> void: _lives_label.text = "VOLT x%d" % v)
	GameManager.player_health_changed.connect(_on_health_changed)
	GameManager.boss_health_changed.connect(_on_boss_health_changed)
	GameManager.boss_visibility_changed.connect(func(v: bool) -> void: _boss_box.visible = v)
	GameManager.message_requested.connect(show_message)


func _process(_delta: float) -> void:
	_time_label.text = _format_time(GameManager.level_time)


# ---------------------------------------------------------------------------
# Construção
# ---------------------------------------------------------------------------
func _build_top_left(root: Control) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(20, 12)
	box.add_theme_constant_override("separation", 2)
	root.add_child(box)
	_hearts = HBoxContainer.new()
	box.add_child(_hearts)
	_lives_label = UITheme.make_label("VOLT x3", 18, UITheme.COLOR_ACCENT_LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
	box.add_child(_lives_label)
	var counters := HBoxContainer.new()
	counters.add_theme_constant_override("separation", 6)
	box.add_child(counters)
	counters.add_child(_icon(SpriteLib.ITEM_CELL))
	_cells_label = UITheme.make_label("x 0", 20, UITheme.COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_cells_label.custom_minimum_size.x = 64
	counters.add_child(_cells_label)
	counters.add_child(_icon(SpriteLib.ITEM_CORE))
	_cores_label = UITheme.make_label("0/4", 20, UITheme.COLOR_GOOD, HORIZONTAL_ALIGNMENT_LEFT)
	counters.add_child(_cores_label)


func _build_top_right(root: Control) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(1280 - 320 - 20, 12)
	box.custom_minimum_size = Vector2(320, 0)
	root.add_child(box)
	_score_label = UITheme.make_label("PONTOS 000000", 24, UITheme.COLOR_WARNING, HORIZONTAL_ALIGNMENT_RIGHT)
	box.add_child(_score_label)
	_time_label = UITheme.make_label("00:00", 18, UITheme.COLOR_TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	box.add_child(_time_label)


func _build_center(root: Control) -> void:
	_banner = VBoxContainer.new()
	_banner.position = Vector2(0, 170)
	_banner.custom_minimum_size = Vector2(1280, 0)
	_banner.modulate.a = 0.0
	root.add_child(_banner)
	_banner_title = UITheme.make_label("", 48, UITheme.COLOR_ACCENT_LIGHT)
	_banner.add_child(_banner_title)
	_banner_subtitle = UITheme.make_label("", 24, UITheme.COLOR_TEXT)
	_banner.add_child(_banner_subtitle)

	_message = UITheme.make_label("", 22, UITheme.COLOR_WARNING)
	_message.position = Vector2(140, 580)
	_message.size = Vector2(1000, 60)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.modulate.a = 0.0
	root.add_child(_message)


func _build_boss_bar(root: Control) -> void:
	_boss_box = VBoxContainer.new()
	_boss_box.position = Vector2(340, 652)
	_boss_box.custom_minimum_size = Vector2(600, 0)
	_boss_box.visible = false
	root.add_child(_boss_box)
	_boss_box.add_child(UITheme.make_label("SENTINELA", 18, UITheme.COLOR_DANGER))
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(600, 16)
	_boss_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("1a1c2c")
	bg.border_color = Color("f4f4f4")
	bg.set_border_width_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UITheme.COLOR_DANGER
	_boss_bar.add_theme_stylebox_override("background", bg)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	_boss_box.add_child(_boss_bar)


func _icon(index: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = SpriteLib.texture("items", index)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(32, 32)
	return icon


# ---------------------------------------------------------------------------
# Atualizações
# ---------------------------------------------------------------------------
func _on_score_changed(value: int) -> void:
	_score_label.text = "PONTOS %06d" % value
	# "Pulinho" no contador para chamar atenção.
	_score_label.pivot_offset = _score_label.size * Vector2(1.0, 0.5)
	_score_label.scale = Vector2(1.15, 1.15)
	create_tween().tween_property(_score_label, "scale", Vector2.ONE, 0.15)


func _on_health_changed(current: int, maximum: int) -> void:
	while _hearts.get_child_count() < maximum:
		var heart := TextureRect.new()
		heart.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		heart.custom_minimum_size = Vector2(32, 32)
		_hearts.add_child(heart)
	for i in _hearts.get_child_count():
		var heart := _hearts.get_child(i) as TextureRect
		heart.texture = _heart_full if i < current else _heart_empty


func _on_boss_health_changed(current: int, maximum: int) -> void:
	_boss_bar.max_value = maximum
	var tween := create_tween()
	tween.tween_property(_boss_bar, "value", float(current), 0.2)


## Título grande que aparece e some (início de fase).
func show_banner(title: String, subtitle: String = "", hold: float = 2.2) -> void:
	_banner_title.text = title
	_banner_subtitle.text = subtitle
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.4)
	if hold > 0.0:
		_banner_tween.tween_interval(hold)
		_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


func show_message(text: String, duration: float = 3.5) -> void:
	_message.text = text
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property(_message, "modulate:a", 1.0, 0.2)
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.5)


func show_level_complete(result: Dictionary) -> void:
	var lines := "Tempo %s   •   Bônus de tempo +%d   •   Sem dano +%d" % [
		_format_time(result["time"]), result["time_bonus"], result["damage_bonus"]]
	show_banner("FASE CONCLUÍDA!", lines, 0.0)


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
