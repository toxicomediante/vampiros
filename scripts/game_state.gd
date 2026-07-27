extends Node

const VALID_CHARACTERS := [&"michu", &"juan"]
const COMBAT_INTERIOR_COUNT := 3

var selected_character: StringName = &"michu"
var selected_combat_interior := 0
var run_deck: Array[StringName] = []
var run_hp := 0


func select_character(character_id: String) -> void:
	var requested := StringName(character_id)
	if requested not in VALID_CHARACTERS:
		push_error("Personaje desconocido: %s" % character_id)
		return
	selected_character = requested


func start_new_run() -> void:
	run_deck = CardCatalog.build_starting_deck(selected_character)
	run_hp = 72 if selected_character == &"juan" else 60


func ensure_run() -> void:
	if run_deck.is_empty():
		start_new_run()


func add_reward_card(card_id: StringName) -> void:
	run_deck.append(card_id)


func select_combat_interior(interior_index: int) -> void:
	if interior_index < 0 or interior_index >= COMBAT_INTERIOR_COUNT:
		push_error("Interior de combate desconocido: %d" % interior_index)
		return
	selected_combat_interior = interior_index
