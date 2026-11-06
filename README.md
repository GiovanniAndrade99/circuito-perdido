# Circuito Perdido

Jogo de plataforma 2D para PC desenvolvido como **Projeto Prático P2** da disciplina
Desenvolvimento de Jogos Digitais (Ciência da Computação).

> Num futuro abandonado, o robô de manutenção **VOLT** acorda numa fábrica em colapso.
> Ele precisa recuperar os **4 núcleos de energia** espalhados por 3 setores e derrotar o
> **SENTINELA**, o sistema de segurança que enlouqueceu, para reativar o reator e escapar.

## Integrantes

| Integrante | Responsabilidades principais |
|---|---|
| **Giovanni Anicezio Andrade** | Programação de gameplay: jogador (física e estados), componentes de vida e dano, inimigos e IA, chefe, motor de fases, GameManager e SceneLoader, testes automatizados |
| **Carlos Eduardo Peraçolli** | Level design das 4 fases, objetos do cenário, interface (HUD e menus), áudio e salvamento, geração procedural de arte e trilha sonora, documentação |

## Como executar

### Jogar (sem instalar nada)
1. Extraia `CircuitoPerdido_Build.zip`.
2. Abra `CircuitoPerdido.exe` (Windows 10/11, 64 bits).

### Abrir o projeto no Godot
1. Instale o [Godot Engine **4.3**](https://godotengine.org/download/archive/4.3-stable/) (versão padrão, sem .NET).
2. No Gerenciador de Projetos, clique em **Importar** e selecione `project.godot`.
3. Pressione **F5** para jogar.

No editor (build de depuração) há atalhos para a apresentação: **F1** conclui a fase atual
e **F2** liga/desliga a invencibilidade. Eles não funcionam no executável final.

## Controles

| Ação | Teclado / mouse | Gamepad |
|---|---|---|
| Mover | A / D ou setas | Analógico esquerdo ou direcional |
| Pular (segure para pular mais alto) | Espaço, W ou seta para cima | A |
| Pulso de energia (segure para disparo contínuo) | J, K, X ou clique esquerdo | X |
| Pausar | Esc ou P | Start |

## Estrutura do projeto

```
circuito-perdido/
├── project.godot / export_presets.cfg
├── assets/            sprites (PNG) e áudio (WAV) gerados pelos scripts de tools/
├── scenes/            cenas .tscn: main/ (telas), levels/, actors/, objects/, ui/
├── scripts/
│   ├── autoload/      GameManager, AudioManager, SaveManager, SceneLoader
│   ├── core/          Layers, SpriteLib, Fx, UITheme
│   ├── components/    HealthComponent, Hitbox, Hurtbox
│   ├── actors/        Player, EnemyBase, PatrolBot, Turret, Kamikaze, Boss
│   ├── objects/       coletáveis, checkpoint, portal, esteira, prensa, caixa...
│   ├── levels/        LevelBase (lê o mapa ASCII) + mapas das 4 fases
│   └── ui/            HUD, menus, opções, créditos, fundo parallax
├── tests/             testes automatizados e ferramenta de screenshots
├── tools/             gerar_sprites.py e gerar_audio.py (Python 3)
└── docs/              GDD, contribuições, roteiro da apresentação, playtest
```

## Testes automatizados

```
Godot_v4.3-stable_win64_console.exe --headless --path . res://tests/SmokeTest.tscn
Godot_v4.3-stable_win64_console.exe --headless --path . res://tests/MechanicsTest.tscn
```

- **SmokeTest**: abre todas as telas e fases, simula o jogador e verifica o fluxo de morte e checkpoint.
- **MechanicsTest**: verifica núcleo, portal e troca de fase, esteira, caixa, prensa, plataforma móvel
  e o ciclo completo do chefe até a tela de vitória.

## Regerar arte e áudio (opcional)

```
python tools/gerar_sprites.py
python tools/gerar_audio.py
```

## Documentação

- [Game Design Document](docs/GDD.md)
- [Contribuições de cada integrante](docs/contribuicoes.md)
- [Roteiro da apresentação](docs/apresentacao.md)
- [Formulário de playtest](docs/playtest/formulario.md)
- [Créditos](CREDITS.md) (também na tela **Créditos** do jogo)
