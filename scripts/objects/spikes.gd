extends Hitbox
## Responsável: Carlos Eduardo Peraçolli
## Fileira de espinhos: Hitbox persistente na camada "perigos".

@export var length := 1  ## comprimento em tiles


func _ready() -> void:
	collision_layer = Layers.HAZARD
	collision_mask = 0
	monitoring = false
	persistent = true
	damage = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(length * 32.0 - 10.0, 14.0)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, 8)
	add_child(collision)
	for i in length:
		var spike := Sprite2D.new()
		spike.texture = SpriteLib.texture("tiles", SpriteLib.TILE_SPIKES)
		spike.position = Vector2((i - (length - 1) * 0.5) * 32.0, 0)
		add_child(spike)
