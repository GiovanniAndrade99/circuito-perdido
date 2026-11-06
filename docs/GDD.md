# Game Design Document (simplificado): Circuito Perdido

**Disciplina:** Desenvolvimento de Jogos Digitais (quinta-feira), Ciência da Computação
**Atividade:** Projeto Prático P2 · **Entrega:** 19/11/2026
**Equipe:** Giovanni Anicezio Andrade e Carlos Eduardo Peraçolli

---

## 1. Visão geral

| Item | Definição |
|---|---|
| Título | Circuito Perdido |
| Gênero | Plataforma 2D com ação (tiro e pisão) |
| Plataforma | PC (Windows 10/11, 64 bits) |
| Engine | Godot 4.3 (GDScript), renderizador Compatibility. Aprovada pelo professor |
| Público | Jogadores casuais, 10+ anos |
| Duração | 8 a 12 minutos por partida completa |
| Resolução | 1280×720, escala com a janela; tela cheia opcional |

## 2. Premissa e narrativa

Num futuro abandonado, **VOLT**, um pequeno robô de manutenção, acorda numa fábrica em colapso.
O reator central está desligado e o sistema de segurança, o **SENTINELA**, enlouqueceu. Para
escapar, VOLT precisa recuperar os **4 núcleos de energia**: um em cada setor da fábrica e o
último guardado pelo próprio SENTINELA.

**Pilares de design**
1. **Controle responsivo**: o pulo e o movimento precisam ser agradáveis desde os primeiros segundos.
2. **Regras claras**: um objetivo por fase (pegar o núcleo e chegar ao portal) e poucos verbos (andar, pular, atirar).
3. **Dificuldade em degraus**: cada fase apresenta uma mecânica nova e depois a combina com as anteriores.
4. **Feedback em tudo**: todo evento tem resposta visual (partículas, flash, tremor) e sonora.

## 3. Mecânicas e controles

| Ação | Teclado / mouse | Gamepad |
|---|---|---|
| Mover | A/D ou setas | Analógico / direcional |
| Pular | Espaço, W ou ↑ | A |
| Pulso de energia | J, K, X ou clique | X |
| Pausar | Esc ou P | Start |

**Movimento**
- Aceleração e atrito (o robô não para nem arranca instantaneamente). No ar o controle é de 70%.
- Gravidade 25% maior na queda, para um pulo mais "firme".
- **Pulo variável**: soltar o botão durante a subida corta a velocidade (pulo curto). Altura máxima de ~3,7 tiles.
- **Coyote time** (0,1 s): ainda dá para pular logo depois de sair da borda.
- **Jump buffer** (0,12 s): apertar pouco antes de tocar o chão também vale.

**Combate**
- Pulso de energia: projétil reto, 1 de dano, intervalo de 0,3 s. Segurar o botão dispara continuamente.
- **Pisão**: cair sobre patrulheiros e kamikazes os destrói e faz VOLT quicar (quica mais alto segurando o pulo).
- Ao levar dano: empurrão para trás (knockback), 1,2 s de invencibilidade com o sprite piscando e tremor de câmera.

**Vida e progresso**
- 3 corações de energia por vida e 3 vidas (VOLT x3).
- Perder todos os corações ou cair num buraco custa 1 vida e VOLT renasce no último checkpoint.
- Sem vidas: tela **Fim de Jogo**, com as opções Tentar novamente (recomeça a fase) ou Menu.
- **Checkpoints** salvam a posição, a pontuação e os itens já coletados, e recuperam todos os corações.
- O **portal de saída** só abre depois que o núcleo da fase é coletado.

**Pontuação**

| Evento | Pontos |
|---|---|
| Célula de energia | 10 |
| Núcleo | 100 |
| Patrulheiro / Kamikaze / Torreta | 50 / 60 / 80 |
| SENTINELA | 1000 |
| Fase sem levar dano | +200 |
| Bônus de tempo | +2 por segundo abaixo de 2min30 |

O recorde fica salvo em `user://save.json`.

## 4. Estrutura das fases

| Fase | Tema | Mecânica nova | Ameaças |
|---|---|---|---|
| 1. Galpão de Montagem | Tutorial embutido com 7 placas de dica | Andar, pular, atirar, pisão, espinhos, checkpoint, núcleo e portal | Patrulheiros |
| 2. Esteiras e Prensas | Linha de produção | Esteiras, plataformas móveis, prensas com ritmo, caixa empurrável (puzzle para subir uma parede alta) | Patrulheiros e torretas |
| 3. Reator | Área escura, iluminada só pela luz do VOLT e por lâmpadas | Plataforma vertical, esteira contra o jogador sob prensas, tudo combinado | Patrulheiros, torretas e kamikazes |
| 4. Núcleo de Segurança | Arena fechada | Luta contra o chefe | SENTINELA |

**Fluxo de telas**

```
Splash (equipe) → Menu Principal ─┬─ Jogar → Fase 1 → Fase 2 → Fase 3 → Chefe → Vitória → Menu
                                  ├─ Opções (música, efeitos, tela cheia)
                                  ├─ Créditos
                                  └─ Sair
Em qualquer fase: Esc → Pausa (Continuar | Opções | Reiniciar fase | Menu principal)
Sem vidas → Fim de Jogo (Tentar novamente | Menu principal)
```

