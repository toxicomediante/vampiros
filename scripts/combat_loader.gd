extends Control

const COMBAT_SCENE_PATH := "res://scenes/combat.tscn"

@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	call_deferred("_open_combat")


func _open_combat() -> void:
	# Deja que Godot libere por completo el mapa antes de cargar las texturas
	# grandes del combate. En Web esto evita el pico de memoria entre escenas.
	await get_tree().process_frame
	await get_tree().process_frame

	var packed_scene := ResourceLoader.load(
		COMBAT_SCENE_PATH,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REUSE
	) as PackedScene
	if packed_scene == null:
		_show_error("NO SE PUDO CARGAR EL COMBATE")
		return

	var change_error := get_tree().change_scene_to_packed(packed_scene)
	if change_error != OK:
		_show_error("NO SE PUDO ABRIR EL COMBATE · ERROR %d" % change_error)


func _show_error(message: String) -> void:
	push_error(message)
	status_label.text = message
	status_label.modulate = Color(1.0, 0.42, 0.38)
