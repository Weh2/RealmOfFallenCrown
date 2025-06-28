extends Resource
class_name Inv

signal update
signal hotbar_updated  # Новый сигнал

@export var slots: Array[InvSlot]
@export var hotbar_slots: Array[InvSlot] = []  # Добавляем хотбар
@export var hotbar_size: int = 6  # Количество слотов хотбара

func _init():
	# Инициализация обычных слотов
	slots = []
	
	# Инициализация хотбара
	hotbar_slots.resize(hotbar_size)
	for i in hotbar_size:
		hotbar_slots[i] = InvSlot.new()

# Обновлённый метод insert
func insert(item: InvItem):
	# Сначала пробуем добавить в хотбар
	for slot in hotbar_slots:
		if slot.item == item and item.stackable:
			slot.amount += 1
			hotbar_updated.emit()
			return
	
	# Затем в основной инвентарь
	var itemslots = slots.filter(func(s): return s.item == item)
	if !itemslots.is_empty():
		itemslots[0].amount += 1
	else:
		var emptyslots = slots.filter(func(s): return s.item == null)
		if !emptyslots.is_empty():
			emptyslots[0].item = item
			emptyslots[0].amount = 1
	update.emit()

# Новый метод для хотбара
func set_hotbar_slot(index: int, item: InvItem, amount: int = 1):
	if index < hotbar_slots.size():
		hotbar_slots[index].item = item
		hotbar_slots[index].amount = amount
		hotbar_updated.emit()
