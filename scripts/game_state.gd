extends Node

const VALID_CHARACTERS := [&"michu", &"juan"]

var selected_character: StringName = &"michu"


func select_character(character_id: String) -> void:
	var requested := StringName(character_id)
	if requested not in VALID_CHARACTERS:
		push_error("Personaje desconocido: %s" % character_id)
		return
	selected_character = requested
