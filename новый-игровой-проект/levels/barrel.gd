extends StaticBody2D

@onready var loot_component = $LootComponent
@onready var interaction_area = $InteractionArea

var is_opened = false

func _ready():
	# Явная проверка подключения сигналов
	if not interaction_area.interacted.is_connected(_on_interacted):
		interaction_area.interacted.connect(_on_interacted)
	if not loot_component.loot_generated.is_connected(_on_loot_generated):
		loot_component.loot_generated.connect(_on_loot_generated)
	
	print("Бочка инициализирована. Готово к взаимодействию.")

func _on_interacted():
	print("Сигнал interacted получен!")
	if not is_opened and interaction_area.player_in_range:
		print("Условия открытия выполнены")
		open()
	else:
		print("Не выполнены условия:", 
			  "is_opened=", is_opened, 
			  "player_in_range=", interaction_area.player_in_range)

func open():
	print("Открываю бочку...")
	is_opened = true
	loot_component.generate_loot()
	# Визуальная обратная связь
	$Sprite2D.modulate = Color.GREEN

func _on_loot_generated(items: Array):
	print("Сгенерирован лут:", items)
	if items.is_empty():
		print("Бочка пуста!")
	get_tree().call_group("loot_ui", "show_loot", items, self)

func take_item(item_id: String, amount: int):
	print("Предмет взят из бочки:", item_id, "x", amount)
