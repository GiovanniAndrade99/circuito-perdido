# Contribuições por integrante

Base do slide "Contribuição de cada integrante" da apresentação. Cada script traz no
cabeçalho a linha `## Responsável:` com o nome de quem o desenvolveu.

## Giovanni Anicezio Andrade: gameplay e sistemas

| Área | Arquivos principais | Conceitos da disciplina |
|---|---|---|
| Jogador VOLT | `scripts/actors/player.gd`, `scenes/actors/Player.tscn` | Física (gravidade, aceleração, atrito), pulo variável, coyote time, jump buffer, máquina de estados, squash & stretch, screen shake |
| Sistema de dano | `scripts/components/health_component.gd`, `hitbox.gd`, `hurtbox.gd` | Detecção de colisão com Area2D, camadas e máscaras, composição, sinais |
| Inimigos (herança) | `enemy_base.gd`, `patrol_bot.gd`, `turret.gd`, `kamikaze.gd` | IA com RayCast2D, detecção por distância, perseguição com steering |
| Chefe SENTINELA | `scripts/actors/boss.gd` | Máquina de estados com 8 fases, padrões de ataque, escudo, dificuldade progressiva |
| Motor de fases | `scripts/levels/level_base.gd` | Leitura de mapa ASCII, TileMapLayer, câmera com limites, iluminação 2D |
| Fluxo do jogo | `scripts/autoload/game_manager.gd`, `scene_loader.gd` | Autoloads (singletons), vidas, checkpoints com snapshot de estado, pontuação, transições |
| Projéteis e explosão | `scripts/objects/projectile.gd`, `explosion.gd` | Herança de Hitbox, colisão com o cenário |
| Testes | `tests/smoke_test.gd`, `tests/mechanics_test.gd` | Testes automatizados de regressão |

## Carlos Eduardo Peraçolli: conteúdo, interface e áudio

| Área | Arquivos principais | Conceitos da disciplina |
|---|---|---|
| Level design | `scripts/levels/level_01.gd` … `boss_arena.gd` | Curva de dificuldade, tutorial embutido, posicionamento de desafios |
| Objetos do cenário | `moving_platform.gd`, `conveyor.gd`, `press.gd`, `crate.gd`, `spikes.gd` | AnimatableBody2D, StaticBody2D com velocidade constante, RigidBody2D, perigos |
| Coletáveis e progressão | `collectible.gd`, `checkpoint.gd`, `exit_portal.gd`, `hint_sign.gd` | Feedback visual e sonoro, portal trancado pelo objetivo |
| Interface | `scripts/ui/hud.gd`, `main_menu.gd`, `pause_menu.gd`, `options_panel.gd`, `credits.gd`, `game_over.gd`, `victory.gd`, `splash.gd` | HUD, menus navegáveis por teclado, mouse e gamepad, tema visual único |
| Áudio | `scripts/autoload/audio_manager.gd`, `tools/gerar_audio.py` | Barramentos Music/SFX, pool de players, crossfade, loop de trilhas, síntese chiptune |
| Arte e animação | `tools/gerar_sprites.py`, `scripts/core/sprite_lib.gd`, `fx.gd`, `background.gd` | Sprite sheets, AnimatedSprite2D, partículas, parallax |
| Salvamento | `scripts/autoload/save_manager.gd` | Persistência em JSON (recorde e opções) |
| Documentação | `README.md`, `docs/GDD.md`, `CREDITS.md`, `docs/apresentacao.md` | GDD, créditos, roteiro |

## Registro de atividades

| Data | Quem | O que foi feito |
|---|---|---|
| 05/11/2026 | Ambos | Planejamento, aprovação da engine com o professor, divisão de tarefas |
| 05/11/2026 | Giovanni | Jogador, componentes de dano, inimigos, chefe, motor de fases, testes automatizados |
| 05/11/2026 | Carlos | Arte e áudio procedurais, mapas das fases, objetos do cenário, HUD e menus |
| | | *(continuar registrando: playtests, ajustes de balanceamento, ensaios)* |
