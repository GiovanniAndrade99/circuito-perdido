extends Hitbox
## Responsável: Giovanni Anicezio Andrade
## Explosão do kamikaze: área de dano circular que existe por um instante.

@export var radius := 46.0
@export var duration := 0.2


func _ready() -> void:
	collision_layer = Layers.HAZARD
	collision_mask = 0
	monitoring = false
	persistent = true
	damage = 1
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	Fx.explosion(self, global_position, 1.6)
	AudioManager.play_sfx("explosion", 0.1)
	GameManager.request_shake(8.0)
	await get_tree().create_timer(duration, false).timeout
	queue_free()
