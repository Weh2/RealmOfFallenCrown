extends Resource
class_name Inv

signal inventory_updated
signal hotbar_updated
signal equipment_updated

@export var slots: Array[InvSlot] = []
@export var hotbar_slots: Array[InvSlot] = []
@export var equipment_slots: Dictionary = {
	"main_hand": InvSlot.new(),
	"off_hand": InvSlot.new(),
	"body": InvSlot.new(),
	"head": InvSlot.new(),
	"hands": InvSlot.new(),
	"legs": InvSlot.new(),
	"ring_1": InvSlot.new(),
	"ring_2": InvSlot.new(),
	"amulet": InvSlot.new()
}

func _init():
	print("Инициализация Inv")
	print("Слоты экипировки: ", equipment_slots.keys())
	for slot in equipment_slots:
		print(slot, ": ", equipment_slots[slot].item)
	slots.resize(24)
	for i in slots.size():
		slots[i] = InvSlot.new()
	
	hotbar_slots.resize(2)
	for i in hotbar_slots.size():
		hotbar_slots[i] = InvSlot.new()


func _can_equip(item: InvItem, slot_type: String) -> bool:
	if item == null:
		print("Ошибка: предмет не существует")
		return false
	
	print("Проверка экипировки:", item.name, "| Тип:", item.item_type, "| Слот:", slot_type)
	
	var result = false
	match slot_type:
		"main_hand":
			result = (item.item_type == InvItem.ItemType.WEAPON)
		"off_hand":
			result = (item.item_type in [InvItem.ItemType.WEAPON, InvItem.ItemType.SHIELD])
		"body":
			result = (item.item_type == InvItem.ItemType.BODY)
		"head":
			result = (item.item_type == InvItem.ItemType.HEAD)
		"hands":
			result = (item.item_type == InvItem.ItemType.HANDS)
		"legs":
			result = (item.item_type == InvItem.ItemType.LEGS)
		"ring_1", "ring_2":
			result = (item.item_type == InvItem.ItemType.RING)
		"amulet":
			result = (item.item_type == InvItem.ItemType.AMULET)
		_:
			print("Неизвестный тип слота:", slot_type)
	
	print("Результат проверки:", result)
	return result

func equip_item(item: InvItem, slot_type: String) -> bool:
	print("=== Начало экипировки ===")
	print("Предмет:", item.name, "| Тип:", item.item_type)
	print("Целевой слот:", slot_type)
	
	if not _can_equip(item, slot_type):
		print("Предмет не может быть экипирован в этот слот")
		return false
	
	var slot = equipment_slots[slot_type]
	if slot == null:
		push_error("Слот не инициализирован!")
		return false
	
	# Временное сохранение текущего предмета
	var previous_item = slot.item
	print("Текущий предмет в слоте:", previous_item.name if previous_item else "пусто")
	
	# Экипировка нового предмета
	slot.item = item
	slot.amount = 1
	print("Предмет временно установлен в слот")
	
	# Возврат предыдущего предмета
	if previous_item:
		print("Попытка вернуть в инвентарь:", previous_item.name)
		if not insert(previous_item):
			# Откат изменений при ошибке
			slot.item = previous_item
			print("Ошибка: не удалось вернуть предмет в инвентарь")
			return false
	
	print("Экипировка успешно завершена")
	equipment_updated.emit()
	return true


func insert(item: InvItem):
	# Сначала пробуем добавить в хотбар (только для зелий)
	if item.name in ["Health Potion", "Stamina Potion"]:
		# Ищем такой же предмет в хотбаре
		for slot in hotbar_slots:
			if slot.item == item and slot.amount < item.max_stack:
				slot.amount += 1
				hotbar_updated.emit()
				return
		
		# Ищем пустой слот в хотбаре
		for slot in hotbar_slots:
			if slot.item == null:
				slot.item = item
				slot.amount = 1
				hotbar_updated.emit()
				return
	
	# Затем в основной инвентарь
	var itemslots = slots.filter(func(s): return s.item == item and s.amount < item.max_stack)
	if !itemslots.is_empty():
		itemslots[0].amount += 1
	else:
		var emptyslots = slots.filter(func(s): return s.item == null)
		if !emptyslots.is_empty():
			emptyslots[0].item = item
			emptyslots[0].amount = 1
	inventory_updated.emit()  # Заменили update на inventory_updated

func use_hotbar_slot(index: int, player: Node):
	if index < 0 or index >= hotbar_slots.size():
		return
	
	var slot = hotbar_slots[index]
	if slot.item == null:
		return
	
	match slot.item.name:
		"Health Potion":
			player.heal(30)
		"Stamina Potion":
			player.current_stamina = min(player.current_stamina + 50, player.max_stamina)
		_:
			return
	
	slot.amount -= 1
	if slot.amount <= 0:
		slot.item = null
	hotbar_updated.emit()
