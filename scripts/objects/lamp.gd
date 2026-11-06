extends Node2D
## Responsável: Carlos Eduardo Peraçolli
## Lâmpada de teto. Na fase escura acende uma PointLight2D que pisca levemente.

@export var with_light := false

var _light: PointLight2D
var _time := 0.0


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = SpriteLib.texture("items", SpriteLib.ITEM_LAMP)
	add_child(sprite)
	if with_light:
		_light = PointLight2D.new()
		_light.texture = Fx.light_texture()
		_light.texture_scale = 1.6
		_light.color = Color("ffcd75")
		_light.energy = 0.9
		_light.position = Vector2(0, 40)
		add_child(_light)
	_time = randf() * 10.0


func _process(delta: float) -> void:
	if _light:
		_time += delta
		_light.energy = 0.85 + sin(_time * 7.0) * 0.05 + (0.15 if fmod(_time, 4.0) < 0.08 else 0.0)
