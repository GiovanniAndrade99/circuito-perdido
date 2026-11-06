extends Node
## Responsável: Giovanni Anicezio Andrade
## Teste automatizado das mecânicas principais (física, colisão e fluxo).
## Uso: Godot_v4.3-stable_win64_console.exe --headless --path . res://tests/MechanicsTest.tscn

var _failures := 0


func _ready() -> void:
	get_tree().current_scene = null
	await get_tree().process_frame
	await _test_core_and_portal()
	await _test_conveyor()
	await _test_crate()
	await _test_press()
	await _test_moving_platform()
	await _test_boss()
	print("MECHANICS TEST: %s (%d falha(s))" % ["OK" if _failures == 0 else "FALHOU", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --------------------------------------------------------------------------
func _load_level(index: int) -> LevelBase:
	GameManager.reset_run()
	GameManager.prepare_level(index)
	get_tree().change_scene_to_file(GameManager.LEVELS[index])
	await _frames(10)
	return get_tree().current_scene as LevelBase


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _cell(x: int, y: int) -> Vector2:
	return Vector2(x * 32 + 16, y * 32 + 16)


func _check(condition: bool, message: String) -> void:
	print("   [%s] %s" % ["ok" if condition else "FALHA", message])
	if not condition:
		_failures += 1


# --------------------------------------------------------------------------
func _test_core_and_portal() -> void:
	print("-> núcleo, portal e troca de fase")
	var level := await _load_level(0)
	level.player.global_position = _cell(106, 17)  # portal trancado
	await _frames(5)
	_check(level._exiting == false, "portal trancado não deixa sair")
	level.player.global_position = _cell(87, 9)  # núcleo
	await _frames(5)
	_check(GameManager.core_taken, "núcleo coletado")
	level.player.global_position = _cell(106, 17)
	await _frames(5)
	_check(level._exiting, "portal aberto inicia a saída")
	await _frames(260)
	var next := get_tree().current_scene
	_check(next != null and next.scene_file_path == GameManager.LEVELS[1], "avançou para a fase 2")
	_check(GameManager.get_cores() == 1, "contador de núcleos = 1")
	await _frames(30)


func _test_conveyor() -> void:
	print("-> esteira empurra o jogador")
	var level := await _load_level(1)
	level.player.global_position = _cell(18, 17)
	await _frames(70)
	_check(level.player.global_position.x > _cell(18, 17).x + 40.0,
		"jogador parado foi levado pela esteira (x=%d)" % int(level.player.global_position.x))


func _test_crate() -> void:
	print("-> empurrar caixa")
	var level := await _load_level(1)
	var crate: RigidBody2D = null
	for child in level.get_children():
		if child is RigidBody2D:
			crate = child
	_check(crate != null, "caixa existe")
	if crate == null:
		return
	var start_x := crate.global_position.x
	level.player.global_position = _cell(78, 17)
	Input.action_press("move_right")
	await _frames(120)
	Input.action_release("move_right")
	_check(crate.global_position.x > start_x + 32.0,
		"caixa foi empurrada (%d -> %d)" % [int(start_x), int(crate.global_position.x)])


func _test_press() -> void:
	print("-> prensa causa dano")
	var level := await _load_level(1)
	level.player.global_position = _cell(58, 17)
	var hp := level.player.health.health
	await _frames(200)
	_check(GameManager.took_damage or level.player.health.health < hp, "jogador sob a prensa levou dano")


func _test_moving_platform() -> void:
	print("-> plataforma móvel carrega o jogador")
	var level := await _load_level(1)
	level.player.global_position = _cell(30, 16) + Vector2(0, -44)
	await _frames(90)
	var x := level.player.global_position.x
	_check(x > _cell(30, 16).x + 30.0 and level.player.global_position.y < 560.0,
		"jogador andou junto com a plataforma (x=%d)" % int(x))


func _test_boss() -> void:
	print("-> chefe: ciclo de estados e derrota")
	var level := await _load_level(3)
	GameManager.god_mode = true
	var boss := get_tree().get_first_node_in_group("boss")
	_check(boss != null, "chefe existe")
	if boss == null:
		return
	var seen := {}
	for i in 60 * 25:
		if not is_instance_valid(boss):
			break
		seen[boss.phase] = true
		if boss.phase == boss.Phase.STUNNED:
			break
		await get_tree().physics_frame
	_check(seen.has(boss.Phase.SHOOT), "chefe atirou")
	_check(seen.has(boss.Phase.CHARGE), "chefe fez investida")
	_check(boss.phase == boss.Phase.STUNNED, "chefe ficou atordoado ao bater na parede")
	# Tiro com escudo (fora do atordoamento) não causa dano; atordoado causa.
	var hp: int = boss.health.health
	var shot := Hitbox.new()
	shot.damage = 1
	boss._on_hurt(shot)
	_check(boss.health.health == hp - 1, "atordoado recebe dano")
	boss.phase = boss.Phase.IDLE
	boss._on_hurt(shot)
	_check(boss.health.health == hp - 1, "fora do atordoamento o escudo bloqueia")
	boss.phase = boss.Phase.STUNNED
	for i in 30:
		boss._on_hurt(shot)
	shot.free()
	await _frames(150)
	_check(not is_instance_valid(boss), "chefe derrotado")
	var core: Node2D = null
	for child in level.get_children():
		if child is Collectible:
			if child.key == "boss_core":
				core = child
	_check(core != null, "chefe soltou o último núcleo")
	if core:
		level.player.global_position = core.global_position
		await _frames(5)
		level.player.global_position = _cell(35, 18)
		await _frames(300)
		var scene := get_tree().current_scene
		_check(scene != null and scene.scene_file_path == GameManager.VICTORY, "chegou à tela de vitória")
		_check(GameManager.last_result.get("cores", 0) == 1, "resumo da vitória registrado")
	GameManager.god_mode = false
