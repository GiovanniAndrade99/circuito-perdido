class_name Hurtbox
extends Area2D
## Responsável: Giovanni Anicezio Andrade
## Área que RECEBE dano. Emite "hit" quando encosta numa Hitbox ativa; quem
## decide o que fazer (perder vida, ser pisado...) é o dono da hurtbox.

signal hit(hitbox: Hitbox)

@export var enabled := true


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if enabled and area is Hitbox and area.active:
		hit.emit(area)


## Hitboxes persistentes (espinhos, corpo de inimigos) continuam causando dano
## enquanto houver sobreposição; o tempo de invencibilidade do HealthComponent
## evita que o dano seja aplicado a cada quadro.
func _physics_process(_delta: float) -> void:
	if not enabled or not monitoring:
		return
	for area in get_overlapping_areas():
		if area is Hitbox and area.active and area.persistent:
			hit.emit(area)
