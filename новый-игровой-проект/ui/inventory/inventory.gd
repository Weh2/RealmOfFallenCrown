extends Resource
class_name Inv

signal inventory_updated
signal hotbar_updated
signal equipment_updated  # Новый сигнал

# Основной инвентарь
@export var slots: Array[InvSlot] = []
# Хотбар
@export var hotbar_slots: Array[InvSlot] = []
# Слоты экипировки
@export var equipment_slots: Dictionary = {
	"main_hand": null,
	"off_hand": null,
	"body": null,
	"head": null,
	"hands": null,
	"legs": null,
	"ring_1": null,
	"ring_2": null,
	"amulet": null
}

func _init():
	# Инициализация обычных слотов (24 слота)
	slots.resize(24)
	for i in 24:
		slots[i] = InvSlot.new()
	
	# Инициализация хотбара (2 слота)
	hotbar_slots.resize(2)
	for i in 2:
		hotbar_slots[i] = InvSlot.new()
	
	# Инициализация слотов экипировки
	for slot in equipment_slots.keys():
		equipment_slots[slot] = InvSlot.new()

# Метод для экипировки предмета
func equip_item(item: InvItem, slot_type: String):
	var slot = equipment_slots.get(slot_type)
	if slot and _can_equip(item, slot_type):
		# Возвращаем текущий экипированный предмет в инвентарь
		if slot.item:
			add_item(slot.item)
		
		slot.item = item
		slot.amount = 1
		equipment_updated.emit()
		return true
	return false

# Проверка можно ли экипировать предмет в слот
func _can_equip(item: InvItem, slot_type: String) -> bool:
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
