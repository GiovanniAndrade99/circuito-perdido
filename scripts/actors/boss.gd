extends EnemyBase
## Responsável: Giovanni Anicezio Andrade
## Chefe final SENTINELA. Máquina de estados:
##   INTRO -> IDLE -> SHOOT (rajadas) -> IDLE -> TELEGRAPH -> CHARGE (investida)
##   -> STUNNED (bate na parede, fica vulnerável) -> RISE -> IDLE ...
## Só recebe dano quando está ATORDOADO; nos outros estados o escudo bloqueia.
## Fica mais rápido abaixo de 66% e 33% de vida.

enum Phase { INTRO, IDLE, SHOOT, TELEGRAPH, CHARGE, STUNNED, RISE, DEAD }

const SHOT_SCENE := preload("res://scenes/objects/EnemyShot.tscn")
const CORE_SCENE := preload("res://scenes/objects/Core.tscn")

@export var idle_time := 1.5
@export var charge_speed := 480.0
@export var stun_time := 2.8
@export var shot_speed := 230.0
@export var hover_height := 300.0    ## altura de voo acima do chão
@export var charge_height := 52.0    ## altura do centro durante a investida

var phase: Phase = Phase.INTRO
var arena_left := 64.0
var arena_right := 1216.0
var floor_y := 608.0

var _timer := 0.0
var _time := 0.0
var _volleys := 0
var _charge_dir := 1
var _next_is_charge := false
var _shield_flash := 0.0


func _setup() -> void:
	add_to_group("boss")
	sprite.sprite_frames = SpriteLib.frames("boss")
	sprite.play("idle")
	health.health_changed.connect(func(current: int, maximum: int) -> void:
		GameManager.boss_health_changed.emit(current, maximum))


## Chamado pela arena com os limites da sala.
func setup_arena(left: float, right: float, floor_position: float) -> void:
	arena_left = left
	arena_right = right
	floor_y = floor_position


func _hover_y() -> float:
	return floor_y - hover_height


## Multiplicador de agressividade conforme a vida restante.
func _rage() -> float:
	var ratio := float(health.health) / float(health.max_health)
	if ratio > 0.66:
		return 1.0
	if ratio > 0.33:
		return 1.3
	return 1.6


func _physics_process(delta: float) -> void:
	if phase == Phase.DEAD:
		return
	_time += delta
	_shield_flash = maxf(_shield_flash - delta, 0.0)
	queue_redraw()
	var player := get_player()
	match phase:
		Phase.INTRO:
			_process_intro(delta)
		Phase.IDLE:
			_hover_follow(player, delta)
			_timer -= delta
			if _timer <= 0.0:
				_choose_attack()
		Phase.SHOOT:
			_hover_follow(player, delta)
			_timer -= delta
			if _timer <= 0.0:
				_fire_volley(player)
		Phase.TELEGRAPH:
			_process_telegraph(player, delta)
		Phase.CHARGE:
			_process_charge(delta)
		Phase.STUNNED:
			_process_stunned(delta)
		Phase.RISE:
			global_position.y = move_toward(global_position.y, _hover_y(), 160.0 * delta)
			if absf(global_position.y - _hover_y()) < 2.0:
				_enter_idle()


# ---------------------------------------------------------------------------
# Estados
# ---------------------------------------------------------------------------
func _process_intro(delta: float) -> void:
	global_position.y = move_toward(global_position.y, _hover_y(), 110.0 * delta)
	if absf(global_position.y - _hover_y()) < 2.0:
		GameManager.boss_visibility_changed.emit(true)
		GameManager.boss_health_changed.emit(health.health, health.max_health)
		GameManager.show_message("Atire no SENTINELA quando ele estiver ATORDOADO!")
		_enter_idle()


func _enter_idle() -> void:
	phase = Phase.IDLE
	_timer = idle_time / _rage()
	sprite.play("idle")
	hitbox.active = true


func _choose_attack() -> void:
	if _next_is_charge:
		phase = Phase.TELEGRAPH
		_timer = 0.9 / _rage()
		sprite.play("charge")
		AudioManager.play_sfx("boss_charge")
	else:
		phase = Phase.SHOOT
		_volleys = 3 if _rage() < 1.5 else 4
		_timer = 0.3
	_next_is_charge = not _next_is_charge


