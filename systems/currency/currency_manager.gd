class_name CurrencyManager
extends Node

signal currency_changed(old_amount: int, new_amount: int, source_type: String, source_id: String)

var data := CurrencyData.new()

func setup(saved_data: Dictionary = {}) -> void:
	data = CurrencyData.from_dict(saved_data) if not saved_data.is_empty() else CurrencyData.new()

func get_coin_amount() -> int: return data.amount

func add_coins(amount: int, source_type: String, source_id: String) -> bool:
	if amount <= 0: return false
	var old_amount := data.amount; data.amount += amount; data.total_earned += amount
	currency_changed.emit(old_amount, data.amount, source_type, source_id); return true

func can_spend_coins(amount: int) -> bool: return amount >= 0 and data.amount >= amount

func spend_coins(amount: int, source_type: String, source_id: String) -> bool:
	if amount <= 0 or not can_spend_coins(amount): return false
	var old_amount := data.amount; data.amount -= amount; data.total_spent += amount
	currency_changed.emit(old_amount, data.amount, source_type, source_id); return true

func rollback_spend(amount: int, source_type: String, source_id: String) -> bool:
	if amount <= 0 or data.total_spent < amount: return false
	var old_amount := data.amount; data.amount += amount; data.total_spent -= amount
	currency_changed.emit(old_amount, data.amount, source_type, source_id); return true
