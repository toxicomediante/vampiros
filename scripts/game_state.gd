extends Node

const VALID_CHARACTERS := [&"michu", &"juan"]
const COMBAT_INTERIOR_COUNT := 3

var selected_character: StringName = &"michu"
var selected_combat_interior := 0


func select_character(character_id: String) -> void:
	var requested := StringName(character_id)
	if requested not in VALID_CHARACTERS:
		push_error("Personaje desconocido: %s" % character_id)
		return
	selected_character = requested


func select_combat_interior(interior_index: int) -> void:
	if interior_index < 0 or interior_index >= COMBAT_INTERIOR_COUNT:
		push_error("Interior de combate desconocido: %d" % interior_index)
		return
	selected_combat_interior = interior_index
