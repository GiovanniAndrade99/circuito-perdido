class_name Layers
## Responsável: Giovanni Anicezio Andrade
## Máscaras de bits das camadas de colisão. Os nomes batem com
## Projeto > Configurações > Nomes de Camadas > Física 2D.

const WORLD := 1         ## camada 1: chão, paredes, caixas, plataformas
const PLAYER := 2        ## camada 2: corpo e hurtbox do jogador
const ENEMY := 4         ## camada 3: corpo, hitbox e hurtbox dos inimigos
const PLAYER_SHOT := 8   ## camada 4: pulso de energia do jogador
const ENEMY_SHOT := 16   ## camada 5: projéteis inimigos
const COLLECTIBLE := 32  ## camada 6: itens, checkpoints e portal
const HAZARD := 64       ## camada 7: espinhos, prensas e explosões
