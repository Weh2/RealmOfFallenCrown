extends Panel

@onready var item_list = $MarginContainer/VBoxContainer/GridContainer  # Изменили путь
@onready var take_all_button = $TakeAllButton  # Прямой дочерний элемент Panel
@onready var close_button = $CloseButton

var current_loot_source = null  # Источник лута (враг)

func _ready():
	hide()
	take_all_button.pressed.connect(_on_take_all_pressed)
	close_button.pressed.connect(_on_close_pressed)
# Добавляем отсутствующий метод
func _clear_items():
	for child in item_list.get_children():
		if child is Button:  # Удаляем только кнопки
			child.queue_free()
func show_loot(items: Array):  # Новая версия (1 аргумент)
	_clear_items()
	
	for item in items:
		var item_btn = Button.new()
		item_btn.text = item.name
		item_btn.pressed.connect(_on_item_taken.bind(item))
		item_list.add_child(item_btn)
	
	show()

func _on_item_taken(item):
	if current_loot_source and current_loot_source.has_method("remove_item"):
		current_loot_source.remove_item(item)
		get_parent().add_to_inventory(item)
		_clear_items()
		# Обновляем список
		var remaining_items = current_loot_source.get_loot()
		if remaining_items.is_empty():
			hide()
		else:
			# Передаём ТОЛЬКО массив items, без source
			show_loot(remaining_items)

# Исправляем ошибку с current_enemy -> current_loot_source
func _on_take_all_pressed():
	if current_loot_source and current_loot_source.has_method("take_all_items"):
		var items = current_loot_source.take_all_items()
		for item in items:
			get_parent().add_to_inventory(item)
		hide()

func _on_close_pressed():
	hide()
