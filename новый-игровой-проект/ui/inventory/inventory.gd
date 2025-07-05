extends Resource
class_name Inv

# Все сигналы должны быть объявлены в начале класса
signal inventory_updated
signal equipment_updated  # Этот сигнал был пропущен!
signal hotbar_updated

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
	# Инициализация слотов
	for i in range(24):
		slots.append(InvSlot.new())

	
	# Инициализация хотбара (2 слота)
	hotbar_slots.resize(2)
	for i in range(hotbar_slots.size()):
		hotbar_slots[i] = InvSlot.new()

func insert(item: InvItem) -> bool:
	# Сначала пробуем добавить в хотбар (только для зелий)
	if item.item_type == InvItem.ItemType.CONSUMABLE:
		for slot in hotbar_slots:
			if slot.item == item and slot.amount < item.max_stack:
				slot.amount += 1
				emit_signal("hotbar_updated")
				return true
			
		for slot in hotbar_slots:
			if slot.item == null:
				slot.item = item
				slot.amount = 1
				emit_signal("hotbar_updated")
				return true
	
	# Затем в основной инвентарь
	for slot in slots:
		if slot.item == item and slot.amount < item.max_stack:
			slot.amount += 1
			emit_signal("inventory_updated")
			return true
			
	for slot in slots:
		if slot.item == null:
			slot.item = item
			slot.amount = 1
			emit_signal("inventory_updated")
			return true
	
	return false

func equip(item: InvItem, slot_type: String) -> bool:
	if !equipment_slots.has(slot_type):
		return false
		
	var slot = equipment_slots[slot_type]
	var prev_item = slot.item
	slot.item = item
	
	if prev_item:
		if !insert(prev_item):
			slot.item = prev_item
			return false
	
	emit_signal("equipment_updated")  # Важно: исправленный вызов
	return true
func _can_equip(item: InvItem, slot_type: String) -> bool:
	if item == null:
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
	emit_signal("hotbar_updated")
