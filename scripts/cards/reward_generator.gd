class_name RewardGenerator
extends RefCounted

const EXCLUDED_REWARD_CARDS: Array[StringName] = [
	&"la_variz",
	&"la_prole",
	&"tuerca",
]
const NEUTRAL_REWARD_CARDS: Array[StringName] = [
	&"katana_escondida",
	&"circulo_negro",
	&"el_camino_te_camela",
	&"pollo_con_pollo",
	&"la_slam",
	&"la_revancha",
	&"ahora_la_vi",
	&"evangelio",
	&"licor_k",
]


static func generate(character_id: StringName) -> Array[StringName]:
	var character_cards := character_candidates(character_id)
	var neutral_cards := neutral_candidates()
	character_cards.shuffle()
	neutral_cards.shuffle()

	var reward: Array[StringName] = []
	reward.append_array(character_cards.slice(0, mini(2, character_cards.size())))
	if not neutral_cards.is_empty():
		reward.append(neutral_cards[0])
	reward.shuffle()
	return reward


static func character_candidates(character_id: StringName) -> Array[StringName]:
	var result := CardCatalog.character_reward_pool(character_id)
	var starting_recipe: Dictionary = CardCatalog.STARTING_DECKS.get(
		character_id, {}
	)
	for starter_card: StringName in starting_recipe:
		result.erase(starter_card)
	for excluded_card: StringName in EXCLUDED_REWARD_CARDS:
		result.erase(excluded_card)
	return result


static func neutral_candidates() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(NEUTRAL_REWARD_CARDS)
	return result


static func discover(character_id: StringName, amount := 3) -> Array[StringName]:
	var pool := character_candidates(character_id)
	pool.append_array(neutral_candidates())
	# Evita cadenas recursivas de ventanas de elección.
	pool.erase(&"la_revancha")
	pool.shuffle()
	var choices: Array[StringName] = []
	choices.assign(pool.slice(0, mini(amount, pool.size())))
	return choices
