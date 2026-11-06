extends EnemyBase
## Responsável: Giovanni Anicezio Andrade
## Torreta fixa: quando o jogador entra no alcance, carrega (aviso visual)
## e dispara um projétil mirando nele. Não pode ser pisada.

const SHOT_SCENE := preload("res://scenes/objects/EnemyShot.tscn")

@export var fire_interval := 2.0
@export var detection_range := 430.0
@export var shot_speed := 260.0
@export var charge_time := 0.5  ## tempo de aviso antes do tiro

var _timer := 1.0


func _setup() -> void:
	sprite.sprite_frames = SpriteLib.frames("turret")
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var player := get_player()
	if not player_alive(player):
		_set_anim("idle")
		return
	var to_player := player.global_position - global_position
	sprite.flip_h = to_player.x < 0.0
	if to_player.length() > detection_range:
		_timer = maxf(_timer, charge_time + 0.2)
		_set_anim("idle")
		return
	_timer -= delta
	if _timer <= charge_time:
		_set_anim("charge")
	if _timer <= 0.0:
		_fire(to_player.normalized())
		_timer = fire_interval


func _fire(direction: Vector2) -> void:
	var shot: Projectile = SHOT_SCENE.instantiate()
	shot.direction = direction
	shot.speed = shot_speed
	get_parent().add_child(shot)
	shot.global_position = global_position + Vector2(signf(direction.x) * 14.0, -2.0)
	sprite.play("fire")
	AudioManager.play_sfx("boss_shoot", 0.1, -6.0)


func _set_anim(anim: String) -> void:
	# Não interrompe o quadro de disparo antes de ele aparecer.
	if sprite.animation == "fire" and _timer > fire_interval - 0.2:
		return
	if sprite.animation != anim:
		sprite.play(anim)
