extends Node  
class_name LootComponent  

# Настройки лута в инспекторе:  
@export var possible_loot: Array[Dictionary] = [  
	{"id": "health_potion", "chance": 1.0, "min": 1, "max": 1}  # 100% шанс
]

# Сигнал для передачи лута в UI  
signal loot_generated(items: Array)  

func generate_loot() -> Array[Dictionary]:  
	var dropped_items = []  
	for item in possible_loot:  
		if randf() <= item["chance"]:  
			dropped_items.append({  
				"id": item["id"],  
				"amount": randi_range(item["min"], item["max"])  
			})  
	loot_generated.emit(dropped_items)  # Отправляем лут в UI  
	return dropped_items  
