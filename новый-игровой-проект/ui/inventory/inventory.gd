extends Resource
class_name Inv

signal update
signal hotbar_updated
signal equipment_updated # Новый сигнал для обновления экипировки

@export var slots: Array[InvSlot] # Обычные слоты инвентаря
@export var hotbar_slots: Array[InvSlot] = [] # Слоты хотбара
@export var equipment_slots: Array[InvSlot] = [] # Новые слоты для экипировки
@export var hotbar_size: int = 2

func _init():
	slots = []
	
	# Инициализация хотбара
	hotbar_slots = []
	hotbar_slots.resize(hotbar_size)
	for i in hotbar_size:
		hotbar_slots[i] = InvSlot.new()
	
	# Инициализация слотов экипировки
	equipment_slots = []
	equipment_slots.resize(8)
	for i in 8:
		equipment_slots[i] = InvSlot.new()  # Гарантируем, что каждый слот существует
		

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
	update.emit()

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


# Экипировка предмета
func equip_item(slot_index: int, item: InvItem) -> bool:
	if slot_index < 0 or slot_index >= equipment_slots.size():
		return false
	
	# Проверяем тип предмета
	if item.item_type != slot_index:
		print("Нельзя экипировать ", item.name, " в этот слот")
		return false
	
	# Если в слоте уже есть предмет - сначала снимаем его
	var unequipped_item = unequip_item(slot_index)
	
	# Находим слот с этим предметом в инвентаре
	var item_slot_index = -1
	for i in range(slots.size()):
		if slots[i].item == item:
			item_slot_index = i
			break
	
	if item_slot_index != -1:
		# Переносим предмет в слот экипировки
		equipment_slots[slot_index].item = slots[item_slot_index].item
		equipment_slots[slot_index].amount = 1
		slots[item_slot_index].item = null  # Удаляем из инвентаря
		
		# Обновляем статы
		equipment_updated.emit()
		update.emit()
		return true
	print("Предмет не найден в инвентаре")
	return false
# Снятие предмета

func unequip_item(slot_index: int) -> InvItem:
	if slot_index < 0 or slot_index >= equipment_slots.size():
		return null
	
	var item = equipment_slots[slot_index].item
	if not item:
		return null
	
	# Создаем временную копию предмета
	var unequipped_item = item
	
	# Очищаем слот экипировки
	equipment_slots[slot_index].item = null
	equipment_slots[slot_index].amount = 0
	
	print("DEBUG: Предмет снят из слота", slot_index)  # Должно появиться в консоли
	
	# Форсируем обновление
	equipment_updated.emit()
	update.emit()
	
	# Пытаемся вернуть предмет в инвентарь
	if insert(unequipped_item):
		return unequipped_item
	else:
		print("В инвентаре нет места!")
		return null

# Получение бонусов от всей экипировки
func get_equipment_bonuses() -> Dictionary:
	var bonuses = {
		"attack": 0,
		"defense": 0,
		"health": 0,
		"stamina": 0
	}
	
	for slot in equipment_slots:
		if slot.item:
			for stat in bonuses:
				bonuses[stat] += slot.item.stats.get(stat, 0)
	
	return bonuses
