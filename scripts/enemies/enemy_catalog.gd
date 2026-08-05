class_name EnemyCatalog
extends RefCounted

const ENEMIES := {
	&"tarantula": {
		"id": &"tarantula",
		"name": "TARÁNTULA",
		"tier": 1,
		"max_hp": 30,
		"damage": 4,
		"currency": 8,
		"texture_path": "res://assets/enemies/tarantula.png",
		"scale": Vector2(0.86, 0.86),
		"visible_bottom": 482.0,
	},
	&"malleiro": {
		"id": &"malleiro",
		"name": "VAMPIRO MALLEIRO",
		"tier": 1,
		"max_hp": 28,
		"damage": 5,
		"currency": 10,
		"texture_path": "res://assets/enemies/vampiro_malleiro.png",
		"scale": Vector2(0.66, 0.66),
		"visible_bottom": 686.0,
	},
}


static func generate_encounter(
	route_step: int,
	run_seed: int,
	route_node_id: String
) -> Array[StringName]:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed ^ hash("encounter:%s" % route_node_id)

	var available: Array[StringName] = []
	for enemy_id: StringName in ENEMIES:
		var definition: Dictionary = ENEMIES[enemy_id]
		if int(definition["tier"]) <= _maximum_tier(route_step):
			available.append(enemy_id)
	_shuffle_with_rng(available, rng)

	if available.is_empty():
		return []

	var encounter_size := 1
	var pair_probability := 0.25
	if route_step >= 3:
		pair_probability = 0.45
	if route_step >= 6:
		pair_probability = 0.60
	if available.size() >= 2 and rng.randf() < pair_probability:
		encounter_size = 2

	var encounter: Array[StringName] = []
	for index in mini(encounter_size, available.size()):
		encounter.append(available[index])
	return encounter


static func _shuffle_with_rng(
	values: Array[StringName],
	rng: RandomNumberGenerator
) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := values[index]
		values[index] = values[swap_index]
		values[swap_index] = value


static func encounter_currency(enemy_ids: Array[StringName]) -> int:
	var total := 0
	for enemy_id: StringName in enemy_ids:
		if ENEMIES.has(enemy_id):
			total += int(ENEMIES[enemy_id]["currency"])
	return total


static func _maximum_tier(route_step: int) -> int:
	if route_step >= 6:
		return 3
	if route_step >= 3:
		return 2
	return 1
