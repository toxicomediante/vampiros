extends Node

const VALID_CHARACTERS := [&"michu", &"juan"]
const COMBAT_INTERIOR_COUNT := 3
const DEFAULT_ROUTE_SEED := 1
const TAVERN_VARIANT_COUNT := 3
const TRUJILLO_MIDDLE_STEPS := [3, 4, 5]

var selected_character: StringName = &"michu"
var selected_combat_interior := 0

var run_deck: Array[StringName] = []
var run_hp := 0
var run_currency := 0
var run_seed := DEFAULT_ROUTE_SEED

var run_route_nodes: Array = []
var run_route_connections: Array = []
var current_route_step := -1
var current_route_branch := -1
var pending_route_step := -1
var pending_route_branch := -1
var pending_location_kind: StringName = &""
var pending_encounter: Array[StringName] = []
var completed_route_nodes: Array[String] = []

var shop_stock: Array[StringName] = []
var shop_purchased: Array[StringName] = []


func select_character(character_id: String) -> void:
	var requested := StringName(character_id)
	if requested not in VALID_CHARACTERS:
		push_error("Personaje desconocido: %s" % character_id)
		return
	selected_character = requested


func start_new_run() -> void:
	run_deck = CardCatalog.build_starting_deck(selected_character)
	run_hp = 72 if selected_character == &"juan" else 60
	run_currency = 0

	var seed_rng := RandomNumberGenerator.new()
	seed_rng.randomize()
	run_seed = seed_rng.randi()

	run_route_nodes.clear()
	run_route_connections.clear()
	current_route_step = -1
	current_route_branch = -1
	_clear_pending_destination()
	completed_route_nodes.clear()
	shop_stock.clear()
	shop_purchased.clear()


func reset_run() -> void:
	run_deck.clear()
	run_hp = 0
	run_currency = 0
	run_seed = DEFAULT_ROUTE_SEED
	run_route_nodes.clear()
	run_route_connections.clear()
	current_route_step = -1
	current_route_branch = -1
	_clear_pending_destination()
	completed_route_nodes.clear()
	shop_stock.clear()
	shop_purchased.clear()


func ensure_run() -> void:
	if run_deck.is_empty():
		start_new_run()


func ensure_route(
	step_positions: Array,
	start_position: Vector2,
	castle_position: Vector2
) -> void:
	if (
		not run_route_nodes.is_empty()
		and run_route_nodes.size() == step_positions.size()
		and run_route_connections.size() == step_positions.size() + 1
	):
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	run_route_nodes = _build_route_nodes(step_positions, rng)
	run_route_connections = _build_route_connections(
		step_positions,
		start_position,
		castle_position,
		rng
	)


func _build_route_nodes(step_positions: Array, rng: RandomNumberGenerator) -> Array:
	var nodes: Array = []
	if step_positions.is_empty():
		return nodes

	var middle_candidates: Array[int] = []
	for candidate: int in TRUJILLO_MIDDLE_STEPS:
		if candidate >= 0 and candidate < step_positions.size():
			middle_candidates.append(candidate)
	if middle_candidates.is_empty():
		middle_candidates.append(step_positions.size() / 2)

	var trujillo_step: int = middle_candidates[
		rng.randi_range(0, middle_candidates.size() - 1)
	]
	var trujillo_branch := rng.randi_range(
		0, step_positions[trujillo_step].size() - 1
	)

	var meigas_step := rng.randi_range(1, step_positions.size() - 1)
	var meigas_branch := rng.randi_range(
		0, step_positions[meigas_step].size() - 1
	)
	while (
		meigas_step == trujillo_step
		and meigas_branch == trujillo_branch
	):
		meigas_step = rng.randi_range(1, step_positions.size() - 1)
		meigas_branch = rng.randi_range(
			0, step_positions[meigas_step].size() - 1
		)

	var previous_taverns: Array[int] = []
	for step_index in step_positions.size():
		var step_nodes: Array = []
		var current_taverns: Array[int] = []
		for branch_index in step_positions[step_index].size():
			var node := {
				"kind": &"tavern",
				"tavern_variant": 0,
			}
			if step_index == trujillo_step and branch_index == trujillo_branch:
				node["kind"] = &"trujillo"
			elif step_index == meigas_step and branch_index == meigas_branch:
				node["kind"] = &"meigas"
			else:
				var variant := _choose_tavern_variant(
					rng,
					previous_taverns,
					current_taverns
				)
				node["tavern_variant"] = variant
				if not current_taverns.has(variant):
					current_taverns.append(variant)
			step_nodes.append(node)
		nodes.append(step_nodes)
		previous_taverns = current_taverns
	return nodes


