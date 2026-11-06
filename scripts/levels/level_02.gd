extends LevelBase
## Responsável: Carlos Eduardo Peraçolli (level design)
## Fase 2 — Esteiras e Prensas: esteiras, plataformas móveis, prensas com ritmo, caixa empurrável e torretas.
## Legenda dos caracteres: veja scripts/levels/level_base.gd

const MAP := """
#                                                                                                                                #
#                                                                                                                                #
#                                                                                                                                #
#                                                                                                                                #
#                                                                                                                                #
#                                                                                                                                #
#                                                                                                                                #
#                                                                                                                                #
#                                                                                                                                #
#                                                                                                                                #
#                                                     ###################                                                        #
#                                                     ###################                                   oooo           C     #
#                              ooo                    ###################                                                 ===    #
#                                                         X    X    X                   ooo      d   h                           #
#                                                                                     ###################                        #
#                 oooooooo                                                            ###################  M           ===       #
#                             M                                                       ###################                        #
#  P  1                               2       o   t    3    oo   oo   oo   K 4  B     ###################          K d   t    E  #
################>>>>>>>>>>>>        #####################################################################         ################
############################        #####################################################################         ################
############################        #####################################################################         ################
############################        #####################################################################         ################
"""


const HINTS := [
	"Esteiras empurram você. Plataformas azuis se movem: use-as para atravessar buracos.",
	"Torretas atiram quando você se aproxima. Elas aguentam 2 tiros.",
	"Prensas descem em intervalos. Observe o ritmo e passe na hora certa!",
	"Empurre a caixa até a parede e suba nela para alcançar o alto.",
]


func get_map() -> String:
	return MAP


func get_hints() -> Array:
	return HINTS
