extends LevelBase
## Responsável: Carlos Eduardo Peraçolli (level design)
## Arena do chefe SENTINELA: desvie dos tiros, pule as investidas e ataque quando ele estiver atordoado.
## Legenda dos caracteres: veja scripts/levels/level_base.gd

const MAP := """
########################################
########################################
##                                    ##
##                  S                 ##
##                                    ##
##                                    ##
##                                    ##
##                                    ##
##                                    ##
##                                    ##
##                                    ##
##                                    ##
##                                    ##
##                                    ##
##                                    ##
##      h                      h      ##
##    =====                  =====    ##
##                                    ##
##   P                             E  ##
########################################
########################################
########################################
"""


func get_map() -> String:
	return MAP


## Informa ao chefe os limites da arena (paredes e chão).
func _on_level_built() -> void:
	var boss := get_tree().get_first_node_in_group("boss")
	if boss:
		var floor_y := float((map_size.y - 3) * TILE)
		boss.setup_arena(2.0 * TILE, float((map_size.x - 2) * TILE), floor_y)
