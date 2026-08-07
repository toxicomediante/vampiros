class_name EnemyCatalog
extends RefCounted


const NORMAL_ENEMY_IDS: Array[StringName] = [
	&"tarantula",
	&"vampiro_malleiro",
	&"el_fregona",
	&"momia",
	&"piru_enloquecido",
	&"sequeiros",
	&"el_secu",
	&"media_croqueta",
	&"pimiento_infernal",
	&"vampiros",
]

# The atlas cleanup intentionally kept eight cells per sheet so attack timing and
# asset dimensions stayed stable. Some removed base cells were filled with an
# adjacent pose, though, which made idle loops hold on the same image at their
# seam. These sequences keep only the distinct cyclic poses. Combat redistributes
# the original cycle duration over them, so the motion has no artificial pause.
const IDLE_FRAME_SEQUENCES := {
	&"tarantula": [0, 2, 3, 4],
	&"vampiro_malleiro": [0, 2, 3, 4, 5, 6],
	&"el_fregona": [0, 2, 3, 4],
	&"momia": [0, 2, 3, 4, 5],
	&"piru_enloquecido": [0, 2, 4, 6],
	&"sequeiros": [0, 2],
	&"el_secu": [0, 4],
	&"media_croqueta": [0, 2, 3, 4, 5, 6],
	&"pimiento_infernal": [0, 2, 3, 4, 5, 6],
	&"vampiros": [0, 2, 3, 4],
	&"la_mamona": [0, 2, 3, 6],
}

const DEFINITIONS := {
	&"tarantula": {
		"name": "TARÁNTULA",
		"max_hp": 24,
		"damage": 5,
		"tiers": [1, 2],
		"asset_folder": "tarantula",
		"cell_size": Vector2i(724, 543),
		"ground_y": 480.0,
		"anchor_x": 362.0,
		"scale": Vector2(0.82, 0.82),
		"idle_fps": 6.0,
		"attack_fps": 9.0,
		"impact_frame": 4,
	},
	&"vampiro_malleiro": {
		"name": "VAMPIRO MALLEIRO",
		"max_hp": 24,
		"damage": 5,
		"tiers": [1, 2],
		"asset_folder": "vampiro_malleiro",
		"cell_size": Vector2i(543, 724),
		"ground_y": 684.0,
		"anchor_x": 271.5,
		"scale": Vector2(0.66, 0.66),
		"idle_fps": 7.0,
		"attack_fps": 10.0,
		"impact_frame": 4,
	},
	&"el_fregona": {
		"name": "EL FREGONA",
		"max_hp": 30,
		"damage": 6,
		"tiers": [1, 2, 3],
		"asset_folder": "el_fregona",
		"cell_size": Vector2i(512, 768),
		"ground_y": 731.0,
		"anchor_x": 256.0,
		"scale": Vector2(0.64, 0.64),
		"idle_fps": 6.0,
		"attack_fps": 9.0,
		"impact_frame": 4,
	},
	&"momia": {
		"name": "LA MOMIA",
		"max_hp": 34,
		"damage": 6,
		"tiers": [2, 3, 6, 7],
		"asset_folder": "momia",
		"cell_size": Vector2i(543, 724),
		"ground_y": 704.0,
		"anchor_x": 271.5,
		"scale": Vector2(0.68, 0.68),
		"idle_fps": 6.0,
		"attack_fps": 9.0,
		"impact_frame": 4,
	},
	&"piru_enloquecido": {
		"name": "PIRÚ ENLOQUECIDO",
		"max_hp": 32,
		"damage": 6,
		"tiers": [2, 3],
		"asset_folder": "pavo_white_label",
		"cell_size": Vector2i(543, 724),
		"ground_y": 711.0,
		"anchor_x": 271.0,
		"scale": Vector2(0.66, 0.66),
		"idle_fps": 6.0,
		"attack_fps": 9.0,
		"impact_frame": 4,
	},
	&"sequeiros": {
		"name": "SEQUEIROS",
		"max_hp": 40,
		"damage": 5,
		"tiers": [3, 4],
		"asset_folder": "sequeiros",
		"cell_size": Vector2i(512, 768),
		"ground_y": 732.0,
		"anchor_x": 237.0,
		"scale": Vector2(0.64, 0.64),
		"idle_fps": 6.0,
		"attack_fps": 9.0,
		"impact_frame": 4,
	},
	&"el_secu": {
		"name": "EL SECU",
		"max_hp": 42,
		"damage": 7,
		"tiers": [3, 4],
		"asset_folder": "el_futbolin",
		"cell_size": Vector2i(768, 512),
		"ground_y": 500.0,
		"anchor_x": 384.0,
		"scale": Vector2(0.64, 0.64),
		"idle_fps": 7.0,
		"attack_fps": 9.0,
		"impact_frame": 3,
	},
	&"media_croqueta": {
		"name": "MEDIA CROQUETA",
		"max_hp": 46,
		"damage": 5,
		"tiers": [4, 5],
		"asset_folder": "media_croqueta",
		"cell_size": Vector2i(512, 768),
		"ground_y": 736.0,
		"anchor_x": 256.0,
		"scale": Vector2(0.62, 0.62),
		"idle_fps": 7.0,
		"attack_fps": 10.0,
		"impact_frame": 4,
	},
	&"pimiento_infernal": {
		"name": "PIMIENTO INFERNAL",
		"max_hp": 48,
		"damage": 6,
		"tiers": [4, 5],
		"asset_folder": "pimiento_infernal",
		"cell_size": Vector2i(512, 768),
		"ground_y": 738.0,
		"anchor_x": 256.0,
		"scale": Vector2(0.62, 0.62),
		"idle_fps": 8.0,
		"attack_fps": 11.0,
		"impact_frame": 4,
	},
	&"vampiros": {
		"name": "VAMPIROS",
		"max_hp": 58,
		"damage": 9,
		"tiers": [6, 7],
		"asset_folder": "pareja_gaitero_dragon",
		"cell_size": Vector2i(561, 701),
		"ground_y": 690.0,
		"anchor_x": 280.5,
		"scale": Vector2(0.66, 0.66),
		"idle_fps": 6.0,
		"attack_fps": 9.0,
		"impact_frame": 3,
	},
	&"la_mamona": {
		"name": "LA MAMONA",
		"max_hp": 92,
		"damage": 12,
		"tiers": [],
		"asset_folder": "la_mamona",
		"cell_size": Vector2i(543, 724),
		"ground_y": 704.0,
		"anchor_x": 266.0,
		"scale": Vector2(0.74, 0.74),
		"idle_fps": 5.0,
		"attack_fps": 9.0,
		"impact_frame": 4,
	},
}


