# Roteiro da apresentação (máx. 15 minutos)

**Antes de começar:** jogo aberto no menu (executável) e projeto aberto no Godot 4.3 na aba
de scripts. Ter como **plano B** um vídeo de 2 minutos gravado da partida.

| Tempo | Conteúdo | Quem | O que mostrar |
|---|---|---|---|
| 0:00 – 1:00 | Abertura: título, premissa, engine e por que Godot | Giovanni | Menu principal |
| 1:00 – 5:00 | **Demo ao vivo**: fase 1 (tutorial, pisão, checkpoint, núcleo, portal), trecho da fase 2 (esteira, caixa, prensas), fase 3 escura e luta contra o chefe | Carlos joga, Giovanni narra | No editor (F5), **F1** pula a fase e **F2** liga a invencibilidade para chegar rápido ao chefe |
| 5:00 – 7:30 | **Código: gameplay** | Giovanni | `player.gd` (coyote time, jump buffer, pulo variável, estados), `hitbox.gd`/`hurtbox.gd`/`health_component.gd` (composição e camadas de colisão), `enemy_base.gd` (herança), `boss.gd` (máquina de estados) |
| 7:30 – 10:00 | **Código: conteúdo e interface** | Carlos | Mapa ASCII de uma fase + `level_base.gd`, `press.gd`/`conveyor.gd` (tipos de corpo físico), `hud.gd` ouvindo sinais do `GameManager`, `audio_manager.gd` (barramentos e crossfade), `gerar_sprites.py` e `gerar_audio.py` |
| 10:00 – 11:30 | Design: curva de dificuldade, feedback, testes automatizados e resultados dos playtests | Carlos | Tabela do GDD e execução do `MechanicsTest` |
| 11:30 – 13:00 | Contribuição de cada integrante | Ambos | Slide com `docs/contribuicoes.md` |
| 13:00 – 15:00 | Lições aprendidas, créditos, perguntas | Ambos | Tela de créditos do jogo |

## Perguntas prováveis do professor (e respostas curtas)

- **Como funciona a colisão?** Há 7 camadas nomeadas. O dano usa Area2D: a Hitbox causa dano e a Hurtbox recebe. O cenário é um TileMapLayer com colisão por tile, e as plataformas finas são de mão única.
- **Onde está a física?** No `CharacterBody2D` com gravidade, aceleração e atrito, no `AnimatableBody2D` (plataformas e prensas), no `StaticBody2D` com velocidade constante (esteiras) e no `RigidBody2D` (caixa empurrada com impulsos).
- **Como as animações funcionam?** O `SpriteLib` monta `SpriteFrames` a partir de folhas de sprites, e o `AnimatedSprite2D` troca a animação conforme o estado. Tweens fazem o squash & stretch, o piscar e as transições, e há partículas.
- **Os assets são de terceiros?** Não: arte e áudio foram gerados por scripts Python da equipe. Os créditos estão no jogo.
- **Como evitam que o jogador perca o progresso?** O checkpoint guarda um "snapshot" do estado (pontos, itens coletados, núcleo), restaurado ao renascer.

## Checklist do dia

- [ ] Executável testado em outro computador
- [ ] Projeto abre no Godot 4.3 sem erros
- [ ] Vídeo do plano B no pendrive
- [ ] Cada integrante ensaiou a sua parte do código
- [ ] Entrega feita no CONNECT+ (build .zip, projeto .zip ou GitHub, GDD, README)
