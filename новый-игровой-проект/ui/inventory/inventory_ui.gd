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
	for i in range(inventory_system.items.size()):
		var item = inventory_system.items[i]
		var slot = grid.get_child(i)
		var icon = slot.get_node("Icon")
		var label = slot.get_node("Quantity")
		
		if item:
			icon.texture = item.icon
			label.text = str(item.quantity) if item.max_stack > 1 else ""
		else:
			icon.texture = null
			label.text = ""

func toggle_visibility():
	visible = !visible
	get_tree().paused = visible  # Пауза только при открытии
	
	# Добавьте отладочный вывод
	print("Инвентарь: ", "открыт" if visible else "закрыт")
