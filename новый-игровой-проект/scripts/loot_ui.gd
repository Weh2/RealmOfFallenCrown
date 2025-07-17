extends Panel

@onready var grid = $MarginContainer/VBoxContainer/GridContainer
@onready var take_all_button = $TakeAllButton
@onready var close_button = $CloseButton

var current_loot_source = null
var is_open = false
var is_initialized = false
func _ready():
	hide()
	take_all_button.pressed.connect(_on_take_all_pressed)
	close_button.pressed.connect(_on_close_pressed)

func toggle_loot(items: Array):
	if is_open:
		hide()
		is_open = false
	else:
		show_loot(items)
		is_open = true

func show_loot(items: Array):
	# Очищаем только содержимое слотов
	for slot in grid.get_children():
		slot.update_slot(null, 0)
	
	# Обновляем слоты
	for i in range(min(items.size(), grid.get_child_count())):
		var item_data = items[i]
		grid.get_child(i).update_slot(item_data["item"], item_data["quantity"])
	
	show()

func _on_close_pressed():
	hide()
	is_open = false
	current_loot_source = null

func _on_take_all_pressed():
	if current_loot_source:
		var items = current_loot_source.take_all_items()
		# Логика добавления предметов
		hide()
		is_open = false
