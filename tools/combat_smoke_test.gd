extends SceneTree

const COMBAT_SCENE_PATH := "res://scenes/combat.tscn"
const CHARACTER_IDS := [&"michu", &"juan"]
const STATUS_ATLAS_PATH := "res://assets/ui/combat/status/status_atlas.png"
const CARD_TEXTURE_PATHS := [
	"res://assets/cards/juan/guantazo.png",
	"res://assets/cards/juan/guardia.png",
	"res://assets/cards/juan/tiriviento.png",
	"res://assets/cards/juan/fresquita.png",
	"res://assets/cards/juan/siempre_sale_bien.png",
	"res://assets/cards/juan/el_oculto.png",
	"res://assets/cards/michu/mojadita.png",
	"res://assets/cards/michu/guardia.png",
	"res://assets/cards/michu/bocanegra.png",
	"res://assets/cards/michu/petardo.png",
	"res://assets/cards/michu/trilita.png",
	"res://assets/cards/michu/choriza.png",
	"res://assets/cards/neutral/katana.png",
	"res://assets/cards/neutral/camino.png",
	"res://assets/cards/neutral/variz.png",
]

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

	for card_path: String in CARD_TEXTURE_PATHS:
		var texture := load(card_path) as Texture2D
		_expect(texture != null, "no se puede cargar %s" % card_path)
		if texture != null:
			_expect(
				texture.get_size() == Vector2(512, 768),
				"%s no tiene tamaño Web seguro" % card_path
			)
		texture = null
		await process_frame

	var status_atlas := load(STATUS_ATLAS_PATH) as Texture2D
	_expect(status_atlas != null, "no se puede cargar el atlas de estados")
	if status_atlas != null:
		_expect(
			status_atlas.get_size() == Vector2(160, 32),
			"el atlas de estados no contiene cinco iconos de 32 px"
		)
	status_atlas = null
	await process_frame

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
		var character_sprite := combat.get_node_or_null(
			"CombatCharacter/Sprite"
		) as AnimatedSprite2D
		var card_buttons: Array = combat.get("card_buttons")
		var card_cache: Dictionary = combat.get("card_texture_cache")
		var enemies: Array = combat.get("enemies")

		_expect(curtain != null, "%s no tiene telón" % character_id)
		if curtain != null:
			_expect(
				curtain.color.a < 0.01,
				"%s deja el telón negro visible" % character_id
			)
		_expect(player_hud != null, "%s no construye la UI HP/DEF" % character_id)
		if player_hud != null:
			_expect(
				is_equal_approx(player_hud.size.x, 520.0)
				and player_hud.size.y >= 199.0,
				"%s no mantiene la geometría compacta del HUD" % character_id
			)
			_expect(
				_count_textured_rects(player_hud) == 5,
				"%s construye una UI HP/DEF sin todas sus texturas" % character_id
			)
			if character_sprite != null:
				player_hud.position = Vector2(24, 126)
				character_sprite.frame = 3
				combat.call("_sync_player_hud_motion", 1.0)
				_expect(
					player_hud.position.distance_to(Vector2(24, 126)) > 8.0,
					"%s no hace deliberado el movimiento del HUD" % character_id
				)
		_expect(
			background != null and background.texture != null,
			"%s no carga el interior" % character_id
		)
		_expect(
			energy != null and energy.texture != null,
			"%s no carga el contador de energía" % character_id
		)
		if energy != null and energy.texture != null:
			var energy_position := energy.position
			var energy_size := energy.size
			for energy_value in [3, 2, 1, 0]:
				combat.call("set_energy", energy_value)
				var state_texture := energy.texture as AtlasTexture
				_expect(
					state_texture != null
					and state_texture.region == Rect2(
						(3 - energy_value) * 256, 0, 256, 373
					),
					"%s recorta mal el estado %d/3" % [
						character_id, energy_value
					]
				)
				_expect(
					energy.position == energy_position and energy.size == energy_size,
					"%s mueve el contador al cambiar a %d/3" % [
						character_id, energy_value
					]
				)
			combat.call("set_energy", 3)
		var player_state = combat.get("player")
		var player_status_row := combat.get_node_or_null(
			"Interface/PlayerHUD/PlayerStatusRow"
		) as HBoxContainer
		_expect(
			player_status_row != null,
			"%s no crea la fila de estados del protagonista" % character_id
		)
		if player_state != null and player_status_row != null:
			player_state.set("poison", 2)
			player_state.set("strength", 1)
			player_state.set("regeneration", 3)
			player_state.set("autodefense", 4)
			player_state.set("vulnerable", 2)
			combat.call("_refresh_all_ui")
			_expect(
				player_status_row.visible and player_status_row.get_child_count() == 5,
				"%s no muestra los cinco estados con iconos" % character_id
			)
			_expect_status_item(
				player_status_row, 0, 0, 2, Color(0.38, 1.0, 0.34),
				"%s veneno" % character_id
			)
			_expect_status_item(
				player_status_row, 1, 1, 1, Color(1.0, 0.27, 0.20),
				"%s fuerza" % character_id
			)
			_expect_status_item(
				player_status_row, 2, 2, 3, Color(0.38, 1.0, 0.34),
				"%s regeneración" % character_id
			)
			_expect_status_item(
				player_status_row, 3, 3, 4, Color(0.82, 0.84, 0.88),
				"%s autodefensa" % character_id
			)
			_expect_status_item(
				player_status_row, 4, 4, 2, Color(1.0, 0.27, 0.20),
				"%s vulnerable" % character_id
			)
			for property_name: StringName in [
				&"poison", &"strength", &"regeneration", &"autodefense", &"vulnerable"
			]:
				player_state.set(property_name, 0)
			combat.call("_refresh_all_ui")

		_expect(
			enemies.size() == 2,
			"%s no carga los dos enemigos" % character_id
		)
		for enemy: Dictionary in enemies:
			var sprite := enemy.get("sprite") as Sprite2D
			_expect(
				sprite != null and sprite.texture != null,
				"%s construye un enemigo sin textura" % character_id
			)
		_expect(
			card_buttons.size() == 5,
			"%s no roba una mano inicial de 5 cartas" % character_id
		)
		for button: TextureButton in card_buttons:
			_expect(
				button.texture_normal != null,
				"%s construye una carta visible sin textura" % character_id
			)
		_expect(
			combat.get_node_or_null("Interface/CardPreview") == null,
			"%s aún crea una copia para ampliar la carta" % character_id
		)
		if not card_buttons.is_empty():
			var first_card := card_buttons[0] as TextureButton
			var home_position: Vector2 = first_card.get_meta("home_position")
			combat.call("_on_card_hovered", first_card)
			await create_timer(0.20).timeout
			_expect(
				first_card.scale.x > 1.55
				and first_card.position.y < home_position.y
				and first_card.z_index == 90,
				"%s no anima la propia carta al hacer hover" % character_id
			)
			combat.call("_on_card_unhovered", first_card)
			await create_timer(0.25).timeout
			_expect(
				first_card.scale.distance_to(Vector2.ONE) < 0.02
				and first_card.position.distance_to(home_position) < 0.2,
				"%s no devuelve la carta ampliada al abanico" % character_id
			)
			combat.call("_select_card", first_card)
			await create_timer(0.20).timeout
			_expect(
				first_card.scale.x > 1.55,
				"%s no amplía la misma carta seleccionada" % character_id
			)
			combat.call("_select_card", first_card)
			await create_timer(0.20).timeout

			var local_grab := Vector2(52, 94)
			var touch := InputEventScreenTouch.new()
			touch.position = local_grab
			var expected_pointer := first_card.get_global_transform() * local_grab
			var converted_pointer: Vector2 = combat.call(
				"_card_event_canvas_position",
				first_card,
				touch
			)
			_expect(
				converted_pointer.distance_to(expected_pointer) < 0.1,
				"%s mezcla coordenadas locales y globales al tocar" % character_id
			)

			var origin: Vector2 = first_card.get_meta("home_position")
			var moved_pointer := expected_pointer + Vector2(48, -48)
			combat.call(
				"_begin_card_press",
				first_card,
				first_card.get_meta("card_id"),
				expected_pointer,
				0
			)
			combat.call(
				"_update_card_press",
				first_card,
				moved_pointer,
				0
			)
			_expect(
				combat.get("drag_card") == first_card,
				"%s no inicia el arrastre tras superar el umbral" % character_id
			)
			var drag_grab_local: Vector2 = combat.get("drag_grab_local")
			_expect(
				(
					first_card.get_global_transform()
					* drag_grab_local
				).distance_to(moved_pointer) < 0.1,
				"%s pierde el punto exacto donde se agarró la carta" % character_id
			)
			combat.call(
				"_finish_card_press",
				first_card,
				moved_pointer,
				0
			)
			await create_timer(0.20).timeout
			_expect(
				first_card.position.distance_to(origin) < 0.1
				and combat.get("drag_card") == null,
				"%s no devuelve una carta tras un destino inválido" % character_id
			)
		_expect(
			not card_cache.is_empty() and card_cache.size() <= 3,
			"%s carga cartas que no están en la mano" % character_id
		)
		for cached_texture: Texture2D in card_cache.values():
			_expect(
				cached_texture != null,
				"%s conserva una carta inválida en caché" % character_id
			)

		current_scene = null
		combat.queue_free()
		for _frame in 5:
			await process_frame

	_finish()


