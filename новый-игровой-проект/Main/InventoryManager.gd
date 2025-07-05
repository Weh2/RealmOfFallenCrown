extends Node
class_name InventoryManager

# Делаем inventory публичной переменной
var inventory: Inv

func _ready():
	# Создаем и инициализируем инвентарь
	inventory = Inv.new()
	call_deferred("_initialize_inventory")  # Отложенная инициализация

func _initialize_inventory():
	inventory._init()  # Вызываем инициализацию слотов
	print("Inventory initialized:", inventory != null)  # Для отладки
