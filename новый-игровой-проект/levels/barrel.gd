extends Area2D
class_name Barrel

@onready var sprite = $Sprite2D
@onready var loot_component = $LootComponent

var player_in_range := false
var current_loot: Array = []  # Храним текущий лут

func _ready():
	add_to_group("lootable")  
	reset_loot()  # Генерируем начальный лут
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func reset_loot():
	current_loot = loot_component.generate_loot()


func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		print("Игрок вошел в зону бочки")

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		print("Игрок вышел из зоны бочки")

func interact():
	if not player_in_range:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_loot_ui"):
		var ui = player.get_loot_ui()
		if ui:
			if ui.is_visible() and ui.current_loot_source == self:
				# Если UI уже открыт для этой бочки - закрываем
				ui.hide()
			else:
				# Показываем текущий лут
				var grouped_loot = _group_loot_items(current_loot)
				ui.show_loot(grouped_loot, self)

# Вызывается из LootUI при взятии предметов
func update_loot(remaining_loot: Array):
	current_loot = remaining_loot

	
	# Если лут закончился, можно вызвать reset_loot() через какое-то время
	if current_loot.is_empty():
		await get_tree().create_timer(60.0).timeout  # Через 60 секунд
		reset_loot()

# Группировка лута (без изменений)
func _group_loot_items(loot: Array) -> Array:
	var grouped = {}
	for item_data in loot:
		var item = item_data["item"]
		var quantity = item_data["quantity"]
		if item in grouped:
			grouped[item]["quantity"] += quantity
		else:
			grouped[item] = {"item": item, "quantity": quantity}
	return grouped.values()
