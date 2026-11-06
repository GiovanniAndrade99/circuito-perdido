extends RigidBody2D
## Responsável: Carlos Eduardo Peraçolli
## Caixa empurrável (corpo rígido). O jogador aplica impulsos ao encostar;
## aqui limitamos a velocidade horizontal para a caixa não "voar".

@export var max_speed := 110.0


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = Layers.WORLD
	lock_rotation = true
	mass = 2.0
	var physics_mat := PhysicsMaterial.new()
	physics_mat.friction = 0.4
	physics_material_override = physics_mat
	$Sprite.texture = SpriteLib.texture("tiles", SpriteLib.TILE_CRATE)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var v := state.linear_velocity
	v.x = clampf(v.x, -max_speed, max_speed)
	state.linear_velocity = v
