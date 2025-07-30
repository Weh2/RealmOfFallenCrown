extends Node
class_name LootComponent

@export var possible_loot: Array[Dictionary] = [
	{"item": preload("res://ui/inventory/items/HealthPotion.tres"), "chance": 1, "min": 1, "max": 3},
	
]

var generated_loot: Array = []
var can_be_looted := false

func generate_loot() -> Array:
	generated_loot.clear()
	for loot_data in possible_loot:
		if randf() <= loot_data["chance"]:
			generated_loot.append({
				"item": loot_data["item"],
				"quantity": randi_range(loot_data["min"], loot_data["max"])
			})
	can_be_looted = !generated_loot.is_empty()
	return generated_loot

func get_loot() -> Array:
	return generated_loot

func remove_item(index: int) -> bool:
	if index < 0 or index >= generated_loot.size():
		return false
	generated_loot.remove_at(index)
	can_be_looted = !generated_loot.is_empty()
	return true
