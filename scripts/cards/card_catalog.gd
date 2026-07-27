class_name CardCatalog
extends RefCounted

enum Owner {
	MICHU,
	JUAN,
	NEUTRAL,
}

enum Target {
	SELF,
	ONE_ENEMY,
	ALL_ENEMIES,
	NONE,
}

const STARTING_DECKS := {
	&"michu": {
		&"mojadita": 5,
		&"michu_guardia": 5,
		&"bocanegra": 1,
	},
	&"juan": {
		&"guantazo": 5,
		&"juan_guardia": 5,
		&"tiriviento": 1,
	},
}

const CARDS := {
	&"mojadita": {
		"name": "MOJADITA",
		"owner": Owner.MICHU,
		"cost": 1,
		"target": Target.ONE_ENEMY,
		"effects": [{"type": &"damage", "amount": 6}],
	},
	&"michu_guardia": {
		"name": "GUARDIA",
		"owner": Owner.MICHU,
		"cost": 1,
		"target": Target.SELF,
		"effects": [{"type": &"block", "amount": 5}],
	},
	&"juan_guardia": {
		"name": "GUARDIA",
		"owner": Owner.JUAN,
		"cost": 1,
		"target": Target.SELF,
		"effects": [{"type": &"block", "amount": 5}],
	},
	&"bocanegra": {
		"name": "BOCANEGRA",
		"owner": Owner.MICHU,
		"cost": 2,
		"target": Target.ONE_ENEMY,
		"effects": [{"type": &"poison", "amount": 3}],
	},
	&"petardo": {
		"name": "PETARDO",
		"owner": Owner.MICHU,
		"cost": 1,
		"target": Target.ALL_ENEMIES,
		"effects": [{"type": &"damage", "amount": 2}],
	},
	&"trilita": {
		"name": "TRILITA",
		"owner": Owner.MICHU,
		"cost": 2,
		"target": Target.ALL_ENEMIES,
		"effects": [
			{"type": &"damage", "amount": 2},
			{"type": &"poison", "amount": 2},
		],
	},
	&"choriza_de_jabali": {
		"name": "CHORIZA DE JABALÍ",
		"owner": Owner.MICHU,
		"cost": 3,
		"target": Target.ONE_ENEMY,
		"effects": [{"type": &"double_poison"}],
	},
	&"guantazo": {
		"name": "GUANTAZO",
		"owner": Owner.JUAN,
		"cost": 1,
		"target": Target.ONE_ENEMY,
		"effects": [{"type": &"damage", "amount": 6}],
	},
	&"tiriviento": {
		"name": "TIRIVIENTO, HOMBRE",
		"owner": Owner.JUAN,
		"cost": 2,
		"target": Target.ONE_ENEMY,
		"effects": [
			{"type": &"damage", "amount": 8},
			{"type": &"vulnerable", "amount": 2},
		],
	},
	&"fresquita": {
		"name": "FRESQUITA",
		"owner": Owner.JUAN,
		"cost": 2,
		"target": Target.SELF,
		"effects": [{"type": &"heal", "amount": 6}],
	},
	&"siempre_sale_bien": {
		"name": "SIEMPRE SALE BIEN",
		"owner": Owner.JUAN,
		"cost": 2,
		"target": Target.SELF,
		"effects": [{"type": &"regeneration", "amount": 3}],
	},
	&"el_oculto": {
		"name": "EL OCULTO",
		"owner": Owner.JUAN,
		"cost": 2,
		"target": Target.SELF,
		"effects": [{"type": &"autodefense", "amount": 4}],
	},
	&"katana_escondida": {
		"name": "KATANA ESCONDIDA",
		"owner": Owner.NEUTRAL,
		"cost": 1,
		"target": Target.SELF,
		"effects": [{"type": &"strength", "amount": 1}],
	},
	&"circulo_negro": {
		"name": "CÍRCULO NEGRO",
		"owner": Owner.NEUTRAL,
		"cost": 1,
		"target": Target.ONE_ENEMY,
		"effects": [{"type": &"stun", "amount": 1}],
	},
	&"el_camino_te_camela": {
		"name": "EL CAMINO TE CAMELA",
		"owner": Owner.NEUTRAL,
		"cost": 2,
		"target": Target.SELF,
		"effects": [{"type": &"regeneration", "amount": 3}],
	},
	&"la_variz": {
		"name": "LA VARIZ",
		"owner": Owner.NEUTRAL,
		"cost": 1,
		"target": Target.SELF,
		"effects": [{"type": &"self_damage", "amount": 4, "blockable": true}],
	},
	&"pollo_con_pollo": {
		"name": "POLLO CON POLLO",
		"owner": Owner.NEUTRAL,
		"cost": 1,
		"target": Target.SELF,
		"effects": [
			{"type": &"poison", "amount": 2},
			{"type": &"exhaust"},
		],
	},
	&"la_slam": {
		"name": "LA SLAM",
		"owner": Owner.NEUTRAL,
		"cost": 0,
		"target": Target.NONE,
		"effects": [
			{"type": &"gold", "amount": 20},
			{"type": &"exhaust"},
		],
	},
	&"la_prole": {
		"name": "LA PROLE",
		"owner": Owner.NEUTRAL,
		"cost": 3,
		"target": Target.NONE,
		"effects": [{"type": &"remove_curse_from_deck", "amount": 1}],
	},
	&"la_revancha": {
		"name": "LA REVANCHA",
		"owner": Owner.NEUTRAL,
		"cost": 1,
		"target": Target.NONE,
		"effects": [{"type": &"discover", "choices": 3, "temporary_cost": 0}],
	},
	&"ahora_la_vi": {
		"name": "¡AHORA LA VI!",
		"owner": Owner.NEUTRAL,
		"cost": 3,
		"target": Target.NONE,
		"effects": [{"type": &"set_hand_cost", "amount": 0, "duration": &"turn"}],
	},
	&"evangelio": {
		"name": "EVANGELIO",
		"owner": Owner.NEUTRAL,
		"cost": 2,
		"target": Target.NONE,
		"effects": [{"type": &"draw", "amount": 2, "drawn_cost": 0}],
	},
	&"tuerca": {
		"name": "TUERCA",
		"owner": Owner.NEUTRAL,
		"cost": 1,
		"target": Target.NONE,
		"effects": [{"type": &"remove_self_from_deck"}],
	},
	&"licor_k": {
		"name": "LICOR-K",
		"owner": Owner.NEUTRAL,
		"cost": 2,
		"target": Target.SELF,
		"effects": [{"type": &"strength", "amount": 1}],
	},
}


static func build_starting_deck(character_id: StringName) -> Array[StringName]:
	var deck: Array[StringName] = []
	var recipe: Dictionary = STARTING_DECKS.get(character_id, {})
	for card_id: StringName in recipe:
		for copy_index in int(recipe[card_id]):
			deck.append(card_id)
	return deck


static func character_reward_pool(character_id: StringName) -> Array[StringName]:
	var expected_owner := Owner.MICHU if character_id == &"michu" else Owner.JUAN
	return _cards_for_owner(expected_owner)


static func neutral_reward_pool() -> Array[StringName]:
	return _cards_for_owner(Owner.NEUTRAL)


static func _cards_for_owner(owner: Owner) -> Array[StringName]:
	var result: Array[StringName] = []
	for card_id: StringName in CARDS:
		if CARDS[card_id]["owner"] == owner:
			result.append(card_id)
	return result
