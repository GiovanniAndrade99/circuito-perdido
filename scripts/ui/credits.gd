extends Control
## Responsável: Carlos Eduardo Peraçolli
## Tela de créditos com rolagem: equipe, ferramentas e origem de todos os
## recursos (exigência do projeto: referenciar assets de terceiros).

const MENU_SCENE := "res://scenes/main/MainMenu.tscn"
const SCROLL_SPEED := 45.0

## [texto, tamanho, cor] — linhas vazias viram espaçamento.
const LINES := [
	["CIRCUITO PERDIDO", 56, "73eff7"],
	["Projeto Prático P2 — Desenvolvimento de Jogos Digitais", 22, "f4f4f4"],
	["Curso de Ciência da Computação", 20, "94b0c2"],
	["", 20, ""],
	["EQUIPE", 32, "ffcd75"],
	["Giovanni Anicezio Andrade", 26, "f4f4f4"],
	["Programação de gameplay: jogador, física, inimigos, IA e chefe,", 18, "94b0c2"],
	["componentes de vida/dano, motor de fases e fluxo do jogo", 18, "94b0c2"],
	["", 12, ""],
	["Carlos Eduardo Peraçolli", 26, "f4f4f4"],
	["Level design das 4 fases, objetos do cenário, interface (HUD e menus),", 18, "94b0c2"],
	["áudio, salvamento, arte e trilha sonora procedurais, documentação", 18, "94b0c2"],
	["", 20, ""],
	["ARTE", 32, "ffcd75"],
	["Pixel art original criada pela equipe com o script tools/gerar_sprites.py", 20, "f4f4f4"],
	["Paleta de cores \"Sweetie 16\" por GrafxKid (lospec.com) — uso livre", 18, "94b0c2"],
	["", 20, ""],
	["ÁUDIO", 32, "ffcd75"],
	["Efeitos sonoros e trilhas chiptune sintetizados pela equipe", 20, "f4f4f4"],
	["com o script tools/gerar_audio.py", 18, "94b0c2"],
	["", 20, ""],
	["TECNOLOGIA", 32, "ffcd75"],
	["Godot Engine 4.3 — licença MIT — godotengine.org", 20, "f4f4f4"],
	["Fonte padrão do Godot (Open Sans) — SIL Open Font License", 18, "94b0c2"],
	["Python 3 (geração de arte e áudio)", 18, "94b0c2"],
	["", 20, ""],
	["Nenhum asset de terceiros com restrição de uso foi utilizado.", 18, "a7f070"],
	["", 30, ""],
	["Obrigado por jogar!", 36, "73eff7"],
]

var _content: VBoxContainer
var _leaving := false


func _ready() -> void:
	theme = UITheme.get_theme()
	var background := GameBackground.new()
	background.auto_scroll = 20.0
	add_child(background)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.05, 0.1, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_content = VBoxContainer.new()
	_content.custom_minimum_size = Vector2(1280, 0)
	_content.position = Vector2(0, 720)
	_content.add_theme_constant_override("separation", 6)
	add_child(_content)
	for line in LINES:
		if line[0] == "":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, line[1])
			_content.add_child(spacer)
		else:
			_content.add_child(UITheme.make_label(line[0], line[1], Color(line[2])))

	var back := UITheme.make_button("Voltar", _back, 200)
	back.position = Vector2(1280 - 220, 720 - 72)
	add_child(back)
	back.grab_focus()
	AudioManager.play_music("menu")


func _process(delta: float) -> void:
	_content.position.y -= SCROLL_SPEED * delta
	if _content.position.y < -_content.size.y:
		_content.position.y = 720.0  # recomeça a rolagem


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_back()


func _back() -> void:
	if _leaving:
		return
	_leaving = true
	SceneLoader.change_scene(MENU_SCENE)
