class_name RewardGenerator
extends RefCounted

const EXCLUDED_NEUTRAL_REWARDS := [
	&"la_variz",
	&"la_prole",
	&"tuerca",
]

# Estas son las neutrales que hoy tienen efecto y textura final dentro de
# assets/. Las restantes se incorporarán al recibir sus imágenes con alfa.
const IMPLEMENTED_NEUTRAL_REWARDS := [
	&"katana_escondida",
	&"el_camino_te_camela",
]


static func generate(character_id: StringName) -> Array[StringName]:
	var character_cards := CardCatalog.character_reward_pool(character_id)
	var starting_recipe: Dictionary = CardCatalog.STARTING_DECKS.get(
		character_id,
		{}
	)
	for starting_card_id: StringName in starting_recipe:
		character_cards.erase(starting_card_id)
	character_cards.shuffle()

	var neutral_cards: Array[StringName] = (
		IMPLEMENTED_NEUTRAL_REWARDS.duplicate()
	)
	for excluded_card_id: StringName in EXCLUDED_NEUTRAL_REWARDS:
		neutral_cards.erase(excluded_card_id)
	neutral_cards.shuffle()

	var reward: Array[StringName] = []
	reward.append_array(
		character_cards.slice(0, mini(2, character_cards.size()))
	)
	if not neutral_cards.is_empty():
		reward.append(neutral_cards[0])
	reward.shuffle()
	return reward
