extends Panel

@onready var grid = $MarginContainer/VBoxContainer/GridContainer
@onready var take_all_button = $TakeAllButton
@onready var close_button = $CloseButton

var current_loot_source = null
var is_open = false
var loot_items: Array = []

func _ready():
	hide()
	take_all_button.pressed.connect(_on_take_all_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	for i in range(grid.get_child_count()):
		var slot = grid.get_child(i)
		slot.slot_index = i
		slot.slot_clicked.connect(_on_slot_clicked)

func _input(event):
	if visible and event.is_action_pressed("interact"):
		hide()
		is_open = false
		get_viewport().set_input_as_handled()

func show_loot(items: Array, source):
	if source.is_in_group("lootable"):  # Проверяем, что источник — бочка/сундук
		current_loot_source = source
	print("Showing loot with items:", items)
	if items.is_empty():
		print("No items to show!")
		return
		
	current_loot_source = source
	loot_items = items
	
	# Очищаем все слоты
	for slot in grid.get_children():
		slot.update_slot(null, 0)
	
	# Заполняем слоты
	for i in range(min(items.size(), grid.get_child_count())):
		var item_data = items[i]
		if item_data and item_data.has("item"):
			grid.get_child(i).update_slot(item_data["item"], item_data["quantity"])
		else:
			print("Invalid item data at index", i)
	
	show()
	is_open = true

func _on_slot_clicked(index: int, item: InvItem, quantity: int):
	if item and current_loot_source:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("collect_multiple"):
			# Используем новый метод для добавления сразу всего количества
			player.collect_multiple(item, quantity)
			
			# Удаляем из лута
			if index < loot_items.size():
				loot_items.remove_at(index)
				grid.get_child(index).update_slot(null, 0)
	# Обновляем источник лута
	if current_loot_source and current_loot_source.has_method("update_loot"):
		current_loot_source.update_loot(loot_items)
		
		
func _on_take_all_pressed():
	if current_loot_source:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("collect"):
			for item_data in loot_items:
				for i in range(item_data["quantity"]):
					player.collect(item_data["item"].duplicate())
		
		loot_items.clear()
		for slot in grid.get_children():
			slot.update_slot(null, 0)
		
		hide()
		is_open = false
	if current_loot_source and current_loot_source.has_method("update_loot"):
		current_loot_source.update_loot([])  # Передаем пустой массив


func _on_close_pressed():
	hide()
	is_open = false


func sort_items_by_quality(items: Array):
	items.sort_custom(func(a, b): 
		return a["item"].quality > b["item"].quality
	)
