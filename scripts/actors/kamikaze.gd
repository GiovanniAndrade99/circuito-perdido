extends EnemyBase
## Responsável: Giovanni Anicezio Andrade
## Drone kamikaze: flutua parado até detectar o jogador, então o persegue e
## explode ao chegar perto (ou quando o pavio acaba). Derrubá-lo com um tiro
## antes disso dá pontos.

const EXPLOSION_SCENE := preload("res://scenes/objects/Explosion.tscn")

@export var detection_range := 280.0
@export var speed := 150.0
@export var steering := 380.0      ## quão rápido muda de direção
@export var fuse_time := 4.0
@export var trigger_distance := 34.0

var _chasing := false
var _fuse := 0.0
var _time := 0.0


func _setup() -> void:
	sprite.sprite_frames = SpriteLib.frames("kamikaze")
	sprite.play("idle")
	_time = randf() * TAU


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_time += delta
	var player := get_player()
	if not _chasing:
		velocity = Vector2(0, sin(_time * 3.0) * 20.0)  # flutuando
		if player_alive(player) and global_position.distance_to(player.global_position) < detection_range:
			_chasing = true
			sprite.play("chase")
			AudioManager.play_sfx("boss_charge", 0.1, -10.0)
	else:
		_fuse += delta
		if player_alive(player):
			var desired := (player.global_position - global_position).normalized() * speed
			velocity = velocity.move_toward(desired, steering * delta)
			if global_position.distance_to(player.global_position) < trigger_distance:
				explode()
				return
		if _fuse >= fuse_time:
			explode()
			return
	move_and_slide()


func explode() -> void:
	if is_dead:
		return
	var explosion: Node2D = EXPLOSION_SCENE.instantiate()
	explosion.position = global_position
	get_parent().add_child.call_deferred(explosion)
	score_value = 0  # explodir sozinho não dá pontos
	die()
