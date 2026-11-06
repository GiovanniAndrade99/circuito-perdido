class_name LevelBase
extends Node2D
## Responsável: Giovanni Anicezio Andrade (motor de fases)
## Monta uma fase a partir de um mapa em texto (ASCII), definido em cada
## script de fase. Cada caractere vira um tile do TileMapLayer ou instancia
## uma cena:
##   #  bloco sólido            =  plataforma atravessável
##   ^  espinhos                <  >  esteira (para esquerda / direita)
##   o  célula de energia       h  coração           C  núcleo
##   K  checkpoint              E  portal de saída   P  início do jogador
##   d  robô patrulheiro        t  torreta           k  kamikaze     S  chefe
##   M  plataforma móvel horizontal    V  plataforma móvel vertical
##   X  prensa (presa no teto)         B  caixa empurrável
##   L  lâmpada                 1-9  placa de dica (texto em get_hints())
## Assim o level design é feito editando texto, sem mexer em código.

const TILE := 32
const PLAYER_SCENE := preload("res://scenes/actors/Player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/PauseMenu.tscn")
const SPIKES_SCENE := preload("res://scenes/objects/Spikes.tscn")
const CONVEYOR_SCENE := preload("res://scenes/objects/Conveyor.tscn")
const MOVING_PLATFORM_SCENE := preload("res://scenes/objects/MovingPlatform.tscn")
const PRESS_SCENE := preload("res://scenes/objects/Press.tscn")
const HINT_SCENE := preload("res://scenes/objects/HintSign.tscn")
const LAMP_SCENE := preload("res://scenes/objects/Lamp.tscn")
const COLLECTIBLE_CHARS := "ohC"
const ENTITY_SCENES := {
	"o": preload("res://scenes/objects/EnergyCell.tscn"),
	"h": preload("res://scenes/objects/Heart.tscn"),
	"C": preload("res://scenes/objects/Core.tscn"),
	"K": preload("res://scenes/objects/Checkpoint.tscn"),
	"E": preload("res://scenes/objects/ExitPortal.tscn"),
	"d": preload("res://scenes/actors/PatrolBot.tscn"),
	"t": preload("res://scenes/actors/Turret.tscn"),
	"k": preload("res://scenes/actors/Kamikaze.tscn"),
	"S": preload("res://scenes/actors/Boss.tscn"),
	"B": preload("res://scenes/objects/Crate.tscn"),
}
const SOLID_CHARS := "#<>"
const MOVE_DISTANCE := 4  ## tiles percorridos pelas plataformas móveis

@export var level_title := "Fase"
@export var level_subtitle := ""
@export var music := "level"
@export var dark := false
@export var sky_top := Color("1a1c2c")
@export var sky_bottom := Color("29366f")

var player: Player
var hud: GameHUD
var terrain: TileMapLayer
var map_size := Vector2i.ZERO

var _rows: PackedStringArray
var _player_start := Vector2(64, 64)
var _exiting := false


## Mapa da fase (sobrescrito por cada fase).
func get_map() -> String:
	return ""


## Textos das placas de dica 1..9 (sobrescrito por cada fase).
func get_hints() -> Array:
	return []


## Gancho chamado depois que a fase foi montada.
func _on_level_built() -> void:
	pass


func _ready() -> void:
	_rows = _parse_rows(get_map())
	var background := GameBackground.new()
	background.sky_top = sky_top
	background.sky_bottom = sky_bottom
	add_child(background)

	terrain = TileMapLayer.new()
	terrain.name = "Terreno"
	terrain.tile_set = SpriteLib.tileset()
	add_child(terrain)
	_build_map()

	# HUD antes do jogador, para já receber o sinal de vida inicial.
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	add_child(PAUSE_SCENE.instantiate())
	_spawn_player()
	_setup_camera()
	if dark:
		_setup_darkness()
	_on_level_built()

	AudioManager.play_music(music)
	GameManager.level_started()
	hud.show_banner(level_title, level_subtitle)


# ---------------------------------------------------------------------------
# Leitura do mapa
# ---------------------------------------------------------------------------
func _parse_rows(text: String) -> PackedStringArray:
	var rows := PackedStringArray()
	for line in text.split("\n"):
		rows.append(line.replace("\r", ""))
	while rows.size() > 0 and rows[0].strip_edges() == "":
		rows.remove_at(0)
	while rows.size() > 0 and rows[rows.size() - 1].strip_edges() == "":
		rows.remove_at(rows.size() - 1)
	return rows


