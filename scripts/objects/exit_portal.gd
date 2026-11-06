extends Area2D
## Responsável: Carlos Eduardo Peraçolli
## Portal de saída: fica trancado até o núcleo da fase ser coletado.

var _warned_recently := false

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.sprite_frames = SpriteLib.frames("portal")
	GameManager.cores_changed.connect(_refresh)
	_refresh(0)
	body_entered.connect(_on_body_entered)


func is_open() -> bool:
	return GameManager.core_taken


func _refresh(_value: int) -> void:
	var anim := "open" if is_open() else "locked"
	if sprite.animation != anim:
		sprite.play(anim)
		if is_open():
			Fx.burst(self, global_position + Vector2(0, -32), Color("73eff7"), 20, 160.0, 0.7, 0.0, 4.0)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or player.state == Player.State.DEAD:
		return
	if not is_open():
		if not _warned_recently:
			_warned_recently = true
			AudioManager.play_sfx("locked")
			GameManager.show_message("Portal trancado! Encontre o NÚCLEO de energia desta área.")
			get_tree().create_timer(2.0, false).timeout.connect(func() -> void: _warned_recently = false)
		return
	var level := get_tree().current_scene
	if level.has_method("on_exit_reached"):
		level.on_exit_reached()
