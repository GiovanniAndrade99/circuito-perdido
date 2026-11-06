class_name Player
extends CharacterBody2D
## Responsável: Giovanni Anicezio Andrade
## VOLT, o robô controlado pelo jogador.
## Física de plataforma com aceleração/atrito, gravidade maior na queda,
## pulo variável, coyote time e jump buffer, além de uma máquina de estados
## simples que escolhe a animação.

signal died

enum State { IDLE, RUN, JUMP, FALL, HURT, DEAD }

const SHOT_SCENE := preload("res://scenes/objects/PlayerShot.tscn")

@export_group("Movimento")
@export var max_speed := 250.0
@export var acceleration := 2000.0
@export var friction := 2400.0
@export var air_control := 0.7          ## fração da aceleração disponível no ar
@export_group("Pulo")
@export var jump_velocity := -600.0     ## ~3,7 tiles de altura
@export var gravity := 1500.0
@export var fall_gravity_multiplier := 1.25  ## queda mais rápida = pulo mais "firme"
@export var jump_cut_multiplier := 0.45 ## soltar o botão cedo corta o pulo
@export var max_fall_speed := 850.0
@export var coyote_time := 0.1          ## ainda pode pular logo após sair da borda
@export var jump_buffer_time := 0.12    ## aperto um pouco antes de tocar o chão vale
@export_group("Combate")
@export var shoot_cooldown := 0.3
@export var knockback := Vector2(280, -320)
@export var stomp_bounce := -430.0
@export var hurt_time := 0.35
@export var push_force := 70.0          ## impulso por quadro ao empurrar caixas

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var camera: Camera2D = $Camera2D
@onready var muzzle: Marker2D = $Muzzle

var state: State = State.IDLE
var facing := 1
var input_enabled := true
var kill_y := 100000.0  ## abaixo desta altura o jogador caiu num buraco (definido pela fase)

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _shoot_timer := 0.0
var _hurt_timer := 0.0
var _was_on_floor := true
var _shake_strength := 0.0
var _squash_tween: Tween


func _ready() -> void:
	add_to_group("player")
	sprite.sprite_frames = SpriteLib.frames("player")
	sprite.play("idle")
	hurtbox.hit.connect(_on_hurtbox_hit)
	health.damaged.connect(_on_damaged)
	health.died.connect(_die)
	health.health_changed.connect(func(current: int, maximum: int) -> void:
		GameManager.player_health_changed.emit(current, maximum))
	GameManager.camera_shake_requested.connect(shake)
	GameManager.player_health_changed.emit(health.health, health.max_health)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_update_timers(delta)
	_apply_horizontal(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_shoot()
	move_and_slide()
	_push_bodies()
	_check_landing()
	_update_state()
	_update_animation()
	if global_position.y > kill_y:
		_die()


func _process(delta: float) -> void:
	# Tremor de câmera (screen shake) com decaimento.
	if _shake_strength > 0.0:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_strength
		_shake_strength = move_toward(_shake_strength, 0.0, 30.0 * delta)
	else:
		camera.offset = Vector2.ZERO


# ---------------------------------------------------------------------------
# Movimento
# ---------------------------------------------------------------------------
func _update_timers(delta: float) -> void:
	_coyote_timer = coyote_time if is_on_floor() else _coyote_timer - delta
	_jump_buffer_timer -= delta
	_shoot_timer -= delta
	if state == State.HURT:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0:
			state = State.FALL


func _apply_horizontal(delta: float) -> void:
	var direction := 0.0
	if input_enabled and state != State.HURT:
		direction = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
	var accel := acceleration if direction != 0.0 else friction
	if not is_on_floor():
		accel *= air_control
	velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)


func _apply_gravity(delta: float) -> void:
	var g := gravity * (fall_gravity_multiplier if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)


func _handle_jump() -> void:
	if not input_enabled:
		return
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0 and state != State.HURT:
		_jump()
	# Pulo variável: soltar o botão durante a subida corta a velocidade.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func _jump() -> void:
	velocity.y = jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	AudioManager.play_sfx("jump", 0.06)
	Fx.dust(self, global_position + Vector2(0, 16))
	_squash(Vector2(0.75, 1.3))


