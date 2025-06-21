extends CanvasLayer

@onready var slots_container = $SlotsContainer
@onready var inventory_system: InventorySystem = get_node("/root/Level/Player/InventorySystem")  # Полный путь!

func _ready():
	# Проверка на случай отсутствия системы инвентаря
	if not inventory_system:
		push_error("InventorySystem not found!")
		return
	
	# Создание слотов
	for i in range(inventory_system.slots_count):
		var slot = TextureRect.new()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slots_container.add_child(slot)
	
	# Подключение сигнала
	inventory_system.inventory_updated.connect(update_ui)
	update_ui()  # Первоначальное обновление

func update_ui():
	for i in range(inventory_system.items.size()):
		var item = inventory_system.items[i]
		var slot = slots_container.get_child(i)
		slot.texture = item.icon if item else null
