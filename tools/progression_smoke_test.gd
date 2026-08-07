extends SceneTree

const EnemyCatalogScript = preload("res://scripts/enemies/enemy_catalog.gd")
const CombatantStateScript = preload("res://scripts/combat/combatant_state.gd")
const SHOP_SCENE_PATH := "res://scenes/shop.tscn"
const COMING_SOON_SCENE_PATH := "res://scenes/coming_soon.tscn"
const STEP_SIZES: Array[int] = [2, 2, 2, 3, 2, 3, 2, 2]

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	_expect(game_state != null, "GameState no está disponible")
	if game_state == null:
		_finish()
		return

	game_state.select_character(&"michu")
	game_state.start_new_run()
	var route: Array = game_state.build_route(STEP_SIZES)
	_expect(route.size() == 8, "la ruta no contiene ocho tramos")
	_expect(
		_count_kind(route[3], &"trujillo") == 1,
		"Trujillo no aparece una vez en el punto medio"
	)
	_expect(
		_count_kind(route[5], &"meigas") == 1,
		"Pub Meigas no aparece una vez en el sexto tramo"
	)

	var expected_tier_counts := [3, 5, 5, 4, 2, 2, 2]
	for tier_index in expected_tier_counts.size():
		_expect(
			EnemyCatalogScript.ids_for_tier(tier_index + 1).size()
			== expected_tier_counts[tier_index],
			"el tier %d no respeta el inventario" % (tier_index + 1)
		)

	for enemy_id: StringName in EnemyCatalogScript.DEFINITIONS:
		var definition := EnemyCatalogScript.definition(enemy_id)
		_expect(
			int(definition["max_hp"]) > 0 and int(definition["damage"]) > 0,
			"%s no tiene balance básico" % enemy_id
		)
		for animation_path: String in [
			definition["idle_path"], definition["attack_path"]
		]:
			var texture := load(animation_path) as Texture2D
			_expect(texture != null, "no se puede cargar %s" % animation_path)
			if texture != null:
				var cell_size: Vector2i = definition["cell_size"]
				_expect(
					texture.get_size() == Vector2(cell_size.x * 4, cell_size.y * 2),
					"%s no usa atlas 4x2" % animation_path
				)
			texture = null
			await process_frame

	game_state.begin_location(0, 0, &"tavern", 0)
	_expect(
		game_state.current_encounter().size() == 2,
		"un combate normal no selecciona dos enemigos"
	)
	var state := CombatantStateScript.new(60)
	state.hp = 43
	state.poison = 2
	state.strength = 1
	state.regeneration = 3
	state.autodefense = 4
	state.vulnerable = 2
	game_state.save_player_state(state)
	var restored := CombatantStateScript.new(60)
	game_state.restore_player_state(restored)
	_expect(
		restored.hp == 43
		and restored.poison == 2
		and restored.strength == 1
		and restored.regeneration == 3
		and restored.autodefense == 4
		and restored.vulnerable == 2,
		"los estados del protagonista no sobreviven entre locales"
	)
	var previous_gold: int = game_state.run_gold
	var reward: int = game_state.award_combat_gold()
	_expect(reward == 16 and game_state.run_gold == previous_gold + 16, "el oro del tier 1 es incorrecto")
	game_state.complete_location()
	_expect(game_state.route_step == 1, "la victoria no avanza la ruta")

	game_state.begin_location(3, 0, &"trujillo", 0)
	game_state.run_gold = 100
	var deck_size_before: int = game_state.run_deck.size()
	var packed_shop := load(SHOP_SCENE_PATH) as PackedScene
	_expect(packed_shop != null, "la tienda no se puede cargar")
	if packed_shop != null:
		var shop := packed_shop.instantiate()
		root.add_child(shop)
		current_scene = shop
		for _frame in 12:
			await process_frame
		var offers := shop.get_node_or_null("Interface/Offers") as Control
		var npc := shop.get_node_or_null("Shopkeeper/Sprite") as AnimatedSprite2D
		var exit_button := shop.get_node_or_null("Interface/ExitButton") as TextureButton
		var options_hud := shop.get_node_or_null("OptionsHUD") as CanvasLayer
		var first_offer: TextureButton
		if offers != null:
			first_offer = offers.get_node_or_null("ShopCard0") as TextureButton
		_expect(first_offer != null, "Trujillo no ofrece tres cartas comprables")
		_expect(npc != null and npc.animation == &"idle", "el tendero no inicia su idle")
		_expect(
			npc != null and npc.get_parent().scale.x >= 1.0,
			"el tendero sigue apareciendo pequeño y esquinado"
		)
		_expect(
			exit_button != null and exit_button.texture_normal != null,
			"Trujillo no usa el botón SALIR gráfico"
		)
		_expect(options_hud != null, "Trujillo no incluye el menú de opciones")
		if first_offer != null:
			first_offer.emit_signal("pressed")
			await process_frame
			_expect(
				game_state.run_deck.size() == deck_size_before + 1
				and game_state.run_gold < 100,
				"la compra no añade la carta y descuenta su precio"
			)
			_expect(npc.animation == &"dialogue", "la compra no dispara el diálogo")
		current_scene = null
		shop.queue_free()
		for _frame in 3:
			await process_frame

	_expect(
		load(COMING_SOON_SCENE_PATH) is PackedScene,
		"la escena PRÓXIMAMENTE no se puede cargar"
	)
	game_state.abandon_run()
	_finish()


func _count_kind(step: Array, kind: StringName) -> int:
	var count := 0
	for node_data: Dictionary in step:
		if node_data["kind"] == kind:
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PROGRESSION SMOKE TEST: %s" % message)


func _finish() -> void:
	if not failed:
		print("PROGRESSION SMOKE OK: tiers, ruta, oro, tienda y castillo")
	quit(1 if failed else 0)
