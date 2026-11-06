extends Area2D
## Responsável: Carlos Eduardo Peraçolli
## Terminal de checkpoint: ao ser tocado salva o ponto de renascimento e
## recupera toda a energia do jogador.

var activated := false

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.sprite_frames = SpriteLib.frames("items")
	# Se o jogador renasceu aqui, o terminal já começa ligado.
	activated = GameManager.has_checkpoint() and GameManager.checkpoint_position().distance_to(global_position) < 4.0
	sprite.play("cp_on" if activated else "cp_off")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or activated or player.state == Player.State.DEAD:
		return
	activated = true
	sprite.play("cp_on")
	player.health.heal(player.health.max_health)
	GameManager.set_checkpoint(global_position)
	AudioManager.play_sfx("checkpoint")
	Fx.popup_text(self, global_position + Vector2(0, -24), "CHECKPOINT", UITheme.COLOR_GOOD)
	Fx.burst(self, global_position, Color("a7f070"), 14, 140.0, 0.6, 100.0, 4.0)
