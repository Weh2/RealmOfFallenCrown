extends Node
class_name InventorySystem

signal inventory_updated

@export var slots_count: int = 16
var items: Array = []

func _ready():
	items.resize(slots_count)
	items.fill(null)

# Добавляет предмет в первый свободный слот
func add_item(item: ItemData) -> bool:
	# Попытка добавить в существующий стек
	if item.max_stack > 1:
		for i in items.size():
			if items[i] and items[i].name == item.name and items[i].quantity < items[i].max_stack:
				items[i].quantity += 1
				inventory_updated.emit()
				return true
	
	# Добавление в пустой слот
	for i in items.size():
		if items[i] == null:
			items[i] = item.duplicate()  # Важно: создаем копию!
			items[i].quantity = 1
			inventory_updated.emit()
			return true
	return false

# Использование предмета
func use_item(slot_index: int, user: Node) -> bool:
	if slot_index < 0 or slot_index >= items.size(): return false
	
	var item = items[slot_index]
	if item and item.use(user):
		if item.consumable:
			item.quantity -= 1
			if item.quantity <= 0:
				items[slot_index] = null
		inventory_updated.emit()
		return true
	return false
