class_name Hitbox
extends Area2D
## Responsável: Giovanni Anicezio Andrade
## Área que CAUSA dano ao sobrepor uma Hurtbox. Usada em espinhos, corpo de
## inimigos, projéteis, prensas e explosões.

@export var damage := 1
## Dano contínuo enquanto houver sobreposição (espinhos, corpo de inimigos).
## Projéteis usam false: acertam uma vez e somem.
@export var persistent := true
## Pode ser derrotado pelo jogador pulando em cima.
@export var stompable := false
## Permite desligar o dano temporariamente (ex.: chefe atordoado).
@export var active := true