func _check_landing() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		AudioManager.play_sfx("land", 0.1, -6.0)
		Fx.dust(self, global_position + Vector2(0, 16))
		_squash(Vector2(1.3, 0.75))
	_was_on_floor = on_floor


## Empurra corpos rígidos (caixas) na direção do movimento.
func _push_bodies() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var body := collision.get_collider() as RigidBody2D
		if body == null:
			continue
		var normal := collision.get_normal()
		if absf(normal.x) > 0.5:
			body.apply_central_impulse(Vector2(-normal.x * push_force, 0.0))


# ---------------------------------------------------------------------------
# Combate
# ---------------------------------------------------------------------------
func _handle_shoot() -> void:
	if input_enabled and state != State.HURT and _shoot_timer <= 0.0 and Input.is_action_pressed("shoot"):
		_shoot()


func _shoot() -> void:
	_shoot_timer = shoot_cooldown
	var shot: Projectile = SHOT_SCENE.instantiate()
	shot.direction = Vector2(facing, 0)
	get_parent().add_child(shot)
	shot.global_position = global_position + Vector2(muzzle.position.x * facing, muzzle.position.y)
	AudioManager.play_sfx("shoot", 0.08, -3.0)


func _on_hurtbox_hit(hitbox: Hitbox) -> void:
	if state == State.DEAD:
		return
	# Pisão: caindo e acima do inimigo -> o inimigo leva o dano e o jogador quica.
	if hitbox.stompable and velocity.y > 50.0 and global_position.y < hitbox.global_position.y - 6.0:
		var enemy := hitbox.get_parent()
		if enemy.has_method("stomp"):
			enemy.stomp()
			var bounce_bonus := 1.25 if Input.is_action_pressed("jump") else 1.0
			velocity.y = stomp_bounce * bounce_bonus
			return
	if GameManager.god_mode:
		return
	if health.take_damage(hitbox.damage):
		var away := signf(global_position.x - hitbox.global_position.x)
		if away == 0.0:
			away = -facing
		velocity = Vector2(knockback.x * away, knockback.y)


func _on_damaged(_amount: int) -> void:
	GameManager.notify_player_damaged()
	if health.health <= 0:
		return  # a morte é tratada em _die()
	state = State.HURT
	_hurt_timer = hurt_time
	AudioManager.play_sfx("hurt")
	shake(6.0)


func _die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	hurtbox.set_deferred("monitoring", false)
	sprite.play("hurt")
	sprite.modulate.a = 1.0
	AudioManager.play_sfx("death")
	GameManager.notify_player_damaged()
	shake(10.0)
	Fx.burst(self, global_position, Color("73eff7"), 20, 200.0, 0.8, 200.0, 5.0)
	# Animação de morte: sobe girando e cai para fora da tela.
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", -40.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "rotation", TAU, 0.9)
	tween.tween_property(sprite, "position:y", 300.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.6)
	await tween.finished
	died.emit()
	GameManager.player_died()


func heal(amount: int) -> void:
	health.heal(amount)


func shake(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)


# ---------------------------------------------------------------------------
# Estados e animação
# ---------------------------------------------------------------------------
func _update_state() -> void:
	if state == State.HURT:
		return
	if is_on_floor():
		state = State.RUN if absf(velocity.x) > 10.0 else State.IDLE
	else:
		state = State.JUMP if velocity.y < 0.0 else State.FALL


func _update_animation() -> void:
	sprite.flip_h = facing < 0
	var anim := "idle"
	match state:
		State.RUN:
			anim = "run"
		State.JUMP:
			anim = "jump"
		State.FALL:
			anim = "fall"
		State.HURT:
			anim = "hurt"
	if sprite.animation != anim:
		sprite.play(anim)
	# Pisca enquanto invencível após levar dano.
	if health.is_invincible():
		sprite.modulate.a = 0.3 if (Time.get_ticks_msec() / 70) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0


## Squash & stretch: deforma o sprite e volta ao normal (sensação de peso).
func _squash(target_scale: Vector2) -> void:
	if _squash_tween:
		_squash_tween.kill()
	sprite.scale = target_scale
	_squash_tween = create_tween()
	_squash_tween.tween_property(sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
