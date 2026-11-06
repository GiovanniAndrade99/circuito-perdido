class_name GameBackground
extends ParallaxBackground
## Responsável: Carlos Eduardo Peraçolli
## Fundo com efeito parallax (camadas que se movem em velocidades diferentes
## da câmera, dando profundidade). Tudo é desenhado por código: céu em
## degradê, silhuetas de prédios da fábrica e uma camada de tubulações.

@export var sky_top := Color("1a1c2c")
@export var sky_bottom := Color("29366f")
@export var auto_scroll := 0.0  ## rolagem automática (usada no menu)

const WIDTH := 1280.0
const HEIGHT := 720.0


func _ready() -> void:
	_add_layer(Vector2.ZERO, _Painter.Kind.SKY, false)
	_add_layer(Vector2(0.15, 0.0), _Painter.Kind.FAR, true)
	_add_layer(Vector2(0.4, 0.0), _Painter.Kind.MID, true)


func _process(delta: float) -> void:
	if auto_scroll != 0.0:
		scroll_offset.x -= auto_scroll * delta


func _add_layer(motion: Vector2, kind: int, mirror: bool) -> void:
	var layer := ParallaxLayer.new()
	layer.motion_scale = motion
	if mirror:
		layer.motion_mirroring = Vector2(WIDTH, 0)
	var painter := _Painter.new()
	painter.kind = kind
	painter.sky_top = sky_top
	painter.sky_bottom = sky_bottom
	layer.add_child(painter)
	add_child(layer)


## Nó que desenha uma camada do fundo.
class _Painter extends Node2D:
	enum Kind { SKY, FAR, MID }
	var kind := Kind.SKY
	var sky_top := Color.BLACK
	var sky_bottom := Color.BLACK

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7 + kind
		match kind:
			Kind.SKY:
				draw_polygon(
					PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)]),
					PackedColorArray([sky_top, sky_top, sky_bottom, sky_bottom]))
			Kind.FAR:
				# Prédios da fábrica com janelas acesas.
				var building := sky_top.lerp(Color("333c57"), 0.5)
				var x := 0.0
				while x < 1280.0:
					var w := rng.randf_range(80, 180)
					var h := rng.randf_range(160, 380)
					draw_rect(Rect2(x, 720 - h, w - 6, h), building)
					for wy in range(int(720 - h + 20), 700, 34):
						for wx in range(int(x + 12), int(x + w - 20), 26):
							if rng.randf() < 0.3:
								draw_rect(Rect2(wx, wy, 8, 12), Color(1.0, 0.8, 0.46, 0.35))
					# chaminé
					if rng.randf() < 0.5:
						draw_rect(Rect2(x + w * 0.3, 720 - h - 60, 18, 60), building)
					x += w
			Kind.MID:
				# Pilares, vigas e engrenagens mais próximos.
				var color := sky_bottom.lerp(Color("1a1c2c"), 0.55)
				for i in 5:
					var px := i * 256.0 + 40.0
					draw_rect(Rect2(px, 120, 34, 600), color)
					draw_rect(Rect2(px - 10, 120, 54, 16), color)
				draw_rect(Rect2(0, 150, 1280, 14), color)
				draw_rect(Rect2(0, 230, 1280, 6), color)
				for i in 3:
					var center := Vector2(rng.randf_range(100, 1180), rng.randf_range(300, 520))
					var radius := rng.randf_range(40, 70)
					draw_circle(center, radius, color)
					for t in 8:
						var dir := Vector2.from_angle(TAU * t / 8.0)
						draw_rect(Rect2(center + dir * radius - Vector2(9, 9), Vector2(18, 18)), color)
					draw_circle(center, radius * 0.35, sky_bottom.lerp(color, 0.5))
