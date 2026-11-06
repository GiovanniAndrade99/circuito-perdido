class_name Fx
## Responsável: Carlos Eduardo Peraçolli
## Efeitos visuais reutilizáveis: partículas, explosões, flashes e textos
## flutuantes. Tudo é adicionado na cena atual (a fase, cuja origem é (0, 0)),
## por isso as posições globais podem ser usadas diretamente.
##
## Os nós são adicionados com call_deferred porque estes efeitos costumam ser
## disparados dentro de callbacks de física (colisões), onde não é permitido
## alterar a árvore de cena diretamente.

static var _light_texture: GradientTexture2D = null


## Explosão de partículas genérica.
static func burst(ref: Node, pos: Vector2, color: Color, amount: int = 12, speed: float = 140.0,
		lifetime: float = 0.5, gravity: float = 300.0, size: float = 4.0) -> void:
	var root := _root(ref)
	if root == null:
		return
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = 0.9
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.gravity = Vector2(0, gravity)
	particles.scale_amount_min = size * 0.5
	particles.scale_amount_max = size
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color, 0.0))
	particles.color_ramp = ramp
	particles.z_index = 10
	particles.position = pos
	particles.emitting = true
	root.add_child.call_deferred(particles)
	root.get_tree().create_timer(lifetime + 0.4, false).timeout.connect(particles.queue_free)


## Poeira dos pés (pulo, pouso).
static func dust(ref: Node, pos: Vector2) -> void:
	burst(ref, pos, Color(0.85, 0.85, 0.95, 0.8), 6, 70.0, 0.35, -30.0, 3.0)


## Explosão com flash (morte de inimigos, chefe).
static func explosion(ref: Node, pos: Vector2, scale: float = 1.0) -> void:
	burst(ref, pos, Color("ffcd75"), int(16 * scale), 220.0 * scale, 0.6, 150.0, 5.0)
	burst(ref, pos, Color("ef7d57"), int(12 * scale), 150.0 * scale, 0.7, 60.0, 6.0)
	flash(ref, pos, 18.0 * scale, Color(1.0, 0.95, 0.8, 0.9))


## Círculo que cresce e some rapidamente.
static func flash(ref: Node, pos: Vector2, radius: float, color: Color) -> void:
	var root := _root(ref)
	if root == null:
		return
	var circle := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 20:
		points.append(Vector2.from_angle(TAU * i / 20.0) * radius)
	circle.polygon = points
	circle.color = color
	circle.position = pos
	circle.z_index = 11
	root.add_child.call_deferred(circle)
	var tween := root.create_tween()
	tween.tween_property(circle, "scale", Vector2(2.2, 2.2), 0.25)
	tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.25)
	tween.tween_callback(circle.queue_free)


## Texto que sobe e desaparece (+10, CHECKPOINT...).
static func popup_text(ref: Node, pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var root := _root(ref)
	if root == null:
		return
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(160, 24)
	label.position = pos - Vector2(80, 36)
	label.z_index = 20
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("1a1c2c"))
	label.add_theme_constant_override("outline_size", 5)
	root.add_child.call_deferred(label)
	var tween := root.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 34, 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tween.tween_callback(label.queue_free)


## Textura radial usada pelas luzes da fase escura.
static func light_texture() -> GradientTexture2D:
	if _light_texture:
		return _light_texture
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	_light_texture = tex
	return tex


static func _root(ref: Node) -> Node:
	if ref == null or not ref.is_inside_tree():
		return null
	return ref.get_tree().current_scene
