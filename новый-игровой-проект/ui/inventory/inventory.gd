extends Resource
class_name Inv

signal inventory_updated
signal hotbar_updated
signal equipment_updated

@export var slots: Array[InvSlot] = []
@export var hotbar_slots: Array[InvSlot] = []
@export var equipment_slots: Dictionary = {}

func _init():
	# Инициализация с явным созданием новых объектов
	slots.resize(24)
	for i in slots.size():
		slots[i] = InvSlot.new()
	
	hotbar_slots.resize(2)
	for i in hotbar_slots.size():
		hotbar_slots[i] = InvSlot.new()
	
	# Пересоздаем всю структуру слотов
	equipment_slots = {
		"main_hand": _create_slot_with_copy(equipment_slots.get("main_hand")),
		"off_hand": _create_slot_with_copy(equipment_slots.get("off_hand")),
		"body": _create_slot_with_copy(equipment_slots.get("body")),
		"head": _create_slot_with_copy(equipment_slots.get("head")),
		"hands": _create_slot_with_copy(equipment_slots.get("hands")),
		"legs": _create_slot_with_copy(equipment_slots.get("legs")),
		"ring_1": _create_slot_with_copy(equipment_slots.get("ring_1")),
		"ring_2": _create_slot_with_copy(equipment_slots.get("ring_2")),
		"amulet": _create_slot_with_copy(equipment_slots.get("amulet"))
	}

func _create_slot_with_copy(existing_slot: InvSlot) -> InvSlot:
	var new_slot = InvSlot.new()
	if existing_slot and existing_slot.item:
		new_slot.item = existing_slot.item
		new_slot.amount = existing_slot.amount
	return new_slot

func equip_item(item: InvItem, slot_type: String) -> bool:
	if not _can_equip(item, slot_type):
		return false
		
	var slot = equipment_slots.get(slot_type)
	if not slot:
		push_error("Invalid slot type: ", slot_type)
		return false
	
	# Полное копирование предмета
	var new_item = item.duplicate()
	
	# Сохраняем предыдущий предмет
	var previous_item = slot.item
	
	# Полная замена содержимого слота
	var new_slot = InvSlot.new()
	new_slot.item = new_item
	new_slot.amount = 1
	equipment_slots[slot_type] = new_slot
	
	# Возвращаем предыдущий предмет
	if previous_item:
		if not insert(previous_item):
			# Откат при ошибке
			equipment_slots[slot_type] = previous_item
			return false
	
	equipment_updated.emit()
	return true

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
