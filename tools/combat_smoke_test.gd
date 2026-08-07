extends SceneTree

const EnemyCatalogScript = preload("res://scripts/enemies/enemy_catalog.gd")
const COMBAT_SCENE_PATH := "res://scenes/combat.tscn"
const CHARACTER_IDS := [&"michu", &"juan"]
const BACKGROUND_SOURCE_SIZE := Vector2(1672, 941)
const COMBAT_VIEWPORT_SIZE := Vector2(1920, 1080)
const INTERIOR_LAYOUTS := [
	{
		"player_feet": Vector2(560, 960),
		"enemy_feet": [Vector2(1120, 720), Vector2(1570, 760)],
		"has_foreground": true,
		"foreground_source_rect": Rect2(0, 542, 430, 399),
	},
	{
		"player_feet": Vector2(530, 975),
		"enemy_feet": [Vector2(1080, 800), Vector2(1500, 800)],
		"has_foreground": true,
		"foreground_source_rect": Rect2(0, 692, 349, 249),
	},
	{
		"player_feet": Vector2(650, 950),
		"enemy_feet": [Vector2(1050, 690), Vector2(1450, 720)],
		"has_foreground": false,
		"foreground_source_rect": Rect2(),
	},
]
const STATUS_ATLAS_PATH := "res://assets/ui/combat/status/status_atlas.png"
const COMBAT_NUMBER_FONT_PATH := "res://assets/fonts/press-start-2p-latin-400-normal.woff2"
const COMBAT_NUMBER_NORMAL_COLOR := Color(1.0, 1.0, 1.0)
const COMBAT_NUMBER_STATUS_COLOR := Color(0.38, 1.0, 0.34)
const REWARD_MAT_PATH := "res://assets/ui/combat/reward_mat.png"
const REWARD_MAT_POSITION := Vector2(128.0, 72.0)
const REWARD_MAT_SIZE := Vector2(1664.0, 936.0)
const REWARD_CARD_SIZE := Vector2(296.0, 444.0)
const REWARD_SKIP_BUTTON_POSITION := Vector2(750.0, 790.0)
const REWARD_SKIP_BUTTON_SIZE := Vector2(420.0, 104.0)
const PUB_MEIGAS_BACKGROUND_PATH := "res://assets/backgrounds/combat/pub_meigas.png"
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
	"res://assets/cards/neutral/circulo_negro.png",
	"res://assets/cards/neutral/pollo_con_pollo.png",
	"res://assets/cards/neutral/la_slam.png",
	"res://assets/cards/neutral/la_revancha.png",
	"res://assets/cards/neutral/ahora_la_vi.png",
	"res://assets/cards/neutral/evangelio.png",
	"res://assets/cards/neutral/licor_k.png",
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

	_expect(
		CardCatalog.CARDS[&"fresquita"]["owner"] == CardCatalog.Owner.JUAN,
		"FRESQUITA deja de pertenecer a Juan"
	)
	for character_id: StringName in CHARACTER_IDS:
		var candidates := RewardGenerator.character_candidates(character_id)
		var starting_recipe: Dictionary = CardCatalog.STARTING_DECKS[character_id]
		for starter_card: StringName in starting_recipe:
			_expect(
				not candidates.has(starter_card),
				"%s ofrece la carta básica %s como recompensa" % [
					character_id, starter_card
				]
			)
		for _iteration in 20:
			var generated := RewardGenerator.generate(character_id)
			_expect(
				generated.size() == 3
				and generated[0] != generated[1]
				and generated[0] != generated[2]
				and generated[1] != generated[2],
				"%s no genera tres recompensas" % character_id
			)
			for excluded_card: StringName in [
				&"la_variz", &"la_prole", &"tuerca"
			]:
				_expect(
					not generated.has(excluded_card),
					"%s ofrece %s pese a estar excluida" % [
						character_id, excluded_card
					]
				)
	_expect(
		RewardGenerator.character_candidates(&"juan").has(&"fresquita")
		and RewardGenerator.character_candidates(&"juan").has(&"el_oculto"),
		"las recompensas de Juan omiten FRESQUITA o EL OCULTO"
	)
	_expect(
		RewardGenerator.neutral_candidates().has(&"la_revancha")
		and not RewardGenerator.neutral_candidates().has(&"tuerca"),
		"LA REVANCHA o TUERCA no respetan el corte publicado"
	)

	var status_atlas := load(STATUS_ATLAS_PATH) as Texture2D
	_expect(status_atlas != null, "no se puede cargar el atlas de estados")
	if status_atlas != null:
		_expect(
			status_atlas.get_size() == Vector2(160, 32),
			"el atlas de estados no contiene cinco iconos de 32 px"
		)
	status_atlas = null
	await process_frame

	var reward_mat_texture := load(REWARD_MAT_PATH) as Texture2D
	_expect(reward_mat_texture != null, "no se puede cargar el tapete de recompensa")
	if reward_mat_texture != null:
		_expect(
			reward_mat_texture.get_size() == Vector2(1920, 1080),
			"el tapete de recompensa no conserva la resolución del juego"
		)
	reward_mat_texture = null
	await process_frame

	for interior_index in INTERIOR_LAYOUTS.size():
		game_state.select_combat_interior(interior_index)
		game_state.select_character(&"michu")
		game_state.start_new_run()
		game_state.begin_location(0, 0, &"tavern", interior_index)
		var interior_combat := packed_scene.instantiate()
		root.add_child(interior_combat)
		current_scene = interior_combat
		for _frame in 12:
			await process_frame

		var layout: Dictionary = INTERIOR_LAYOUTS[interior_index]
		var character_root := interior_combat.get_node_or_null(
			"CombatCharacter"
		) as Node2D
		var foreground := interior_combat.get_node_or_null(
			"Foreground"
		) as TextureRect
		var interior_enemies: Array = interior_combat.get("enemies")
		_expect(
			character_root != null and character_root.position == layout["player_feet"],
			"el bar %d no respeta el punto de apoyo del protagonista" % (interior_index + 1)
		)
		_expect(
			foreground != null
			and foreground.visible == layout["has_foreground"]
			and (foreground.texture != null) == layout["has_foreground"],
			"el bar %d no configura correctamente el primer plano" % (interior_index + 1)
		)
		if foreground != null and layout["has_foreground"]:
			var source_rect: Rect2 = layout["foreground_source_rect"]
			var source_to_viewport := COMBAT_VIEWPORT_SIZE / BACKGROUND_SOURCE_SIZE
			_expect(
				foreground.position.distance_to(
					source_rect.position * source_to_viewport
				) < 0.1
				and foreground.size.distance_to(
					source_rect.size * source_to_viewport
				) < 0.1,
				"el primer plano del bar %d no conserva su encaje" % (interior_index + 1)
			)
		_expect(
			interior_enemies.size() == 2,
			"el bar %d no carga los dos enemigos" % (interior_index + 1)
		)
		for enemy_index in mini(interior_enemies.size(), 2):
			var enemy: Dictionary = interior_enemies[enemy_index]
			var enemy_sprite := enemy.get("sprite") as AnimatedSprite2D
			if enemy_sprite != null and enemy_sprite.sprite_frames != null:
				var actual_feet: Vector2 = enemy.get("feet_position")
				_expect(
					actual_feet.distance_to(layout["enemy_feet"][enemy_index]) < 0.1,
					"el enemigo %d del bar %d no apoya los pies en su zona" % [
						enemy_index + 1, interior_index + 1
					]
				)

		current_scene = null
		interior_combat.queue_free()
		for _frame in 3:
			await process_frame

	game_state.select_character(&"michu")
	game_state.start_new_run()
	game_state.begin_location(5, 0, &"meigas", 0)
	var meigas_combat := packed_scene.instantiate()
	root.add_child(meigas_combat)
	current_scene = meigas_combat
	for _frame in 12:
		await process_frame
	var meigas_background := meigas_combat.get_node_or_null("Background") as TextureRect
	var meigas_foreground := meigas_combat.get_node_or_null("Foreground") as TextureRect
	var meigas_enemies: Array = meigas_combat.get("enemies")
	var meigas_options := meigas_combat.get_node_or_null("OptionsHUD") as CanvasLayer
	_expect(
		meigas_background != null
		and meigas_background.texture != null
		and meigas_background.texture.resource_path == PUB_MEIGAS_BACKGROUND_PATH,
		"Pub Meigas no carga su fondo de combate"
	)
	_expect(
		meigas_foreground != null and not meigas_foreground.visible,
		"Pub Meigas conserva un primer plano de otra taberna"
	)
	_expect(
		meigas_enemies.size() == 1 and meigas_enemies[0]["id"] == &"la_mamona",
		"Pub Meigas no presenta a La Mamona"
	)
	_expect(meigas_options != null, "el combate no incluye el menú de opciones")
	current_scene = null
	meigas_combat.queue_free()
	for _frame in 3:
		await process_frame

	game_state.select_combat_interior(0)

	for character_id: StringName in CHARACTER_IDS:
		game_state.select_character(character_id)
		game_state.start_new_run()
		game_state.begin_location(0, 0, &"tavern", 0)
		var combat := packed_scene.instantiate()
		root.add_child(combat)
		current_scene = combat

		for _frame in 90:
			await process_frame

		var curtain := combat.get_node_or_null("Interface/Curtain") as ColorRect
		var player_hud := combat.get_node_or_null("Interface/PlayerHUD")
		var background := combat.get_node_or_null("Background") as TextureRect
		var energy := combat.get_node_or_null("Interface/EnergyCounter") as TextureRect
		var discard_action := combat.get("discard_button") as TextureButton
		var turn_action := combat.get("turn_button") as TextureButton
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
			var hud_frame: TextureRect
			for child: Node in player_hud.get_children():
				if child is TextureRect:
					hud_frame = child as TextureRect
					break
			_expect(
				hud_frame != null
				and hud_frame.size == Vector2(520.0, 199.0),
				"%s no mantiene la geometría compacta del HUD" % character_id
			)
			var hp_background := player_hud.get_node_or_null(
				"PlayerHPBackground"
			) as ColorRect
			var block_background := player_hud.get_node_or_null(
				"PlayerBlockBackground"
			) as ColorRect
			var hp_bar := player_hud.get_node_or_null("PlayerHPBar") as Control
			var block_bar := player_hud.get_node_or_null("PlayerBlockBar") as Control
			var hp_value := player_hud.get_node_or_null("PlayerHPValue") as Label
			var block_value := player_hud.get_node_or_null(
				"PlayerBlockValue"
			) as Label
			_expect(
				_count_textured_rects(player_hud) == 1
				and hud_frame.name == "PlayerHUDFrame"
				and hud_frame.material is ShaderMaterial,
				"%s duplica el marco compacto del HUD" % character_id
			)
			_expect(
				hp_background != null
				and block_background != null
				and hp_bar != null
				and block_bar != null,
				"%s no genera las barras HP/DEF con Godot" % character_id
			)
			_expect(
				hp_background != null
				and hp_background.color == Color(0.035, 0.03, 0.045, 0.96)
				and block_background != null
				and block_background.color == Color(0.035, 0.03, 0.045, 0.96),
				"%s no conserva el fondo oscuro de las barras" % character_id
			)
			var hp_fill: ColorRect
			var block_fill: ColorRect
			if hp_bar != null:
				hp_fill = hp_bar.get_node_or_null("Fill") as ColorRect
			if block_bar != null:
				block_fill = block_bar.get_node_or_null("Fill") as ColorRect
			_expect(
				hp_fill != null and hp_fill.color == Color(0.78, 0.08, 0.12, 1.0),
				"%s no usa rojo en la barra de vida" % character_id
			)
			_expect(
				block_fill != null
				and block_fill.color == Color(0.34, 0.47, 0.60, 1.0),
				"%s no usa gris azulado en la barra de bloqueo" % character_id
			)
			_expect(
				hp_bar != null
				and block_bar != null
				and hp_value != null
				and block_value != null
				and hp_value.get_theme_constant("outline_size") >= 5
				and block_value.get_theme_constant("outline_size") >= 5
				and hp_value.get_theme_font("font") == load(COMBAT_NUMBER_FONT_PATH)
				and block_value.get_theme_font("font") == load(COMBAT_NUMBER_FONT_PATH)
				and hp_bar.z_index < hud_frame.z_index
				and block_bar.z_index < hud_frame.z_index
				and hp_value.z_index > hud_frame.z_index
				and block_value.z_index > hud_frame.z_index,
				"%s no superpone valores numéricos legibles a las barras" % character_id
			)
			var hud_state = combat.get("player")
			if (
				hud_state != null
				and hp_bar != null
				and block_bar != null
				and hp_value != null
				and block_value != null
			):
				hud_state.set("hp", hud_state.get("max_hp"))
				hud_state.set("block", 0)
				combat.call("_refresh_all_ui")
				_expect(
					is_equal_approx(hp_bar.size.x, 337.0)
					and is_equal_approx(block_bar.size.x, 0.0)
					and hp_value.text == "HP  %d / %d" % [
						hud_state.get("max_hp"), hud_state.get("max_hp")
					]
					and block_value.text == "DEF  0",
					"%s no representa bien vida completa y bloqueo cero" % character_id
				)
				hud_state.set("hp", 0)
				hud_state.set("block", 10)
				combat.call("_refresh_all_ui")
				_expect(
					is_equal_approx(hp_bar.size.x, 0.0)
					and is_equal_approx(block_bar.size.x, 168.5)
					and hp_value.text == "HP  0 / %d" % hud_state.get("max_hp")
					and block_value.text == "DEF  10",
					"%s no representa bien vida vacía y bloqueo estimado" % character_id
				)
				hud_state.set("hp", hud_state.get("max_hp"))
				hud_state.set("block", 25)
				combat.call("_refresh_all_ui")
				_expect(
					is_equal_approx(block_bar.size.x, 337.0)
					and block_value.text == "DEF  25",
					"%s no limita visualmente el bloqueo alto conservando su valor" % character_id
				)
				hud_state.set("block", 0)
				combat.call("_refresh_all_ui")
			if character_sprite != null:
				player_hud.position = Vector2(90, 80)
				character_sprite.pause()
				character_sprite.set_frame_and_progress(3, 0.0)
				combat.call("_sync_player_hud_motion", 1.0)
				_expect(
					is_equal_approx(player_hud.position.x, 24.0)
					and absf(player_hud.position.y - 126.0) <= 4.1,
					"%s permite deriva o saltos erráticos en el HUD" % character_id
				)
				var low_position: float = player_hud.position.y
				character_sprite.set_frame_and_progress(0, 0.0)
				combat.call("_sync_player_hud_motion", 1.0)
				_expect(
					low_position - player_hud.position.y >= 3.9,
					"%s no acompasa el HUD con la animación del personaje" % character_id
				)
				character_sprite.play(&"idle")
		_expect(
			background != null and background.texture != null,
			"%s no carga el interior" % character_id
		)
		_expect(
			energy != null and energy.texture != null,
			"%s no carga el contador de energía" % character_id
		)
		_expect(
			energy != null
			and energy.position == Vector2(24.0, 690.0)
			and energy.size == Vector2(230.0, 330.0),
			"%s no mantiene la energía en la nueva alineación" % character_id
		)
		_expect(
			discard_action != null
			and discard_action.texture_normal != null
			and discard_action.position == Vector2(1497.0, 976.0)
			and discard_action.size == Vector2(420.0, 104.0)
			and discard_action.toggle_mode,
			"%s no construye el botón gráfico DESCARTAR" % character_id
		)
		_expect(
			turn_action != null
			and turn_action.texture_normal != null
			and turn_action.position == Vector2(1653.0, 721.0)
			and turn_action.size == Vector2(256.0, 256.0),
			"%s no construye el botón gráfico FIN DE TURNO" % character_id
		)
		if discard_action != null:
			discard_action.button_pressed = true
			await process_frame
			_expect(
				bool(combat.get("discard_mode")),
				"%s pierde el funcionamiento táctil de DESCARTAR" % character_id
			)
			discard_action.button_pressed = false
			await process_frame

		combat.call("_build_reward_offer")
		var offered_reward_ids: Array[StringName] = []
		var reward_mat := combat.get_node_or_null(
			"Presentation/ModalContent/RewardMat"
		) as TextureRect
		var reward_title := combat.get_node_or_null(
			"Presentation/ModalContent/RewardTitle"
		) as Label
		var reward_skip := combat.get_node_or_null(
			"Presentation/ModalContent/RewardSkipButton"
		) as TextureButton
		_expect(
			reward_mat != null
			and reward_mat.texture != null
			and reward_mat.position == REWARD_MAT_POSITION
			and reward_mat.size == REWARD_MAT_SIZE
			and reward_mat.size.x < 1920.0
			and reward_mat.size.y < 1080.0,
			"%s no superpone el tapete dejando visible la escena" % character_id
		)
		_expect(
			reward_title != null
			and reward_title.text == "ELIGE UNA CARTA"
			and reward_title.get_theme_font("font") == load(COMBAT_NUMBER_FONT_PATH),
			"%s no integra el título en la cartela superior" % character_id
		)
		_expect(
			reward_skip != null
			and reward_skip.texture_normal != null
			and reward_skip.position == REWARD_SKIP_BUTTON_POSITION
			and reward_skip.size == REWARD_SKIP_BUTTON_SIZE,
			"%s no integra el botón gráfico OMITIR" % character_id
		)
		for reward_index in 3:
			var reward_card := combat.get_node_or_null(
				"Presentation/ModalContent/RewardCard%d" % reward_index
			) as TextureButton
			_expect(
				reward_card != null
				and reward_card.texture_normal != null
				and reward_card.size == REWARD_CARD_SIZE
				and reward_card.has_meta("card_id"),
				"%s no representa gráficamente la recompensa %d" % [
					character_id, reward_index + 1
				]
			)
			if reward_card != null:
				offered_reward_ids.append(reward_card.get_meta("card_id"))
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
		var target_marker := combat.get_node_or_null(
			"Enemies/EnemyTargetMarker"
		) as Sprite2D
		_expect(
			target_marker != null
			and target_marker.texture != null
			and target_marker.texture.get_size() == Vector2(72, 112)
			and not target_marker.visible,
			"%s no crea la ficha de selección oculta" % character_id
		)
		for enemy: Dictionary in enemies:
			var sprite := enemy.get("sprite") as AnimatedSprite2D
			var enemy_id: StringName = enemy.get("id", &"")
			var definition: Dictionary = EnemyCatalogScript.definition(enemy_id)
			var expected_idle_frames := int(
				definition.get("idle_frame_indices", []).size()
			)
			_expect(
				sprite != null
				and sprite.sprite_frames != null
				and sprite.animation == &"idle"
				and sprite.sprite_frames.get_animation_loop(&"idle")
				and sprite.sprite_frames.get_frame_count(&"idle")
					== expected_idle_frames,
				"%s construye un enemigo sin animación idle" % character_id
			)
		if target_marker != null and not enemies.is_empty():
			var targeted_card: TextureButton
			for hand_button: TextureButton in card_buttons:
				var hand_card_id: StringName = hand_button.get_meta("card_id")
				if (
					CardCatalog.CARDS[hand_card_id]["target"]
					== CardCatalog.Target.ONE_ENEMY
				):
					targeted_card = hand_button
					break
			_expect(
				targeted_card != null,
				"%s no tiene una carta para probar la selección" % character_id
			)
			if targeted_card != null:
				var targeted_card_id: StringName = targeted_card.get_meta("card_id")
				var first_enemy_bounds: Rect2 = enemies[0]["bounds"]
				combat.set("drag_card", targeted_card)
				combat.set("drag_card_id", targeted_card_id)
				combat.call("_refresh_enemy_highlight", first_enemy_bounds.get_center())
				_expect(
					target_marker.visible
					and is_equal_approx(
						target_marker.position.x,
						first_enemy_bounds.get_center().x
					),
					"%s no coloca la ficha sobre el enemigo seleccionado" % character_id
				)
				combat.call("_clear_enemy_highlight")
				_expect(
					not target_marker.visible,
					"%s no oculta la ficha al terminar la selección" % character_id
				)
				combat.set("drag_card", null)
				combat.set("drag_card_id", &"")

		var combat_number_layer := combat.get_node_or_null(
			"Interface/CombatNumbers"
		) as Control
		_expect(
			combat_number_layer != null,
			"%s no crea la capa de números de combate" % character_id
		)
		if combat_number_layer != null:
			var normal_popup := combat.call(
				"_spawn_combat_number", 7, Vector2(700, 500), false, false
			) as Label
			var poison_popup := combat.call(
				"_spawn_combat_number", 3, Vector2(850, 500), false, true
			) as Label
			var healing_popup := combat.call(
				"_spawn_combat_number", 4, Vector2(1000, 500), true, true
			) as Label
			_expect(
				normal_popup != null and normal_popup.text == "-7",
				"%s no muestra el daño normal con signo" % character_id
			)
			_expect(
				poison_popup != null and poison_popup.text == "-3",
				"%s no muestra el daño de veneno con signo" % character_id
			)
			_expect(
				healing_popup != null and healing_popup.text == "+4",
				"%s no muestra la recuperación con signo" % character_id
			)
			var combat_font := load(COMBAT_NUMBER_FONT_PATH) as Font
			if normal_popup != null:
				_expect(
					normal_popup.get_theme_font("font") == combat_font,
					"%s no usa la fuente del proyecto en el daño" % character_id
				)
				_expect(
					normal_popup.get_theme_color("font_color").is_equal_approx(
						COMBAT_NUMBER_NORMAL_COLOR
					),
					"%s no muestra el daño normal en blanco" % character_id
				)
			if poison_popup != null:
				_expect(
					poison_popup.get_theme_color("font_color").is_equal_approx(
						COMBAT_NUMBER_STATUS_COLOR
					),
					"%s no muestra el veneno en verde" % character_id
				)
			if healing_popup != null:
				_expect(
					healing_popup.get_theme_color("font_color").is_equal_approx(
						COMBAT_NUMBER_STATUS_COLOR
					),
					"%s no muestra la recuperación en verde" % character_id
				)
			var popup_origin := normal_popup.position if normal_popup != null else Vector2.ZERO
			await create_timer(0.14).timeout
			if normal_popup != null:
				_expect(
					normal_popup.position.y < popup_origin.y - 18.0
					and normal_popup.scale.x > 1.05,
					"%s no anima el número con movimiento y escala" % character_id
				)
			for popup: Label in [normal_popup, poison_popup, healing_popup]:
				if is_instance_valid(popup):
					popup.queue_free()
			await process_frame
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
		var allowed_cached_ids: Array[StringName] = offered_reward_ids.duplicate()
		for hand_button: TextureButton in card_buttons:
			var hand_card_id: StringName = hand_button.get_meta("card_id")
			if not allowed_cached_ids.has(hand_card_id):
				allowed_cached_ids.append(hand_card_id)
		_expect(not card_cache.is_empty(), "%s no carga cartas" % character_id)
		for cached_id: StringName in card_cache:
			_expect(
				allowed_cached_ids.has(cached_id),
				"%s carga una carta ajena a la mano y la recompensa" % character_id
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

	game_state.select_character(&"juan")
	game_state.start_new_run()
	game_state.begin_location(0, 0, &"tavern", 0)
	var mechanics_combat := packed_scene.instantiate()
	root.add_child(mechanics_combat)
	current_scene = mechanics_combat
	for _frame in 12:
		await process_frame
	var mechanics_deck = mechanics_combat.get("deck")
	var mechanics_player = mechanics_combat.get("player")
	var mechanics_enemies: Array = mechanics_combat.get("enemies")

	mechanics_combat.call(
		"_resolve_card",
		&"circulo_negro",
		CardCatalog.CARDS[&"circulo_negro"],
		0
	)
	_expect(
		mechanics_enemies[0]["state"].get("stun") == 1,
		"CÍRCULO NEGRO no anula el siguiente ataque"
	)

	mechanics_deck.set("hand", [&"pollo_con_pollo"])
	mechanics_combat.call("set_energy", 3)
	mechanics_player.set("poison", 0)
	_expect(
		mechanics_combat.call("_try_play_card", &"pollo_con_pollo", -1)
		and mechanics_player.get("poison") == 2
		and mechanics_deck.get("exhausted_pile").has(&"pollo_con_pollo"),
		"POLLO CON POLLO no envenena y se agota"
	)

	mechanics_deck.set("hand", [&"la_slam"])
	mechanics_combat.call("set_energy", 3)
	var gold_before_slam: int = game_state.run_gold
	_expect(
		mechanics_combat.call("_try_play_card", &"la_slam", -1)
		and game_state.run_gold == gold_before_slam + 20
		and mechanics_deck.get("exhausted_pile").has(&"la_slam"),
		"LA SLAM no entrega 20 de oro y se agota"
	)

	mechanics_combat.set("free_card_counts", {})
	mechanics_deck.set("hand", [&"ahora_la_vi", &"guantazo", &"juan_guardia"])
	mechanics_combat.call("set_energy", 3)
	_expect(
		mechanics_combat.call("_try_play_card", &"ahora_la_vi", -1)
		and mechanics_combat.call("_effective_card_cost", &"guantazo") == 0
		and mechanics_combat.call("_effective_card_cost", &"juan_guardia") == 0,
		"¡AHORA LA VI! no vuelve gratuita la mano actual"
	)

	mechanics_combat.set("free_card_counts", {})
	mechanics_deck.set("hand", [&"evangelio"])
	mechanics_deck.set("draw_pile", [&"guantazo", &"juan_guardia"])
	mechanics_combat.call("set_energy", 3)
	_expect(
		mechanics_combat.call("_try_play_card", &"evangelio", -1)
		and mechanics_deck.get("hand").has(&"guantazo")
		and mechanics_deck.get("hand").has(&"juan_guardia")
		and mechanics_combat.call("_effective_card_cost", &"guantazo") == 0
		and mechanics_combat.call("_effective_card_cost", &"juan_guardia") == 0,
		"EVANGELIO no roba dos cartas gratuitas"
	)

	mechanics_combat.set("free_card_counts", {})
	mechanics_deck.set("hand", [&"licor_k"])
	mechanics_combat.call("set_energy", 3)
	mechanics_player.set("strength", 0)
	_expect(
		mechanics_combat.call("_try_play_card", &"licor_k", -1)
		and mechanics_player.get("strength") == 1,
		"LICOR-K no concede fuerza durante el combate"
	)

	mechanics_combat.set("free_card_counts", {})
	mechanics_deck.set("hand", [&"la_revancha"])
	mechanics_combat.call("set_energy", 3)
	_expect(
		mechanics_combat.call("_try_play_card", &"la_revancha", -1),
		"LA REVANCHA no se puede jugar"
	)
	var discover_overlay := mechanics_combat.get_node_or_null(
		"Presentation/ModalContent/DiscoverOverlay"
	) as Control
	_expect(discover_overlay != null, "LA REVANCHA no abre su elección")
	if discover_overlay != null:
		var first_discovered := discover_overlay.get_node_or_null(
			"DiscoverCard0"
		) as TextureButton
		_expect(
			first_discovered != null
			and discover_overlay.get_node_or_null("DiscoverCard1") != null
			and discover_overlay.get_node_or_null("DiscoverCard2") != null,
			"LA REVANCHA no presenta tres cartas"
		)
		if first_discovered != null:
			var discovered_id: StringName = first_discovered.get_meta("card_id")
			_expect(
				discovered_id not in [&"la_variz", &"la_prole", &"tuerca"],
				"LA REVANCHA ofrece una carta excluida"
			)
			mechanics_combat.call("_choose_discovered_card", discovered_id)
			_expect(
				mechanics_deck.get("hand").has(discovered_id)
				and mechanics_combat.call(
					"_effective_card_cost", discovered_id
				) == 0,
				"LA REVANCHA no añade gratis la carta elegida"
			)

	current_scene = null
	mechanics_combat.queue_free()
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
		print("COMBAT SMOKE OK: 3 fondos, profundidad, Michu, Juan, HUD y cartas")
	quit(1 if failed else 0)
