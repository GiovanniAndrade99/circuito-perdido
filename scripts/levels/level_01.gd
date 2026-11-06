extends LevelBase
## Responsável: Carlos Eduardo Peraçolli (level design)
## Fase 1 — Galpão de Montagem: tutorial embutido (mover, pular, atirar), espinhos e patrulheiros.
## Legenda dos caracteres: veja scripts/levels/level_base.gd

const MAP := """
#                                                                                                            #
#                                                                                                            #
#                                                                                                            #
#                                                                                                            #
#                                                                                                            #
#                                                                                                            #
#                                                                                                            #
#                                                                                                            #
#                                                                                                            #
#                                                                                   hooC                     #
#                                                                                  ########                  #
#                                                                                  ########        oo        #
#                                   o          oo                              ====               ====       #
#                         ooo      o o        ====                o                                          #
#                                                                o o                                         #
#                                       3   4       d  ooo                 ===                   #######     #
#                      ############   #####################                                      #######     #
#  P  1  ooo       2   ############   #####################  5   ^^^ 6 K 7    d     ^^  ooo d    #######  E  #
###################################   ########################################################################
###################################   ########################################################################
###################################   ########################################################################
###################################   ########################################################################
"""


const HINTS := [
	"Use A/D ou as SETAS para andar. ESPAÇO pula.",
	"Segure ESPAÇO para pular mais alto. Solte cedo para um pulo curto.",
	"Aperte J (ou clique) para disparar o pulso de energia. Segure para disparar sem parar.",
	"Robôs patrulheiros: atire neles ou pule em cima!",
	"Espinhos machucam! Pule por cima deles.",
	"Checkpoints salvam seu progresso e recuperam sua energia.",
	"Pegue o NÚCLEO de energia lá no alto. Sem ele o portal não abre!",
]


func get_map() -> String:
	return MAP


func get_hints() -> Array:
	return HINTS
