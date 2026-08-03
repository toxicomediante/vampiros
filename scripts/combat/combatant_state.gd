class_name CombatantState
extends RefCounted

var max_hp: int
var hp: int
var block := 0
var poison := 0
var regeneration := 0
var vulnerable := 0
var strength := 0
var autodefense := 0


func _init(initial_max_hp: int) -> void:
	max_hp = initial_max_hp
	hp = initial_max_hp


func begin_turn() -> void:
	# El bloqueo ordinario nunca pasa de un turno al siguiente.
	block = 0
	if autodefense > 0:
		block += autodefense
		autodefense -= 1


func receive_attack(base_damage: int, attacker_strength := 0) -> int:
	var scaled_damage := base_damage + attacker_strength
	if vulnerable > 0:
		scaled_damage = ceili(scaled_damage * 1.5)
	return receive_blockable_damage(scaled_damage)


func receive_blockable_damage(amount: int) -> int:
	var absorbed := mini(block, amount)
	block -= absorbed
	var hp_damage := amount - absorbed
	hp = maxi(0, hp - hp_damage)
	return hp_damage


func heal(amount: int) -> int:
	var previous_hp := hp
	hp = mini(max_hp, hp + amount)
	return hp - previous_hp


func apply_end_of_turn_statuses() -> Dictionary:
	var result := {
		"poison_damage": 0,
		"regenerated_hp": 0,
	}
	if poison > 0:
		var previous_hp := hp
		hp = maxi(0, hp - poison)
		result["poison_damage"] = previous_hp - hp
		poison -= 1
		if hp <= 0:
			return result
	if regeneration > 0:
		result["regenerated_hp"] = heal(regeneration)
		regeneration -= 1
	return result


func finish_turn() -> void:
	if vulnerable > 0:
		vulnerable -= 1
