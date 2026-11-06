class_name SpriteLib
## Responsável: Carlos Eduardo Peraçolli
## Monta SpriteFrames (animações) e o TileSet a partir das folhas PNG geradas
## por tools/gerar_sprites.py. Cada folha é uma tira horizontal de quadros do
## mesmo tamanho; as animações são listas de índices de quadro.

# Índices dos quadros em tiles.png
const TILE_GROUND_TOP := 0
const TILE_GROUND_INNER := 1
const TILE_PLATFORM := 2
const TILE_CRATE := 3
const TILE_SPIKES := 4
const TILE_PRESS_HEAD := 9
const TILE_PRESS_ROD := 10
const TILE_MOVING_PLATFORM := 11

# Índices dos quadros em items.png usados fora de animações (HUD)
const ITEM_CELL := 0
const ITEM_HEART := 4
const ITEM_HEART_EMPTY := 5
const ITEM_CORE := 6
const ITEM_LAMP := 14

## nome da folha -> caminho, tamanho do quadro e animações [quadros, fps, loop]
const SHEETS := {
	"player": {"path": "res://assets/sprites/player.png", "size": Vector2i(32, 32), "anims": {
		"idle": [[0, 1, 2, 3], 4.0, true],
		"run": [[4, 5, 6, 7, 8, 9], 12.0, true],
		"jump": [[10], 1.0, false],
		"fall": [[11], 1.0, false],
		"hurt": [[12], 1.0, false],
	}},
	"patrol": {"path": "res://assets/sprites/patrol.png", "size": Vector2i(32, 32), "anims": {
		"move": [[0, 1, 0, 1, 0, 1, 2, 3], 8.0, true],
	}},
	"turret": {"path": "res://assets/sprites/turret.png", "size": Vector2i(32, 32), "anims": {
		"idle": [[0], 1.0, true],
		"charge": [[0, 1], 10.0, true],
		"fire": [[2], 1.0, false],
	}},
	"kamikaze": {"path": "res://assets/sprites/kamikaze.png", "size": Vector2i(32, 32), "anims": {
		"idle": [[0, 1], 12.0, true],
		"chase": [[2, 3, 0, 1], 16.0, true],
	}},
	"boss": {"path": "res://assets/sprites/boss.png", "size": Vector2i(96, 96), "anims": {
		"idle": [[0, 1], 8.0, true],
		"charge": [[2, 0], 14.0, true],
		"stunned": [[3], 1.0, false],
	}},
	"items": {"path": "res://assets/sprites/items.png", "size": Vector2i(32, 32), "anims": {
		"cell": [[0, 1, 2, 3], 8.0, true],
		"heart": [[4], 1.0, true],
		"core": [[6, 7, 8, 9], 8.0, true],
		"cp_off": [[10], 1.0, true],
		"cp_on": [[11, 12], 3.0, true],
		"sign": [[13], 1.0, true],
		"lamp": [[14], 1.0, true],
		"shot_player": [[15], 1.0, true],
		"shot_enemy": [[16], 1.0, true],
	}},
	"portal": {"path": "res://assets/sprites/portal.png", "size": Vector2i(64, 96), "anims": {
		"locked": [[0], 1.0, true],
		"open": [[1, 2, 3, 4], 10.0, true],
	}},
	"tiles": {"path": "res://assets/sprites/tiles.png", "size": Vector2i(32, 32), "anims": {
		"conveyor": [[5, 6, 7, 8], 12.0, true],
	}},
}

# Cache: cada SpriteFrames é criado uma única vez e compartilhado.
static var _frames_cache := {}
static var _tileset: TileSet = null


## Retorna as animações (SpriteFrames) de uma folha.
static func frames(sheet: String) -> SpriteFrames:
	if _frames_cache.has(sheet):
		return _frames_cache[sheet]
	var info: Dictionary = SHEETS[sheet]
	var tex: Texture2D = load(info["path"])
	var size: Vector2i = info["size"]
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")
	var anims: Dictionary = info["anims"]
	for anim_name in anims:
		var data: Array = anims[anim_name]
		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, data[1])
		sprite_frames.set_animation_loop(anim_name, data[2])
		for index in data[0]:
			sprite_frames.add_frame(anim_name, _atlas(tex, size, index))
	_frames_cache[sheet] = sprite_frames
	return sprite_frames


## Retorna um único quadro de uma folha (para HUD, tiles avulsos etc.).
static func texture(sheet: String, index: int) -> AtlasTexture:
	var info: Dictionary = SHEETS[sheet]
	return _atlas(load(info["path"]), info["size"], index)


## TileSet do terreno: blocos sólidos e plataforma atravessável (one-way).
static func tileset() -> TileSet:
	if _tileset:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, Layers.WORLD)
	ts.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = load(SHEETS["tiles"]["path"])
	source.texture_region_size = Vector2i(32, 32)
	ts.add_source(source, 0)  # adicionar antes de criar tiles: assim herdam a camada de física

	var full := PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)])
	for index in [TILE_GROUND_TOP, TILE_GROUND_INNER]:
		source.create_tile(Vector2i(index, 0))
		var data := source.get_tile_data(Vector2i(index, 0), 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, full)

	# Plataforma: colisão só na faixa superior e atravessável por baixo.
	source.create_tile(Vector2i(TILE_PLATFORM, 0))
	var platform := source.get_tile_data(Vector2i(TILE_PLATFORM, 0), 0)
	platform.add_collision_polygon(0)
	platform.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-16, -16), Vector2(16, -16), Vector2(16, -6), Vector2(-16, -6)]))
	platform.set_collision_polygon_one_way(0, 0, true)

	_tileset = ts
	return ts


static func _atlas(tex: Texture2D, size: Vector2i, index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(index * size.x, 0, size.x, size.y)
	return atlas
