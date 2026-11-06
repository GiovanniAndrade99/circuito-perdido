extends Area2D
## Responsável: Carlos Eduardo Peraçolli
## Placa de dica do tutorial: mostra um balão de texto quando o jogador chega perto.

@export_multiline var text := ""

var _bubble: PanelContainer
var _tween: Tween

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.sprite_frames = SpriteLib.frames("items")
	sprite.play("sign")
	_build_bubble()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.11, 0.17, 0.92)
	style.border_color = UITheme.COLOR_ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	_bubble.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(300, 0)
	label.add_theme_font_size_override("font_size", 16)
	_bubble.add_child(label)
	_bubble.z_index = 30
	_bubble.modulate.a = 0.0
	_bubble.visible = false
	# Centraliza o balão acima da placa sempre que o tamanho é (re)calculado.
	_bubble.resized.connect(func() -> void:
		_bubble.position = Vector2(-_bubble.size.x * 0.5, -_bubble.size.y - 30.0))
	add_child(_bubble)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_show(true)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_show(false)


func _show(visible_now: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if visible_now:
		_bubble.visible = true
		_tween.tween_property(_bubble, "modulate:a", 1.0, 0.2)
	else:
		_tween.tween_property(_bubble, "modulate:a", 0.0, 0.3)
		_tween.tween_callback(func() -> void: _bubble.visible = false)
