extends Node
class_name InventorySystem

signal inventory_updated

@export var slots_count: int = 16  # Количество слотов
var items: Array = []              # Массив предметов

func _ready():
	items.resize(slots_count)
	items.fill(null)  # Заполняем пустыми слотами

# Добавление предмета
func add_item(item_data: ItemData) -> bool:
	for i in range(items.size()):
		if items[i] == null:
			items[i] = item_data
			inventory_updated.emit()
			return true
	return false  # Инвентарь полон

# Удаление предмета
func remove_item(slot_index: int) -> ItemData:
	if slot_index < 0 or slot_index >= items.size():
		return null
	
	var item = items[slot_index]
	items[slot_index] = null
	inventory_updated.emit()
	return item

# Использование предмета
func use_item(slot_index: int, user: Node) -> bool:
	var item = items[slot_index]
	if item and item.has_method("use"):
		return item.use(user)
	return false
