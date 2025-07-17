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
	
	# Подключаем сигналы от всех слотов
	for i in range(grid.get_child_count()):
		var slot = grid.get_child(i)
		slot.slot_index = i
		slot.slot_clicked.connect(_on_slot_clicked)

func _on_slot_clicked(index: int, item: InvItem, quantity: int):
	if item and current_loot_source:
		# Добавляем предмет в инвентарь игрока
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("collect"):
			for i in range(quantity):
				player.collect(item)
		
		# Удаляем предмет из источника лута
		if current_loot_source.has_method("remove_item"):
			current_loot_source.remove_item(index)
		
		# Обновляем отображение
		show_loot(loot_items)

func show_loot(items: Array):
	loot_items = items
	# Очищаем все слоты
	for slot in grid.get_children():
		slot.update_slot(null, 0)
	
	# Заполняем слоты предметами
	for i in range(min(items.size(), grid.get_child_count())):
		var item_data = items[i]
		grid.get_child(i).update_slot(item_data["item"], item_data["quantity"])
	
	show()
	is_open = true

func _on_take_all_pressed():
	if current_loot_source:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("collect"):
			for item_data in loot_items:
				for i in range(item_data["quantity"]):
					player.collect(item_data["item"])
		
		if current_loot_source.has_method("take_all_items"):
			current_loot_source.take_all_items()
		
		hide()
		is_open = false
		current_loot_source = null

func _on_close_pressed():
	hide()
	is_open = false
	current_loot_source = null
