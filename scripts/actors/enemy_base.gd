class_name EnemyBase
extends CharacterBody2D
## Responsável: Giovanni Anicezio Andrade
## Classe base de todos os inimigos (herança). Centraliza o que é comum:
## receber dano pela Hurtbox, piscar ao ser atingido, ser pisado e morrer
## com explosão e pontuação. Cada inimigo sobrescreve _setup() e o seu
## próprio _physics_process() com o comportamento (IA).

@export var score_value := 50
@export var gravity := 1200.0
@export var use_gravity := true
@export var stompable := true

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox

var is_dead := false


func _ready() -> void:
	add_to_group("enemies")
	hitbox.stompable = stompable
	hurtbox.hit.connect(_on_hurt)
	health.damaged.connect(_on_damaged)
	health.died.connect(die)
	_setup()


## Gancho para as subclasses configurarem animações e estado inicial.
func _setup() -> void:
	pass


func _on_hurt(attacker: Hitbox) -> void:
	if not is_dead:
		health.take_damage(attacker.damage)


func _on_damaged(_amount: int) -> void:
	flash()
	AudioManager.play_sfx("hit", 0.1)


## Pisca em branco ao levar dano (feedback visual).
func flash() -> void:
	sprite.modulate = Color(4, 4, 4)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


## Chamado pelo jogador ao pular em cima.
func stomp() -> void:
	if not is_dead and stompable:
		health.take_damage(health.health)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	if score_value > 0:
		GameManager.add_score(score_value)
		Fx.popup_text(self, global_position, "+%d" % score_value, UITheme.COLOR_WARNING)
	Fx.explosion(self, global_position)
	AudioManager.play_sfx("enemy_death", 0.1)
	GameManager.request_shake(4.0)
	queue_free()


func apply_gravity(delta: float) -> void:
	if use_gravity and not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 800.0)


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func player_alive(player: Player) -> bool:
	return player != null and player.state != Player.State.DEAD