func _expect_status_item(
	row: HBoxContainer,
	index: int,
	frame: int,
	amount: int,
	color: Color,
	context: String
) -> void:
	if row == null or index >= row.get_child_count():
		_expect(false, "%s no existe" % context)
		return
	var item := row.get_child(index) as HBoxContainer
	_expect(item != null and item.get_child_count() == 2, "%s está mal agrupado" % context)
	if item == null or item.get_child_count() != 2:
		return
	var icon := item.get_child(0) as TextureRect
	var label := item.get_child(1) as Label
	var atlas := icon.texture as AtlasTexture if icon != null else null
	_expect(
		atlas != null and atlas.region == Rect2(frame * 32, 0, 32, 32),
		"%s usa un icono incorrecto" % context
	)
	_expect(
		label != null and label.text == str(amount),
		"%s muestra un valor incorrecto" % context
	)
	if label != null:
		_expect(
			label.get_theme_color("font_color").is_equal_approx(color),
			"%s usa un color incorrecto" % context
		)


func _count_textured_rects(node: Node) -> int:
	var count := 0
	if node is TextureRect and (node as TextureRect).texture != null:
		count += 1
	for child: Node in node.get_children():
		count += _count_textured_rects(child)
	return count


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("COMBAT SMOKE TEST: %s" % message)


func _finish() -> void:
	if not failed:
		print("COMBAT SMOKE OK: Michu, Juan, HUD compacto, cartas y carga selectiva")
	quit(1 if failed else 0)
