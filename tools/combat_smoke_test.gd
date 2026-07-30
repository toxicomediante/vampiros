extends SceneTree

const COMBAT_SCENE_PATH := "res://scenes/combat.tscn"
const CHARACTER_IDS := [&"michu", &"juan"]

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	_expect(game_state != null, "GameState no está disponible")
	if game_state == null:
		_finish()
		return

	var packed_scene := load(COMBAT_SCENE_PATH) as PackedScene
	_expect(packed_scene != null, "combat.tscn no se puede cargar")
	if packed_scene == null:
		_finish()
		return

	for character_id: StringName in CHARACTER_IDS:
		game_state.select_character(character_id)
		game_state.start_new_run()
		var combat := packed_scene.instantiate()
		root.add_child(combat)
		current_scene = combat

		for _frame in 90:
			await process_frame

		var curtain := combat.get_node_or_null("Interface/Curtain") as ColorRect
		var player_hud := combat.get_node_or_null("Interface/PlayerHUD")
		var background := combat.get_node_or_null("Background") as TextureRect
		var energy := combat.get_node_or_null("Interface/EnergyCounter") as TextureRect
		var card_buttons: Array = combat.get("card_buttons")
		var card_cache: Dictionary = combat.get("card_texture_cache")

		_expect(curtain != null, "%s no tiene telón" % character_id)
		if curtain != null:
			_expect(
				curtain.color.a < 0.01,
				"%s deja el telón negro visible" % character_id
			)
		_expect(player_hud != null, "%s no construye la UI HP/DEF" % character_id)
		_expect(
			background != null and background.texture != null,
			"%s no carga el interior" % character_id
		)
		_expect(
			energy != null and energy.texture != null,
			"%s no carga el contador de energía" % character_id
		)
		_expect(
			card_buttons.size() == 5,
			"%s no roba una mano inicial de 5 cartas" % character_id
		)
		_expect(
			card_cache.size() <= 3,
			"%s carga cartas que no están en la mano" % character_id
		)

		current_scene = null
		combat.queue_free()
		await process_frame

	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("COMBAT SMOKE TEST: %s" % message)


func _finish() -> void:
	if not failed:
		print("COMBAT SMOKE OK: Michu, Juan, UI, telón y carga selectiva")
	quit(1 if failed else 0)
