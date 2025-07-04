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
	slots.resize(24)
	for i in slots.size():
		slots[i] = InvSlot.new()
	
	hotbar_slots.resize(2)
	for i in hotbar_slots.size():
		hotbar_slots[i] = InvSlot.new()

func equip_item(item: InvItem, slot_type: String) -> bool:
	if not _can_equip(item, slot_type):
		print("Предмет не может быть экипирован")
		return false
	
	var slot = equipment_slots.get(slot_type)
	if not slot:
		push_error("Слот не найден: ", slot_type)
		return false
	
	# Возвращаем текущий предмет в инвентарь
	if slot.item:
		if not insert(slot.item):
			push_error("Не удалось вернуть предмет в инвентарь")
			return false
	
	# Экипируем новый предмет
	slot.item = item
	slot.amount = 1
	equipment_updated.emit()
	return true

func _can_equip(item: InvItem, slot_type: String) -> bool:
	if not item:
		return false
	
	match slot_type:
		"main_hand":
			return item.item_type == InvItem.ItemType.WEAPON
		"off_hand":
			return item.item_type in [InvItem.ItemType.WEAPON, InvItem.ItemType.SHIELD]
		"body":
			return item.item_type == InvItem.ItemType.BODY
		"head":
			return item.item_type == InvItem.ItemType.HEAD
		"hands":
			return item.item_type == InvItem.ItemType.HANDS
		"legs":
			return item.item_type == InvItem.ItemType.LEGS
		"ring_1", "ring_2":
			return item.item_type == InvItem.ItemType.RING
		"amulet":
			return item.item_type == InvItem.ItemType.AMULET
		_:

			return false

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
