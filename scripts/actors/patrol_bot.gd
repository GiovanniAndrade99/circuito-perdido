extends EnemyBase
## Responsável: Giovanni Anicezio Andrade
## Robô patrulheiro: anda de um lado para o outro e vira ao encontrar uma
## parede ou a beira de uma plataforma (detectadas com RayCast2D).

@export var speed := 70.0

@onready var wall_ray: RayCast2D = $WallRay
@onready var floor_ray: RayCast2D = $FloorRay

var direction := -1


func _setup() -> void:
	sprite.sprite_frames = SpriteLib.frames("patrol")
	sprite.play("move")
	sprite.frame = randi() % 4  # evita que todos andem sincronizados


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	apply_gravity(delta)
	if is_on_floor():
		# Os raios acompanham a direção atual.
		wall_ray.target_position = Vector2(18 * direction, 0)
		floor_ray.position = Vector2(14 * direction, 0)
		wall_ray.force_raycast_update()
		floor_ray.force_raycast_update()
		if wall_ray.is_colliding() or not floor_ray.is_colliding():
			direction = -direction
	velocity.x = direction * speed
	move_and_slide()
	sprite.flip_h = direction < 0