**Level design por texto:** cada fase é um mapa ASCII (`scripts/levels/level_0X.gd`), em que cada
caractere vira um tile ou um objeto (`#` chão, `=` plataforma, `^` espinho, `d` patrulheiro,
`C` núcleo...). A legenda completa está em `scripts/levels/level_base.gd`. Uma análise de
alcançabilidade (BFS sobre o mapa) confirmou que o núcleo e o portal de cada fase podem ser
alcançados com o pulo do personagem.

## 5. Inimigos e balanceamento

| Inimigo | Vida | Dano | Comportamento |
|---|---|---|---|
| Robô patrulheiro | 1 | 1 (contato) | Anda a 70 px/s e vira ao detectar parede ou borda (RayCast2D). Pode ser pisado |
| Torreta | 2 | 1 (projétil) | Alcance de 430 px. Pisca 0,5 s antes de atirar (aviso) e dispara a cada 2 s mirando no jogador. Não pode ser pisada |
| Kamikaze | 1 | 1 (explosão) | Flutua até detectar o jogador (280 px), então persegue a 150 px/s e explode ao chegar perto ou após 4 s. Pode ser abatido de longe |
| SENTINELA | 20 | 1 | Máquina de estados: Intro → Flutuar → Rajada de tiros → Aviso (treme) → Investida → Atordoado (bate na parede) → Subir. **Só recebe dano atordoado**; fora disso um escudo bloqueia os tiros. Abaixo de 66% e de 33% de vida fica mais rápido e dispara 5 tiros por rajada |

Os valores são variáveis `@export`, editáveis no Inspetor do Godot sem mexer no código.

## 6. Interface

- **HUD:** corações (canto superior esquerdo), vidas, células, núcleos x/4, pontuação e tempo (canto superior direito), título da fase, mensagens contextuais e barra de vida do chefe.
- **Menus:** principal, pausa, opções (volume de música e de efeitos com barramentos de áudio separados, tela cheia), créditos com rolagem, fim de jogo e vitória com resumo e aviso de novo recorde.
- Todos os menus funcionam com teclado, mouse e gamepad (o mouse move o foco).

## 7. Arte e áudio

- **Arte:** pixel art 16×16 ampliada 2× (personagens 32×32, chefe 96×96, portal 64×96), na paleta Sweetie 16. Tudo é gerado por `tools/gerar_sprites.py` a partir de ASCII art e primitivas.
- **Animações:** AnimatedSprite2D (VOLT: parado, correndo, pulo, queda e dano; inimigos, itens, portal, esteiras), além de squash & stretch, piscar ao levar dano, partículas e fundo com parallax de 3 camadas.
- **Áudio:** 22 efeitos e 4 trilhas chiptune (menu, fases 1 e 2, reator, chefe), sintetizados por `tools/gerar_audio.py`. A troca de trilha é feita com crossfade.

## 8. Arquitetura técnica

| Conceito | Onde |
|---|---|
| Física de personagem | `CharacterBody2D` + `move_and_slide()` (jogador e inimigos) |
| Corpos de física | `AnimatableBody2D` (plataformas, prensas), `StaticBody2D` com `constant_linear_velocity` (esteiras), `RigidBody2D` (caixa) |
| Colisão | 7 camadas nomeadas (mundo, jogador, inimigos, tiros, coletáveis, perigos). `Area2D` para Hitbox/Hurtbox/itens. `TileMapLayer` com plataformas de mão única |
| Composição | `HealthComponent`, `Hitbox` e `Hurtbox` são reaproveitados por jogador, inimigos e chefe |
| Herança | `EnemyBase` → patrulheiro, torreta, kamikaze, chefe. `Hitbox` → projétil, espinhos, explosão |
| Sinais | o HUD só ouve o `GameManager` e não conhece jogador nem fases |
| Singletons (Autoload) | `GameManager` (estado e fluxo), `AudioManager`, `SaveManager`, `SceneLoader` (transições) |
| Máquinas de estado | jogador (6 estados), chefe (8 estados), prensa (5 etapas) |
| Testes | `tests/SmokeTest.tscn` e `tests/MechanicsTest.tscn` (20 verificações de mecânica) |

## 9. Cronograma e responsabilidades

| Marco | Data | Situação |
|---|---|---|
| Aprovação da engine e divisão de tarefas | 05/11 | ✔ |
| Versão completa jogável (4 fases, menus, áudio, build) | 05/11 | ✔ |
| Playtest rodada 1 + ajustes | até 15/11 | a fazer |
| Playtest rodada 2 + ajustes finais | até 18/11 | a fazer |
| Ensaio da apresentação (2×, cronometrado) | 18/11 | a fazer |
| Entrega no CONNECT+ e apresentação | 19/11 | a fazer |

A divisão detalhada está em `docs/contribuicoes.md`.

## 10. Testes e playtest

**Testes automatizados (já realizados):** todas as telas e fases carregam sem erros. Núcleo,
portal, troca de fase, esteira, caixa, prensa, plataforma móvel e o ciclo completo do chefe
foram verificados. Os testes revelaram e permitiram corrigir dois problemas: a caixa travava
nas emendas dos tiles (colisão chanfrada nos cantos) e o impulso ao empurrar era menor que
o atrito.

**Playtests com pessoas (a preencher pela equipe):** use `docs/playtest/formulario.md`.

| Problema observado | Ajuste feito | Resultado |
|---|---|---|
| | | |
