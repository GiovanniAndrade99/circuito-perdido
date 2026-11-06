extends Node2D
## Responsável: Carlos Eduardo Peraçolli
## Prensa industrial presa ao teto. Ciclo: espera em cima -> treme (aviso)
## -> desce rápido (causa dano) -> espera embaixo -> sobe devagar.
## A cabeça é um AnimatableBody2D (sólido: dá para subir nela) com uma Hitbox
## na parte de baixo que só fica ativa durante a descida.

enum Step { WAIT_UP, WARN, SLAM, WAIT_DOWN, RISE }

@export var travel := 128.0      ## distância percorrida (definida pela fase)
@export var wait_up := 1.4
@export var warn_time := 0.45
@export var slam_time := 0.16
@export var wait_down := 0.6
@export var rise_time := 1.0
@export var start_delay := 0.0

var _head: AnimatableBody2D
var _head_sprite: Sprite2D
var _hitbox: Hitbox
var _rod_texture: Texture2D
var _step := Step.WAIT_UP
var _timer := 0.0
var _extension := 0.0  ## 0 = recolhida, 1 = estendida


func _ready() -> void:
	z_index = 1
	_rod_texture = SpriteLib.texture("tiles", SpriteLib.TILE_PRESS_ROD)
	_timer = wait_up + start_delay

	_head = AnimatableBody2D.new()
	_head.collision_layer = Layers.WORLD
	_head.collision_mask = 0
	_head.sync_to_physics = true
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	_head.add_child(collision)
	_head_sprite = Sprite2D.new()
	_head_sprite.texture = SpriteLib.texture("tiles", SpriteLib.TILE_PRESS_HEAD)
	_head.add_child(_head_sprite)

	_hitbox = Hitbox.new()
	_hitbox.collision_layer = Layers.HAZARD
	_hitbox.collision_mask = 0
	_hitbox.monitoring = false
	_hitbox.active = false
	var hit_shape := RectangleShape2D.new()
	hit_shape.size = Vector2(28, 10)
	var hit_collision := CollisionShape2D.new()
	hit_collision.shape = hit_shape
	hit_collision.position = Vector2(0, 18)
	_hitbox.add_child(hit_collision)
	_head.add_child(_hitbox)
	add_child(_head)


func _physics_process(delta: float) -> void:
	_timer -= delta
	match _step:
		Step.WAIT_UP:
			if _timer <= 0.0:
				_go(Step.WARN, warn_time)
		Step.WARN:
			_head_sprite.position.x = sin(_timer * 80.0) * 2.0
			if _timer <= 0.0:
				_head_sprite.position.x = 0.0
				_hitbox.active = true
				_go(Step.SLAM, slam_time)
		Step.SLAM:
			_extension = 1.0 - maxf(_timer, 0.0) / slam_time
			if _timer <= 0.0:
				_extension = 1.0
				_hitbox.active = false
				_on_impact()
				_go(Step.WAIT_DOWN, wait_down)
		Step.WAIT_DOWN:
			if _timer <= 0.0:
				_go(Step.RISE, rise_time)
		Step.RISE:
			_extension = maxf(_timer, 0.0) / rise_time
			if _timer <= 0.0:
				_extension = 0.0
				_go(Step.WAIT_UP, wait_up)
	_head.position.y = travel * _extension
	queue_redraw()


func _go(step: Step, duration: float) -> void:
	_step = step
	_timer = duration


func _on_impact() -> void:
	var impact_pos := _head.global_position + Vector2(0, 16)
	Fx.dust(self, impact_pos)
	Fx.dust(self, impact_pos)
	# Som e tremor só se o jogador estiver perto (evita barulho fora da tela).
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.global_position.distance_to(impact_pos) < 500.0:
		AudioManager.play_sfx("press", 0.1, -4.0)
		GameManager.request_shake(3.0)


## Desenha a haste entre o teto e a cabeça.
func _draw() -> void:
	var rod_length := _head.position.y
	if rod_length > 1.0:
		draw_texture_rect(_rod_texture, Rect2(-16, -16, 32, rod_length), true)
