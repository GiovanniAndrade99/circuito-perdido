extends Node
## Responsável: Giovanni Anicezio Andrade
## Autoload "GameManager": estado global da partida (pontuação, vidas,
## núcleos, checkpoints) e o fluxo entre fases. Os outros nós se comunicam
## com ele por sinais, o que mantém HUD, fases e personagens desacoplados.

signal score_changed(value: int)
signal cells_changed(value: int)
signal cores_changed(value: int)
signal lives_changed(value: int)
signal player_health_changed(current: int, maximum: int)
signal boss_health_changed(current: int, maximum: int)
signal boss_visibility_changed(is_visible: bool)
signal message_requested(text: String)
signal camera_shake_requested(strength: float)

const LEVELS: Array[String] = [
	"res://scenes/levels/Level01.tscn",
	"res://scenes/levels/Level02.tscn",
	"res://scenes/levels/Level03.tscn",
	"res://scenes/levels/BossArena.tscn",
]
const MAIN_MENU := "res://scenes/main/MainMenu.tscn"
const GAME_OVER := "res://scenes/main/GameOver.tscn"
const VICTORY := "res://scenes/main/Victory.tscn"

const TOTAL_CORES := 4
const START_LIVES := 3
const SCORE_CELL := 10
const SCORE_CORE := 100
const SCORE_NO_DAMAGE := 200
const PAR_TIME := 150.0  ## tempo de referência por fase (s) para o bônus de tempo

var score := 0
var cells := 0
var lives := START_LIVES
var deaths := 0
var total_time := 0.0
var level_index := 0
var level_time := 0.0
var cores_before_level := 0   ## núcleos de fases já concluídas
var core_taken := false       ## o núcleo da fase atual já foi pego?
var took_damage := false
var collected := {}           ## chaves "x,y" dos itens já coletados nesta fase
var in_level := false
var god_mode := false         ## só em builds de depuração (F2)
var last_result := {}         ## resumo exibido na tela de vitória

# "Fotografias" do estado para reiniciar a fase ou voltar ao checkpoint.
var _level_start := {}
var _checkpoint := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()


func _process(delta: float) -> void:
	if in_level and not get_tree().paused:
		level_time += delta
		total_time += delta


## Atalhos de depuração (somente quando o jogo roda pelo editor / build debug):
## F1 conclui a fase, F2 liga/desliga a invencibilidade.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not in_level or get_tree().paused:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F1:
		core_taken = true
		var level := get_tree().current_scene
		if level.has_method("on_exit_reached"):
			level.on_exit_reached()
	elif key.keycode == KEY_F2:
		god_mode = not god_mode
		show_message("Modo invencível: %s" % ("LIGADO" if god_mode else "DESLIGADO"))


# ---------------------------------------------------------------------------
# Fluxo do jogo
# ---------------------------------------------------------------------------
func new_game() -> void:
	reset_run()
	_start_level(0)


## Zera o estado de uma partida nova.
func reset_run() -> void:
	score = 0
	cells = 0
	lives = START_LIVES
	deaths = 0
	total_time = 0.0
	cores_before_level = 0
	god_mode = false


## Prepara o estado de uma fase (sem trocar de cena).
func prepare_level(index: int) -> void:
	level_index = index
	core_taken = false
	took_damage = false
	collected = {}
	level_time = 0.0
	_checkpoint = {}
	_level_start = _snapshot()


func _start_level(index: int) -> void:
	prepare_level(index)
	SceneLoader.change_scene(LEVELS[index])


## Chamado pela fase quando termina de se montar.
func level_started() -> void:
	in_level = true
	_emit_all()
	boss_visibility_changed.emit(false)


## Retorna o resultado (bônus) para a fase exibir antes de avançar.
func complete_level() -> Dictionary:
	in_level = false
	var time_bonus := int(maxf(0.0, PAR_TIME - level_time)) * 2
	var damage_bonus := 0 if took_damage else SCORE_NO_DAMAGE
	add_score(time_bonus + damage_bonus)
	if core_taken:
		cores_before_level += 1
		core_taken = false
	return {"time": level_time, "time_bonus": time_bonus, "damage_bonus": damage_bonus}