func _build_map() -> void:
	var width := 0
	for row in _rows:
		width = maxi(width, row.length())
	map_size = Vector2i(width, _rows.size())
	var hints := get_hints()

	for y in _rows.size():
		var row: String = _rows[y]
		var x := 0
		while x < row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			var pos := cell_center(cell)
			match ch:
				"#":
					var tile := SpriteLib.TILE_GROUND_INNER if _is_solid(x, y - 1) else SpriteLib.TILE_GROUND_TOP
					terrain.set_cell(cell, 0, Vector2i(tile, 0))
				"=":
					terrain.set_cell(cell, 0, Vector2i(SpriteLib.TILE_PLATFORM, 0))
				"^", "<", ">":
					# Sequências iguais viram um único objeto (menos nós, colisão contínua).
					var run := _run_length(row, x, ch)
					_spawn_run(ch, x, y, run)
					x += run
					continue
				"P":
					_player_start = pos
				"M":
					_spawn(MOVING_PLATFORM_SCENE, pos, {"offset": Vector2(MOVE_DISTANCE * TILE, 0)})
				"V":
					_spawn(MOVING_PLATFORM_SCENE, pos, {"offset": Vector2(0, -MOVE_DISTANCE * TILE)})
				"X":
					_spawn(PRESS_SCENE, pos, {"travel": _free_cells_below(x, y) * TILE, "start_delay": randf() * 1.0})
				"L":
					_spawn(LAMP_SCENE, pos, {"with_light": dark})
				_:
					if ch.is_valid_int() and int(ch) >= 1 and int(ch) <= hints.size():
						_spawn(HINT_SCENE, pos, {"text": hints[int(ch) - 1]})
					elif ENTITY_SCENES.has(ch):
						_spawn_entity(ch, x, y, pos)
			x += 1


func _spawn_entity(ch: String, x: int, y: int, pos: Vector2) -> void:
	if COLLECTIBLE_CHARS.contains(ch):
		var key := "%d,%d" % [x, y]
		if GameManager.is_collected(key):
			return  # já foi coletado antes do último checkpoint
		_spawn(ENTITY_SCENES[ch], pos, {"key": key})
	else:
		_spawn(ENTITY_SCENES[ch], pos)


func _spawn_run(ch: String, x: int, y: int, run: int) -> void:
	var pos := Vector2((x + run * 0.5) * TILE, y * TILE + TILE * 0.5)
	if ch == "^":
		_spawn(SPIKES_SCENE, pos, {"length": run})
	else:
		_spawn(CONVEYOR_SCENE, pos, {"length": run, "speed": 90.0 if ch == ">" else -90.0})


func _spawn(scene: PackedScene, pos: Vector2, props: Dictionary = {}) -> Node2D:
	var node: Node2D = scene.instantiate()
	for property in props:
		node.set(property, props[property])
	node.position = pos
	add_child(node)
	return node


func _run_length(row: String, x: int, ch: String) -> int:
	var run := 0
	while x + run < row.length() and row[x + run] == ch:
		run += 1
	return run


func _char_at(x: int, y: int) -> String:
	if y < 0 or y >= _rows.size() or x < 0 or x >= _rows[y].length():
		return " "
	return _rows[y][x]


func _is_solid(x: int, y: int) -> bool:
	return SOLID_CHARS.contains(_char_at(x, y))


## Quantas células livres existem abaixo de (x, y) até o chão (usado pela prensa).
func _free_cells_below(x: int, y: int) -> int:
	var count := 0
	var yy := y + 1
	while yy < _rows.size() and not _is_solid(x, yy) and _char_at(x, yy) != "=":
		count += 1
		yy += 1
	return count


func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE * 0.5, cell.y * TILE + TILE * 0.5)


# ---------------------------------------------------------------------------
# Jogador, câmera e iluminação
# ---------------------------------------------------------------------------
func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = GameManager.checkpoint_position() if GameManager.has_checkpoint() else _player_start
	player.kill_y = map_size.y * TILE + 64.0
	add_child(player)


func _setup_camera() -> void:
	var camera := player.camera
	camera.limit_left = 0
	camera.limit_right = map_size.x * TILE
	camera.limit_bottom = map_size.y * TILE
	camera.limit_top = mini(0, map_size.y * TILE - 720)
	camera.make_current()
	camera.reset_smoothing()


func _setup_darkness() -> void:
	var darkness := CanvasModulate.new()
	darkness.color = Color(0.2, 0.2, 0.32)
	add_child(darkness)
	var light := PointLight2D.new()
	light.texture = Fx.light_texture()
	light.texture_scale = 2.4
	light.energy = 1.15
	light.color = Color("c8f4ff")
	player.add_child(light)


# ---------------------------------------------------------------------------
# Fim da fase
# ---------------------------------------------------------------------------
func on_exit_reached() -> void:
	if _exiting or player.state == Player.State.DEAD:
		return
	_exiting = true
	player.input_enabled = false
	player.set_physics_process(false)
	player.hurtbox.set_deferred("monitoring", false)
	AudioManager.play_sfx("portal")
	Fx.burst(self, player.global_position, Color("73eff7"), 24, 200.0, 0.8, -50.0, 5.0)
	var tween := create_tween()
	tween.tween_property(player.sprite, "scale", Vector2(0.1, 2.2), 0.35)
	tween.tween_property(player.sprite, "modulate:a", 0.0, 0.15)
	var result := GameManager.complete_level()
	hud.show_level_complete(result)
	await get_tree().create_timer(3.0, false).timeout
	GameManager.go_to_next_level()
