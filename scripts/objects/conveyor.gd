extends StaticBody2D
## Responsável: Carlos Eduardo Peraçolli
## Esteira: bloco sólido cuja "constant_linear_velocity" é transferida pela
## física para quem está em cima (jogador, inimigos e caixas).

@export var speed := 90.0  ## positivo = direita, negativo = esquerda
@export var length := 1    ## comprimento em tiles


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	constant_linear_velocity = Vector2(speed, 0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(length * 32.0, 32.0)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	for i in length:
		var belt := AnimatedSprite2D.new()
		belt.sprite_frames = SpriteLib.frames("tiles")
		belt.play("conveyor")
		belt.flip_h = speed < 0.0
		belt.position = Vector2((i - (length - 1) * 0.5) * 32.0, 0)
		add_child(belt)
