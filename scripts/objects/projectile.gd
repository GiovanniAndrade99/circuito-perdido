class_name Projectile
extends Hitbox
## Responsável: Giovanni Anicezio Andrade
## Projétil em linha reta (tiro do jogador e dos inimigos). É uma Hitbox não
## persistente: acerta uma Hurtbox e some; também some ao bater no cenário.

@export var speed := 620.0
@export var lifetime := 1.2
@export var animation := "shot_player"
@export var impact_color := Color("73eff7")

var direction := Vector2.RIGHT
var _done := false

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	persistent = false
	z_index = 6
	sprite.sprite_frames = SpriteLib.frames("items")
	sprite.play(animation)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Só o cenário (camada "mundo") bloqueia o tiro.
	if body is TileMapLayer or (body is CollisionObject2D and body.get_collision_layer_value(1)):
		_impact()


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		_impact()


func _impact() -> void:
	if _done:
		return
	_done = true
	Fx.burst(self, global_position, impact_color, 6, 90.0, 0.25, 0.0, 3.0)
	queue_free()
