extends Resource
class_name Inv

signal update
signal hotbar_updated

@export var slots: Array[InvSlot]
@export var hotbar_slots: Array[InvSlot] = []
@export var hotbar_size: int = 2  # Меняем на 2 слота

func _init():
	slots = []
	hotbar_slots.resize(hotbar_size)
	for i in hotbar_size:
		hotbar_slots[i] = InvSlot.new()

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
