extends CanvasLayer
## Responsável: Giovanni Anicezio Andrade
## Autoload "SceneLoader": troca de cenas com transição (fade para preto).

const FADE_TIME := 0.25

var _curtain: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_curtain = ColorRect.new()
	_curtain.color = Color("1a1c2c")
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.modulate.a = 0.0
	add_child(_curtain)


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP  # bloqueia cliques durante a troca
	var tween := create_tween()
	tween.tween_property(_curtain, "modulate:a", 1.0, FADE_TIME)
	await tween.finished

	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	# A troca acontece no fim do quadro; espera a nova cena ficar pronta.
	await get_tree().process_frame
	await get_tree().process_frame

	tween = create_tween()
	tween.tween_property(_curtain, "modulate:a", 0.0, FADE_TIME)
	await tween.finished
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
