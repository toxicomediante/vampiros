extends SceneTree

const SCENE_CASES := [
	{
		"scene": "res://scenes/main.tscn",
		"resources": [
			"res://assets/characters/michu_idle.png",
			"res://assets/characters/juan_idle.png",
		],
	},
	{
		"scene": "res://scenes/overworld.tscn",
		"resources": [
			"res://assets/overworld/overworld_map_top.png",
			"res://assets/overworld/overworld_map_bottom.png",
			"res://assets/overworld/taberna_01.png",
			"res://assets/overworld/taberna_02.png",
			"res://assets/overworld/taberna_03.png",
			"res://assets/overworld/pub_meigas.png",
			"res://assets/overworld/supermercados_trujillo.png",
			"res://assets/characters/overworld/michu_overworld_animations.png",
		],
	},
	{
		"scene": "res://scenes/shop.tscn",
		"resources": [
			"res://assets/backgrounds/shop/supermercados_trujillo.png",
			"res://assets/ui/combat/reward_mat.png",
			"res://assets/ui/currency/coins.png",
			"res://assets/npcs/trujillo/idle_atlas.png",
			"res://assets/npcs/trujillo/dialogue_atlas.png",
		],
	},
	{
		"scene": "res://scenes/coming_soon.tscn",
		"resources": [
			"res://assets/ui/vampiros_logo.png",
		],
	},
]

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	_expect(game_state != null, "GameState no está disponible")
	if game_state != null:
		game_state.select_character(&"michu")

	for test_case: Dictionary in SCENE_CASES:
		var scene_path: String = test_case["scene"]
		var packed_scene := load(scene_path) as PackedScene
		_expect(packed_scene != null, "%s no se puede cargar" % scene_path)
		if packed_scene == null:
			continue

		var scene := packed_scene.instantiate()
		root.add_child(scene)
		current_scene = scene
		for _frame in 12:
			await process_frame

		for resource_path: String in test_case["resources"]:
			_expect(
				ResourceLoader.has_cached(resource_path),
				"%s no carga %s" % [scene_path, resource_path]
			)

		current_scene = null
		scene.queue_free()
		scene = null
		packed_scene = null
		for _frame in 12:
			await process_frame

		for resource_path: String in test_case["resources"]:
			_expect(
				not ResourceLoader.has_cached(resource_path),
				"%s retiene %s al salir" % [scene_path, resource_path]
			)

	if not failed:
		print("SCENE LIFECYCLE OK: título, mapa y tienda liberan sus texturas")
	quit(1 if failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("SCENE LIFECYCLE TEST: %s" % message)