func _choose_tavern_variant(
	rng: RandomNumberGenerator,
	previous_step: Array[int],
	current_step: Array[int]
) -> int:
	var candidates: Array[int] = []

	# Un nivel nunca muestra los tres modelos a la vez. Si ya hay dos modelos
	# distintos, se reutiliza uno de esos dos.
	if current_step.size() >= 2:
		candidates = current_step.duplicate()
	else:
		for variant in TAVERN_VARIANT_COUNT:
			if (
				not previous_step.has(variant)
				and not current_step.has(variant)
			):
				candidates.append(variant)

	# Cuando no se puede evitar repetir respecto al nivel anterior, se prioriza
	# al menos un modelo que todavía no esté presente en el nivel actual.
	if candidates.is_empty():
		for variant in TAVERN_VARIANT_COUNT:
			if not current_step.has(variant):
				candidates.append(variant)
	if candidates.is_empty():
		candidates = [0, 1, 2]

	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _build_route_connections(
	step_positions: Array,
	start_position: Vector2,
	castle_position: Vector2,
	rng: RandomNumberGenerator
) -> Array:
	var layers: Array = []
	layers.append(
		_connect_position_layers([start_position], step_positions[0], rng)
	)
	for step_index in step_positions.size() - 1:
		layers.append(
			_connect_position_layers(
				step_positions[step_index],
				step_positions[step_index + 1],
				rng
			)
		)
	layers.append(
		_connect_position_layers(
			step_positions[-1],
			[castle_position],
			rng
		)
	)
	return layers


func _connect_position_layers(
	from_nodes: Array,
	to_nodes: Array,
	rng: RandomNumberGenerator
) -> Dictionary:
	var pairs := {}
	for from_index in from_nodes.size():
		var nearest_to := _nearest_position_index(
			from_nodes[from_index], to_nodes
		)
		pairs[Vector2i(from_index, nearest_to)] = true
	for to_index in to_nodes.size():
		var nearest_from := _nearest_position_index(
			to_nodes[to_index], from_nodes
		)
		pairs[Vector2i(nearest_from, to_index)] = true

	if (
		from_nodes.size() > 1
		and to_nodes.size() > 1
		and rng.randf() < 0.7
	):
		pairs[Vector2i(
			rng.randi_range(0, from_nodes.size() - 1),
			rng.randi_range(0, to_nodes.size() - 1)
		)] = true

	var connections := {}
	for pair: Vector2i in pairs:
		if not connections.has(pair.x):
			connections[pair.x] = []
		connections[pair.x].append(pair.y)
	for from_index in connections:
		connections[from_index].sort()
	return connections


func _nearest_position_index(origin: Vector2, candidates: Array) -> int:
	var nearest := 0
	var nearest_distance := INF
	for candidate_index in candidates.size():
		var distance: float = origin.distance_squared_to(
			candidates[candidate_index]
		)
		if distance < nearest_distance:
			nearest = candidate_index
			nearest_distance = distance
	return nearest


func next_route_branches() -> Array[int]:
	var result: Array[int] = []
	var layer_index := current_route_step + 1
	if (
		layer_index < 0
		or layer_index >= run_route_connections.size()
	):
		return result

	var source_branch := 0 if current_route_step < 0 else current_route_branch
	var layer: Dictionary = run_route_connections[layer_index]
	for branch: int in layer.get(source_branch, []):
		result.append(branch)
	return result


func next_route_step() -> int:
	return current_route_step + 1


func castle_is_next() -> bool:
	return (
		not run_route_nodes.is_empty()
		and next_route_step() >= run_route_nodes.size()
	)


func begin_route_destination(
	step_index: int,
	branch_index: int,
	location_kind: StringName,
	interior_index: int
) -> void:
	pending_route_step = step_index
	pending_route_branch = branch_index
	pending_location_kind = location_kind
	pending_encounter.clear()
	if location_kind == &"tavern" or location_kind == &"meigas":
		select_combat_interior(interior_index)


func complete_pending_destination() -> void:
	if pending_route_step < 0:
		return
	current_route_step = pending_route_step
	current_route_branch = pending_route_branch
	var node_id := route_node_id(current_route_step, current_route_branch)
	if not completed_route_nodes.has(node_id):
		completed_route_nodes.append(node_id)
	_clear_pending_destination()


func complete_castle_destination() -> void:
	current_route_step = run_route_nodes.size()
	current_route_branch = 0
	_clear_pending_destination()


func _clear_pending_destination() -> void:
	pending_route_step = -1
	pending_route_branch = -1
	pending_location_kind = &""
	pending_encounter.clear()


func route_node_id(step_index: int, branch_index: int) -> String:
	return "%d:%d" % [step_index, branch_index]


func set_pending_encounter(enemy_ids: Array[StringName]) -> void:
	pending_encounter = enemy_ids.duplicate()


func add_currency(amount: int) -> void:
	run_currency = maxi(0, run_currency + amount)


func spend_currency(amount: int) -> bool:
	if amount < 0 or run_currency < amount:
		return false
	run_currency -= amount
	return true


func add_reward_card(card_id: StringName) -> void:
	run_deck.append(card_id)


func set_shop_stock(card_ids: Array[StringName]) -> void:
	shop_stock = card_ids.duplicate()
	shop_purchased.clear()


func mark_shop_card_purchased(card_id: StringName) -> void:
	if not shop_purchased.has(card_id):
		shop_purchased.append(card_id)


func select_combat_interior(interior_index: int) -> void:
	if interior_index < 0 or interior_index >= COMBAT_INTERIOR_COUNT:
		push_error("Interior de combate desconocido: %d" % interior_index)
		return
	selected_combat_interior = interior_index
