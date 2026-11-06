class_name HealthComponent
extends Node
## Responsável: Giovanni Anicezio Andrade
## Componente de vida reutilizado pelo jogador, inimigos e chefe
## (composição em vez de repetir a mesma lógica em cada personagem).

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died

@export var max_health := 3
## Tempo de invencibilidade após levar dano (0 = nenhum).
@export var invincibility_time := 0.0

var health := 0
var is_dead := false
var _invincible_timer := 0.0


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	if _invincible_timer > 0.0:
		_invincible_timer -= delta


func is_invincible() -> bool:
	return _invincible_timer > 0.0


## Aplica dano. Retorna true se o dano foi aplicado.
func take_damage(amount: int) -> bool:
	if is_dead or is_invincible() or amount <= 0:
		return false
	health = maxi(health - amount, 0)
	_invincible_timer = invincibility_time
	health_changed.emit(health, max_health)
	damaged.emit(amount)
	if health == 0:
		is_dead = true
		died.emit()
	return true


func heal(amount: int) -> void:
	if is_dead:
		return
	var before := health
	health = mini(health + amount, max_health)
	if health != before:
		health_changed.emit(health, max_health)
		healed.emit(health - before)


func is_full() -> bool:
	return health >= max_health
