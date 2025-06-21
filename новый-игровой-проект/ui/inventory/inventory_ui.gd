extends CanvasLayer

@onready var grid = $Panel/GridContainer
@onready var inventory_system = $"../InventorySystem"

func _ready():
	hide()
	inventory_system.inventory_updated.connect(update_ui)
	
	# Создаем слоты
	for i in range(inventory_system.slots_count):
		var slot = create_slot()
		grid.add_child(slot)
	update_ui()

func create_slot() -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(72, 72)
	
	# Стиль слота
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	panel.add_theme_stylebox_override("panel", style)
	
	# Иконка предмета
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.size = Vector2(64, 64)
	panel.add_child(icon)
	
	# Текст количества
	var label = Label.new()
	label.name = "Quantity"
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(label)
	
	return panel

func update_ui():
	# Проверяем, что grid и inventory_system существуют
	if not is_instance_valid(grid) or not is_instance_valid(inventory_system):
		push_error("Inventory UI not properly initialized!")
		return
	
	# Убедимся, что количество слотов соответствует количеству предметов
	var slots_to_process = min(inventory_system.items.size(), grid.get_child_count())
	
	for i in range(slots_to_process):
		var item = inventory_system.items[i]
		var slot = grid.get_child(i)
		
		# Безопасное получение иконки
		var icon: TextureRect = null
		if slot.has_node("Icon"):
			icon = slot.get_node("Icon")
		else:
			push_error("Slot ", i, " is missing Icon node!")
			continue
			
		# Безопасное получение лейбла количества
		var label: Label = null
		if slot.has_node("Quantity"):
			label = slot.get_node("Quantity")
		else:
			push_error("Slot ", i, " is missing Quantity label!")
			continue
			
		# Обновляем содержимое слота
		if item and is_instance_valid(item):
			# Устанавливаем иконку
			if item.icon:
				icon.texture = item.icon
			else:
				icon.texture = null
				push_warning("Item ", item.name, " has no icon assigned!")
			
			# Устанавливаем количество
			if item.max_stack > 1:
				label.text = str(item.quantity)
			else:
				label.text = ""
		else:
			# Очищаем слот
			icon.texture = null
			label.text = ""
	
	# Отладочная информация
	print("Inventory updated. Slots: ", slots_to_process, 
		  " Items: ", inventory_system.items.size())

func toggle_visibility():
	visible = !visible
	get_tree().paused = visible  # Пауза только при открытии
	
	# Добавьте отладочный вывод
	print("Инвентарь: ", "открыт" if visible else "закрыт")