static func definition(enemy_id: StringName) -> Dictionary:
	if not DEFINITIONS.has(enemy_id):
		push_error("Enemigo desconocido: %s" % enemy_id)
		return {}
	var result: Dictionary = DEFINITIONS[enemy_id].duplicate(true)
	result["id"] = enemy_id
	result["idle_frame_indices"] = IDLE_FRAME_SEQUENCES[enemy_id].duplicate()
	var folder: String = result["asset_folder"]
	result["idle_path"] = "res://assets/enemies/%s/idle_atlas.png" % folder
	result["attack_path"] = "res://assets/enemies/%s/attack_atlas.png" % folder
	return result


static func ids_for_tier(tier: int) -> Array[StringName]:
	var clamped_tier := clampi(tier, 1, 7)
	var result: Array[StringName] = []
	for enemy_id: StringName in NORMAL_ENEMY_IDS:
		var tiers: Array = DEFINITIONS[enemy_id]["tiers"]
		if clamped_tier in tiers:
			result.append(enemy_id)
	return result


static func encounter_for_tier(tier: int, seed_value: int) -> Array[StringName]:
	var pool := ids_for_tier(tier)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for index in range(pool.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var previous := pool[index]
		pool[index] = pool[swap_index]
		pool[swap_index] = previous
	return pool.slice(0, mini(2, pool.size()))


static func definitions_for_ids(enemy_ids: Array[StringName]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy_id: StringName in enemy_ids:
		var enemy_definition := definition(enemy_id)
		if not enemy_definition.is_empty():
			result.append(enemy_definition)
	return result
