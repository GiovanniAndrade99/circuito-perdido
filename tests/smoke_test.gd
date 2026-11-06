extends Node
## Responsável: Giovanni Anicezio Andrade
## Teste automatizado ("smoke test"): abre cada tela e cada fase, simula o
## jogador andando, pulando e atirando, e verifica se tudo carrega sem erros.
## Uso (na raiz do projeto):
##   Godot_v4.3-stable_win64_console.exe --headless --path . res://tests/SmokeTest.tscn

const SCREENS := [
	"res://scenes/main/Splash.tscn",
	"res://scenes/main/MainMenu.tscn",
	"res://scenes/main/Credits.tscn",
	"res://scenes/main/GameOver.tscn",
	"res://scenes/main/Victory.tscn",
]

var _failures := 0


func _ready() -> void:
	# Este nó não pode ser a "cena atual", senão seria destruído na primeira troca.
	get_tree().current_scene = null
	await get_tree().process_frame
	for path in SCREENS:
		await _open(path, 30)
	for i in GameManager.LEVELS.size():
		await _test_level(i)
	await _test_death_flow()
	print("SMOKE TEST: %s (%d falha(s))" % ["OK" if _failures == 0 else "FALHOU", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _open(path: String, frames: int) -> void:
	print("-> ", path)
	var err := get_tree().change_scene_to_file(path)
	_check(err == OK, "não abriu " + path)
	for i in frames:
		await get_tree().physics_frame


func _test_level(index: int) -> void:
	GameManager.reset_run()
	GameManager.prepare_level(index)
	await _open(GameManager.LEVELS[index], 10)
	var level := get_tree().current_scene as LevelBase
	_check(level != null, "fase %d não é LevelBase" % index)
	if level == null:
		return
	_check(level.player != null, "fase %d sem jogador" % index)
	_check(level.map_size.x > 0, "fase %d sem mapa" % index)
	print("   mapa %dx%d, %d inimigos, núcleo: %s" % [level.map_size.x, level.map_size.y,
		get_tree().get_nodes_in_group("enemies").size(), _has_core(level)])
	GameManager.god_mode = true  # evita morrer durante a simulação
	# Simula ~5 s de jogo: correr para a direita, pulando e atirando.
	Input.action_press("move_right")
	for i in 300:
		if i % 40 == 0:
			Input.action_press("jump")
		elif i % 40 == 12:
			Input.action_release("jump")
		if i % 10 == 0:
			Input.action_press("shoot")
		elif i % 10 == 5:
			Input.action_release("shoot")
		await get_tree().physics_frame
	for action in ["move_right", "jump", "shoot"]:
		Input.action_release(action)
	if is_instance_valid(level.player):
		print("   jogador andou até x=%d" % int(level.player.global_position.x))
	GameManager.god_mode = false


func _test_death_flow() -> void:
	print("-> fluxo de morte e checkpoint")
	GameManager.reset_run()
	GameManager.prepare_level(0)
	await _open(GameManager.LEVELS[0], 10)
	GameManager.set_checkpoint(Vector2(2288, 560))
	GameManager.player_died()
	for i in 60:
		await get_tree().physics_frame
	var level := get_tree().current_scene as LevelBase
	_check(level != null and level.player != null, "fase não recarregou após a morte")
	if level and level.player:
		_check(level.player.global_position.distance_to(Vector2(2288, 560)) < 40.0, "não renasceu no checkpoint")
	_check(GameManager.lives == GameManager.START_LIVES - 1, "vida não foi descontada")


func _has_core(level: Node) -> bool:
	for child in level.get_children():
		if child is Collectible and child.kind == Collectible.Kind.CORE:
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FALHA: " + message)
