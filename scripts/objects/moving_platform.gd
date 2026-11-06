extends AnimatableBody2D
## Responsável: Carlos Eduardo Peraçolli
## Plataforma móvel (atravessável por baixo). Vai e volta entre a posição
## inicial e "offset" com movimento suave (cosseno). O AnimatableBody2D
## carrega o jogador junto automaticamente.

@export var offset := Vector2(128, 0)
@export var duration := 2.4   ## tempo de ida (s)
@export var width_tiles := 3

var _start := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	sync_to_physics = true
	_start = position
	var width := width_tiles * 32.0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 14)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -9)
	collision.one_way_collision = true
	add_child(collision)
	for i in width_tiles:
		var piece := Sprite2D.new()
		piece.texture = SpriteLib.texture("tiles", SpriteLib.TILE_MOVING_PLATFORM)
		piece.position = Vector2((i - (width_tiles - 1) * 0.5) * 32.0, 0)
		add_child(piece)


func _physics_process(delta: float) -> void:
	_time += delta
	var t := (1.0 - cos(_time / duration * PI)) * 0.5  # 0 -> 1 -> 0 suavemente
	position = _start + offset * t
