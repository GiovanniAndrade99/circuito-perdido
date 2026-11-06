extends Node
## Responsável: Carlos Eduardo Peraçolli
## Autoload "AudioManager": toca efeitos sonoros (com um pool de players para
## permitir vários sons ao mesmo tempo) e trilhas com transição suave.
## Usa os barramentos de áudio "Music" e "SFX" para o controle de volume.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const SFX_NAMES := [
	"jump", "land", "shoot", "hit", "hurt", "death", "enemy_death", "explosion",
	"cell", "heart", "core", "checkpoint", "portal", "locked", "ui_click", "ui_hover",
	"shield", "press", "boss_charge", "boss_shoot", "victory", "game_over",
]
const POOL_SIZE := 12
const SILENT_DB := -40.0

var _sfx := {}
var _pool: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music_players: Array[AudioStreamPlayer] = []
var _active_music := 0
var _current_music := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # sons de interface tocam com o jogo pausado
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for sfx_name in SFX_NAMES:
		_sfx[sfx_name] = load(SFX_DIR + sfx_name + ".wav")
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_pool.append(player)
	for i in 2:
		var music := AudioStreamPlayer.new()
		music.bus = "Music"
		add_child(music)
		_music_players.append(music)
	set_bus_volume("Music", SaveManager.get_value("music_volume", 0.7))
	set_bus_volume("SFX", SaveManager.get_value("sfx_volume", 0.8))


## Toca um efeito. pitch_variation dá variedade a sons repetidos (pulo, tiro).
func play_sfx(sfx_name: String, pitch_variation: float = 0.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _sfx.get(sfx_name)
	if stream == null:
		push_warning("SFX inexistente: " + sfx_name)
		return
	var player := _pool[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


## Troca a trilha com crossfade. Não reinicia se já estiver tocando.
func play_music(music_name: String, fade_time: float = 0.8) -> void:
	if music_name == _current_music:
		return
	_current_music = music_name
	var stream := load(MUSIC_DIR + music_name + ".wav") as AudioStreamWAV
	if stream == null:
		push_warning("Música inexistente: " + music_name)
		return
	# Ativa o loop do WAV sem lacuna (em amostras).
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)

	var old_player := _music_players[_active_music]
	_active_music = 1 - _active_music
	var new_player := _music_players[_active_music]
	new_player.stream = stream
	new_player.volume_db = SILENT_DB
	new_player.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(new_player, "volume_db", 0.0, fade_time)
	tween.tween_property(old_player, "volume_db", SILENT_DB, fade_time)
	tween.chain().tween_callback(old_player.stop)


func stop_music(fade_time: float = 0.6) -> void:
	_current_music = ""
	var player := _music_players[_active_music]
	var tween := create_tween()
	tween.tween_property(player, "volume_db", SILENT_DB, fade_time)
	tween.tween_callback(player.stop)


## Volume linear (0 a 1) de um barramento.
func set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, linear <= 0.001)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
