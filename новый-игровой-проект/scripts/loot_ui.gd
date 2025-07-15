extends Panel

@onready var item_list = $ScrollContainer/VBoxContainer
@onready var take_all_button = $TakeAllButton
@onready var close_button = $CloseButton

var current_enemy = null

func _ready():
	hide()
	take_all_button.pressed.connect(_on_take_all_pressed)
	close_button.pressed.connect(_on_close_pressed)

func show_loot(items: Array, enemy):
	current_enemy = enemy
	_clear_items()
	
	for i in range(items.size()):
		var item = items[i]
		var hbox = HBoxContainer.new()
		
		# Иконка предмета
		var texture_rect = TextureRect.new()
		texture_rect.texture = item.get("texture")
		texture_rect.custom_minimum_size = Vector2(32, 32)
		hbox.add_child(texture_rect)
		
		# Название и количество
		var label = Label.new()
		label.text = "%s x%d" % [item["name"], item["quantity"]]
		hbox.add_child(label)
		
		# Кнопка взять
		var take_button = Button.new()
		take_button.text = "Взять"
		take_button.pressed.connect(_on_item_take.bind(i))
		hbox.add_child(take_button)
		
		item_list.add_child(hbox)
	
	show()

func _clear_items():
	for child in item_list.get_children():
		child.queue_free()

func _on_item_take(index):
	if current_enemy and current_enemy.has_method("remove_item"):
		var item = current_enemy.remove_item(index)
		if item:
			get_parent().add_to_inventory(item)
			
			# Обновляем список
			var remaining_loot = current_enemy.get_loot()
			if remaining_loot.is_empty():
				hide()
			else:
				show_loot(remaining_loot, current_enemy)

func _on_take_all_pressed():
	if current_enemy and current_enemy.has_method("take_all_items"):
		var items = current_enemy.take_all_items()
		for item in items:
			get_parent().add_to_inventory(item)
		hide()

func _on_close_pressed():
	hide()
