class_name CombatDeck
extends RefCounted

const MAX_ENERGY := 3

var draw_pile: Array[StringName] = []
var hand: Array[StringName] = []
var discard_pile: Array[StringName] = []
var exhausted_pile: Array[StringName] = []
var energy := MAX_ENERGY


func setup(card_ids: Array[StringName]) -> void:
	draw_pile = card_ids.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()
	exhausted_pile.clear()
	energy = MAX_ENERGY


func begin_turn() -> void:
	energy = MAX_ENERGY


func can_pay(cost: int) -> bool:
	return cost >= 0 and energy >= cost


func pay(cost: int) -> bool:
	if not can_pay(cost):
		return false
	energy -= cost
	return true


func draw(amount: int) -> Array[StringName]:
	var drawn: Array[StringName] = []
	for draw_index in amount:
		if draw_pile.is_empty():
			_reshuffle_discards()
		if draw_pile.is_empty():
			break
		var card_id: StringName = draw_pile.pop_back()
		hand.append(card_id)
		drawn.append(card_id)
	return drawn


func discard(card_id: StringName) -> bool:
	var index := hand.find(card_id)
	if index < 0:
		return false
	hand.remove_at(index)
	discard_pile.append(card_id)
	return true


func exhaust(card_id: StringName) -> bool:
	var index := hand.find(card_id)
	if index < 0:
		return false
	hand.remove_at(index)
	exhausted_pile.append(card_id)
	return true


func discard_hand() -> void:
	discard_pile.append_array(hand)
	hand.clear()


func _reshuffle_discards() -> void:
	if discard_pile.is_empty():
		return
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