func go_to_next_level() -> void:
	if level_index + 1 < LEVELS.size():
		_start_level(level_index + 1)
	else:
		_finish_game()


func _finish_game() -> void:
	var record: bool = SaveManager.submit_score(score)
	last_result = {
		"score": score, "time": total_time, "cells": cells,
		"deaths": deaths, "record": record, "cores": cores_before_level,
	}
	SceneLoader.change_scene(VICTORY)


func player_died() -> void:
	in_level = false
	deaths += 1
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		SceneLoader.change_scene(GAME_OVER)
	else:
		# Volta ao último checkpoint (ou ao início) com o estado daquele momento.
		_restore(_checkpoint if has_checkpoint() else _level_start)
		SceneLoader.change_scene(LEVELS[level_index])


## "Tentar novamente" na tela de Game Over: recomeça a fase com vidas cheias.
func retry_level() -> void:
	lives = START_LIVES
	restart_level()


## "Reiniciar fase" no menu de pausa.
func restart_level() -> void:
	in_level = false
	_checkpoint = {}
	_restore(_level_start)
	level_time = 0.0
	SceneLoader.change_scene(LEVELS[level_index])


func go_to_menu() -> void:
	in_level = false
	SceneLoader.change_scene(MAIN_MENU)


# ---------------------------------------------------------------------------
# Pontuação, itens e checkpoints
# ---------------------------------------------------------------------------
func add_score(value: int) -> void:
	score += value
	score_changed.emit(score)


func get_cores() -> int:
	return cores_before_level + (1 if core_taken else 0)


func is_collected(key: String) -> bool:
	return collected.has(key)


func register_collected(key: String) -> void:
	collected[key] = true


func collect_cell(key: String) -> void:
	register_collected(key)
	cells += 1
	cells_changed.emit(cells)
	add_score(SCORE_CELL)


func collect_core(key: String) -> void:
	register_collected(key)
	core_taken = true
	cores_changed.emit(get_cores())
	add_score(SCORE_CORE)


func set_checkpoint(pos: Vector2) -> void:
	_checkpoint = _snapshot()
	_checkpoint["position"] = pos


func has_checkpoint() -> bool:
	return not _checkpoint.is_empty()


func checkpoint_position() -> Vector2:
	return _checkpoint.get("position", Vector2.ZERO)


func notify_player_damaged() -> void:
	took_damage = true


func show_message(text: String) -> void:
	message_requested.emit(text)


func request_shake(strength: float) -> void:
	camera_shake_requested.emit(strength)


func _snapshot() -> Dictionary:
	return {
		"score": score, "cells": cells, "core": core_taken,
		"collected": collected.duplicate(), "took_damage": took_damage,
	}


func _restore(state: Dictionary) -> void:
	score = state["score"]
	cells = state["cells"]
	core_taken = state["core"]
	collected = (state["collected"] as Dictionary).duplicate()
	took_damage = state["took_damage"]
	_emit_all()


func _emit_all() -> void:
	score_changed.emit(score)
	cells_changed.emit(cells)
	cores_changed.emit(get_cores())
	lives_changed.emit(lives)


# ---------------------------------------------------------------------------
# Controles (criados por código para ficarem documentados num só lugar)
# ---------------------------------------------------------------------------
func _setup_input() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_add_action("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_add_action("jump", [KEY_SPACE, KEY_W, KEY_UP], [JOY_BUTTON_A])
	_add_action("shoot", [KEY_J, KEY_K, KEY_X], [JOY_BUTTON_X], -1, 0.0, true)
	_add_action("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])


func _add_action(action: String, keys: Array, buttons: Array, axis: int = -1,
		axis_value: float = 0.0, mouse: bool = false) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.35)
	for keycode in keys:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = keycode
		InputMap.action_add_event(action, key_event)
	for button in buttons:
		var joy_button := InputEventJoypadButton.new()
		joy_button.button_index = button
		InputMap.action_add_event(action, joy_button)
	if axis >= 0:
		var joy_motion := InputEventJoypadMotion.new()
		joy_motion.axis = axis as JoyAxis
		joy_motion.axis_value = axis_value
		InputMap.action_add_event(action, joy_motion)
	if mouse:
		var mouse_button := InputEventMouseButton.new()
		mouse_button.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(action, mouse_button)
