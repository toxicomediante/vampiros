class_name RewardGenerator
extends RefCounted


static func generate(character_id: StringName) -> Array[StringName]:
	var character_cards := CardCatalog.character_reward_pool(character_id)
	# El Oculto está definido mecánicamente, pero su arte definitivo todavía no
	# forma parte de este corte publicado.
	character_cards.erase(&"el_oculto")
	var neutral_cards: Array[StringName] = [
		&"katana_escondida",
		&"el_camino_te_camela",
		&"la_variz",
	]
	# LA PROLE queda fuera del vertical slice hasta definir las maldiciones.
	character_cards.shuffle()
	neutral_cards.shuffle()

	var reward: Array[StringName] = []
	reward.append_array(character_cards.slice(0, mini(2, character_cards.size())))
	if not neutral_cards.is_empty():
		reward.append(neutral_cards[0])
	reward.shuffle()
	return reward
