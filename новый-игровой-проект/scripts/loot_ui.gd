extends Panel

signal item_taken(item)          # Сигнал при взятии одного предмета
signal all_items_taken(items)    # Сигнал при взятии всех предметов
signal loot_closed()             # Сигнал при закрытии

@onready var item_list = $VBoxContainer
@onready var take_all_button = $TakeAllButton
@onready var close_button = $CloseButton

var current_items = []

func _ready():
	hide()
	take_all_button.pressed.connect(_on_take_all_pressed)
	close_button.pressed.connect(_on_close_pressed)

func show_loot(items: Array):
	current_items = items.duplicate()
	_update_item_list()
	show()

func _update_item_list():
	# Очищаем старые элементы
	for child in item_list.get_children():
		child.queue_free()
	
	# Добавляем новые
	for item in current_items:
		var btn = Button.new()
		btn.text = item.name
		btn.pressed.connect(_on_item_clicked.bind(item))
		item_list.add_child(btn)

func _on_item_clicked(item):
	emit_signal("item_taken", item)
	current_items.erase(item)
	_update_item_list()

func _on_take_all_pressed():
	emit_signal("all_items_taken", current_items.duplicate())
	current_items.clear()
	hide()

func _on_close_pressed():
	emit_signal("loot_closed")
	hide()
