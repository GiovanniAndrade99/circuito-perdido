class_name Collectible
extends Area2D
## Responsável: Carlos Eduardo Peraçolli
## Item coletável: célula de energia (pontos), coração (cura) ou núcleo
## (objetivo da fase, destrava o portal). Flutua suavemente para chamar atenção.

enum Kind { CELL, HEART, CORE }

@export var kind: Kind = Kind.CELL

var key := ""  ## identificador "x,y" na fase, para não reaparecer após checkpoint
var _time := 0.0
var _base_y := 0.0
var _taken := false

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	z_index = 2
	sprite.sprite_frames = SpriteLib.frames("items")
	match kind:
		Kind.CELL:
			sprite.play("cell")
		Kind.HEART:
			sprite.play("heart")
		Kind.CORE:
			sprite.play("core")
			sprite.scale = Vector2(1.3, 1.3)
	_time = randf() * TAU
	_base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta * 3.0
	position.y = _base_y + sin(_time) * 3.0


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or player.state == Player.State.DEAD or _taken:
		return
	match kind:
		Kind.CELL:
			GameManager.collect_cell(key)
			AudioManager.play_sfx("cell", 0.05)
			Fx.popup_text(self, global_position, "+%d" % GameManager.SCORE_CELL, UITheme.COLOR_ACCENT_LIGHT)
			Fx.burst(self, global_position, Color("73eff7"), 8, 90.0, 0.4, 0.0, 3.0)
		Kind.HEART:
			if player.health.is_full():
				return  # vida cheia: deixa o coração para depois
			player.heal(1)
			GameManager.register_collected(key)
			AudioManager.play_sfx("heart")
			Fx.popup_text(self, global_position, "+1 VIDA", UITheme.COLOR_DANGER)
			Fx.burst(self, global_position, Color("e04a5f"), 10, 90.0, 0.5, 0.0, 3.0)
		Kind.CORE:
			GameManager.collect_core(key)
			AudioManager.play_sfx("core")
			GameManager.request_shake(5.0)
			GameManager.show_message("NÚCLEO RECUPERADO! O portal de saída foi destravado.")
			Fx.burst(self, global_position, Color("a7f070"), 24, 200.0, 0.8, 0.0, 5.0)
			Fx.flash(self, global_position, 20.0, Color(0.65, 0.94, 0.44, 0.8))
	_taken = true
	queue_free()
