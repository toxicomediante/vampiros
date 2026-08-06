extends Node

const EnemyCatalogScript = preload("res://scripts/enemies/enemy_catalog.gd")

const VALID_CHARACTERS := [&"michu", &"juan"]
const COMBAT_INTERIOR_COUNT := 3
const MAX_ROUTE_STEPS := 8
const TIER_CAP := 7
const TRUJILLO_STEP_INDEX := 3
const MEIGAS_STEP_INDEX := 5

var selected_character: StringName = &"michu"
var selected_combat_interior := 0
var run_deck: Array[StringName] = []
var run_hp := 0
var run_gold := 0
var run_statuses := {
	"poison": 0,
	"regeneration": 0,
	"vulnerable": 0,
	"strength": 0,
	"autodefense": 0,
}

var route_seed := 0
var route_step := 0
var route_data: Array = []
var route_branch_history: Array[int] = []
var pending_step := -1
var pending_branch := -1
var pending_location_kind: StringName = &""
var pending_encounter_ids: Array[StringName] = []
var last_gold_reward := 0
var shop_inventory: Array[StringName] = []


func select_character(character_id: String) -> void:
	var requested := StringName(character_id)
	if requested not in VALID_CHARACTERS:
		push_error("Personaje desconocido: %s" % character_id)
		return
	selected_character = requested


func start_new_run() -> void:
	run_deck = CardCatalog.build_starting_deck(selected_character)
	run_hp = 72 if selected_character == &"juan" else 60
	run_gold = 0
	run_statuses = {
		"poison": 0,
		"regeneration": 0,
		"vulnerable": 0,
		"strength": 0,
		"autodefense": 0,
	}
	route_seed = int(Time.get_ticks_usec()) ^ randi()
	route_step = 0
	route_data.clear()
	route_branch_history.clear()
	_clear_pending_location()
	last_gold_reward = 0
	shop_inventory.clear()


func abandon_run() -> void:
	run_deck.clear()
	run_hp = 0
	run_gold = 0
	route_step = 0
	route_data.clear()
	route_branch_history.clear()
	_clear_pending_location()
	last_gold_reward = 0
	shop_inventory.clear()


func ensure_run() -> void:
	if run_deck.is_empty():
		start_new_run()


func add_reward_card(card_id: StringName) -> void:
	if CardCatalog.CARDS.has(card_id):
		run_deck.append(card_id)


func add_gold(amount: int) -> void:
	run_gold = maxi(0, run_gold + amount)


func spend_gold(amount: int) -> bool:
	if amount < 0 or run_gold < amount:
		return false
	run_gold -= amount
	return true


func save_player_state(state: Object) -> void:
	if state == null:
		return
	run_hp = int(state.get("hp"))
	for property_name: String in run_statuses:
		run_statuses[property_name] = int(state.get(property_name))


func restore_player_state(state: Object) -> void:
	if state == null:
		return
	state.set("hp", clampi(run_hp, 1, int(state.get("max_hp"))))
	for property_name: String in run_statuses:
		state.set(property_name, int(run_statuses[property_name]))


func select_combat_interior(interior_index: int) -> void:
	if interior_index < 0 or interior_index >= COMBAT_INTERIOR_COUNT:
		push_error("Interior de combate desconocido: %d" % interior_index)
		return
	selected_combat_interior = interior_index


func build_route(step_sizes: Array[int]) -> Array:
	if not route_data.is_empty():
		return route_data
	var rng := RandomNumberGenerator.new()
	rng.seed = route_seed
	var trujillo_branch := rng.randi_range(0, step_sizes[TRUJILLO_STEP_INDEX] - 1)
	var meigas_branch := rng.randi_range(0, step_sizes[MEIGAS_STEP_INDEX] - 1)
	for step_index in step_sizes.size():
		var step_data: Array = []
		var variant_offset := rng.randi_range(0, COMBAT_INTERIOR_COUNT - 1)
		for branch_index in step_sizes[step_index]:
			var kind: StringName = &"tavern"
			if step_index == TRUJILLO_STEP_INDEX and branch_index == trujillo_branch:
				kind = &"trujillo"
			elif step_index == MEIGAS_STEP_INDEX and branch_index == meigas_branch:
				kind = &"meigas"
			var tavern_variant := (
				variant_offset + step_index + branch_index
			) % COMBAT_INTERIOR_COUNT
			step_data.append({
				"kind": kind,
				"tavern_variant": tavern_variant,
			})
		route_data.append(step_data)
	return route_data


func begin_location(
	step_index: int,
	branch_index: int,
	location_kind: StringName,
	tavern_variant: int
) -> void:
	pending_step = step_index
	pending_branch = branch_index
	pending_location_kind = location_kind
	select_combat_interior(tavern_variant)
	pending_encounter_ids.clear()
	shop_inventory.clear()
	if location_kind == &"meigas":
		pending_encounter_ids = [&"la_mamona"]
	elif location_kind == &"tavern":
		var tier := mini(step_index + 1, TIER_CAP)
		var encounter_seed := route_seed + step_index * 7919 + branch_index * 104729
		pending_encounter_ids = EnemyCatalogScript.encounter_for_tier(
			tier, encounter_seed
		)


func current_encounter() -> Array[Dictionary]:
	if pending_encounter_ids.is_empty():
		pending_encounter_ids = EnemyCatalogScript.encounter_for_tier(
			mini(route_step + 1, TIER_CAP), route_seed + route_step * 7919
		)
	return EnemyCatalogScript.definitions_for_ids(pending_encounter_ids)


func current_tier() -> int:
	var source_step := pending_step if pending_step >= 0 else route_step
	return clampi(source_step + 1, 1, TIER_CAP)


func award_combat_gold() -> int:
	var reward := 12 + current_tier() * 4
	if pending_location_kind == &"meigas":
		reward += 20
	last_gold_reward = reward
	add_gold(reward)
	return reward


func complete_location() -> void:
	if pending_step < 0:
		return
	while route_branch_history.size() <= pending_step:
		route_branch_history.append(0)
	route_branch_history[pending_step] = pending_branch
	route_step = maxi(route_step, pending_step + 1)
	_clear_pending_location()
	shop_inventory.clear()


func prepare_shop_inventory() -> Array[StringName]:
	if not shop_inventory.is_empty():
		return shop_inventory
	var pool := CardCatalog.character_reward_pool(selected_character)
	pool.append_array([
		&"katana_escondida",
		&"el_camino_te_camela",
		&"la_variz",
	])
	var rng := RandomNumberGenerator.new()
	rng.seed = route_seed + current_tier() * 65537 + 31337
	for index in range(pool.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var previous := pool[index]
		pool[index] = pool[swap_index]
		pool[swap_index] = previous
	shop_inventory.assign(pool.slice(0, mini(3, pool.size())))
	return shop_inventory


func _clear_pending_location() -> void:
	pending_step = -1
	pending_branch = -1
	pending_location_kind = &""
	pending_encounter_ids.clear()