func _fire_volley(player: Player) -> void:
	if not player_alive(player):
		_enter_idle()
		return
	var base_angle := (player.global_position - global_position).angle()
	var spread := [-0.28, 0.0, 0.28] if _rage() < 1.25 else [-0.5, -0.25, 0.0, 0.25, 0.5]
	for offset in spread:
		var shot: Projectile = SHOT_SCENE.instantiate()
		shot.direction = Vector2.from_angle(base_angle + offset)
		shot.speed = shot_speed * (0.9 + 0.2 * _rage())
		get_parent().add_child(shot)
		shot.global_position = global_position + shot.direction * 40.0
	AudioManager.play_sfx("boss_shoot", 0.05)
	_volleys -= 1
	_timer = 0.6 / _rage()
	if _volleys <= 0:
		_enter_idle()


## Desce até a altura do jogador e "treme" antes de investir (aviso).
func _process_telegraph(player: Player, delta: float) -> void:
	var target_y := floor_y - charge_height
	global_position.y = move_toward(global_position.y, target_y, 380.0 * delta)
	sprite.position.x = sin(_time * 60.0) * 3.0
	_timer -= delta
	if _timer <= 0.0 and absf(global_position.y - target_y) < 2.0:
		sprite.position.x = 0.0
		_charge_dir = 1
		if player_alive(player) and player.global_position.x < global_position.x:
			_charge_dir = -1
		phase = Phase.CHARGE


func _process_charge(delta: float) -> void:
	velocity = Vector2(_charge_dir * charge_speed * minf(_rage(), 1.4), 0.0)
	move_and_slide()
	var hit_wall := is_on_wall()
	hit_wall = hit_wall or global_position.x <= arena_left + 48.0 or global_position.x >= arena_right - 48.0
	if hit_wall:
		phase = Phase.STUNNED
		_timer = stun_time
		velocity = Vector2.ZERO
		hitbox.active = false  # atordoado não machuca: o jogador pode chegar perto
		sprite.play("stunned")
		AudioManager.play_sfx("press")
		GameManager.request_shake(12.0)
		Fx.burst(self, global_position + Vector2(_charge_dir * 40, 0), Color("ffcd75"), 16, 200.0, 0.6, 300.0, 4.0)


func _process_stunned(delta: float) -> void:
	# Cai até o chão e fica parado soltando faíscas.
	velocity.x = 0.0
	velocity.y = minf(velocity.y + gravity * delta, 600.0)
	move_and_slide()
	_timer -= delta
	if randf() < 0.08:
		Fx.burst(self, global_position + Vector2(randf_range(-30, 30), -30), Color("ffcd75"), 4, 80.0, 0.4, 200.0, 3.0)
	if _timer <= 0.0:
		phase = Phase.RISE
		velocity = Vector2.ZERO
		sprite.play("idle")
		hitbox.active = true


func _hover_follow(player: Player, delta: float) -> void:
	var target_x := global_position.x
	if player_alive(player):
		target_x = clampf(player.global_position.x, arena_left + 100.0, arena_right - 100.0)
	global_position.x = move_toward(global_position.x, target_x, 90.0 * _rage() * delta)
	global_position.y = _hover_y() + sin(_time * 2.0) * 12.0


# ---------------------------------------------------------------------------
# Dano e morte
# ---------------------------------------------------------------------------
func _on_hurt(attacker: Hitbox) -> void:
	if is_dead:
		return
	if phase == Phase.STUNNED:
		health.take_damage(attacker.damage)
	else:
		_shield_flash = 0.25
		AudioManager.play_sfx("shield", 0.1, -4.0)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	phase = Phase.DEAD
	hitbox.set_deferred("monitorable", false)
	hurtbox.set_deferred("monitoring", false)
	GameManager.add_score(score_value)
	GameManager.boss_visibility_changed.emit(false)
	sprite.play("stunned")
	# Sequência de explosões antes de sumir.
	for i in 6:
		Fx.explosion(self, global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40)), 1.3)
		AudioManager.play_sfx("explosion", 0.15)
		GameManager.request_shake(10.0)
		await get_tree().create_timer(0.25, false).timeout
	Fx.explosion(self, global_position, 2.5)
	Fx.popup_text(self, global_position, "+%d" % score_value, UITheme.COLOR_WARNING)
	# Solta o último núcleo de energia no centro da arena.
	var core: Collectible = CORE_SCENE.instantiate()
	core.key = "boss_core"
	core.position = Vector2((arena_left + arena_right) * 0.5, floor_y - 48.0)
	get_parent().add_child(core)
	GameManager.show_message("O SENTINELA caiu! Pegue o último núcleo.")
	queue_free()


## Desenha o escudo quando um tiro é bloqueado.
func _draw() -> void:
	if _shield_flash > 0.0:
		draw_arc(Vector2.ZERO, 56.0, 0.0, TAU, 40, Color(0.45, 0.94, 0.97, _shield_flash * 3.0), 4.0)
