extends Node
class_name LootComponent

@export var loot_table: Array[InvItem] = []  # Ресурсы предметов из вашего InvItem
@export var max_loot_slots: int = 3  # Макс. количество предметов
@export var drop_chance: float = 0.7  # Шанс выпадения лута

var inventory: Array[InvItem] = []

func _ready():
	# Заполняем инвентарь случайными предметами
	for i in max_loot_slots:
		if loot_table.size() > 0 and randf() < drop_chance:
			var random_item = loot_table[randi() % loot_table.size()].duplicate()
			inventory.append(random_item)

# Вызывается при смерти врага
func get_loot() -> Array[InvItem]:
	return inventory
