extends StaticBody2D

@onready var loot_component = $LootComponent
var is_opened = false

func _ready():
	# Явное подключение сигнала
	if not loot_component.loot_generated.is_connected(_on_loot_generated):
		loot_component.loot_generated.connect(_on_loot_generated)
	print("Бочка инициализирована. Сигналы подключены:", loot_component.loot_generated.is_connected(_on_loot_generated))

func interact():
	if not is_opened:
		open()

func open():
	print("Открываю бочку")
	is_opened = true
	$Sprite2D.modulate = Color.GREEN
	loot_component.generate_loot()  # Генерируем лут

func _on_loot_generated(items: Array):
	print("Получен лут:", items)
	if items.is_empty():
		print("Бочка пуста!")
		return
	
	# Явная проверка LootUI
	if get_tree().has_group("loot_ui"):
		get_tree().call_group("loot_ui", "show_loot", items, self)
	else:
		push_error("LootUI не найден в группах!")

func take_item(item_id: String, amount: int):
	print("Взят предмет: ", item_id, " x", amount)
