extends Area2D
class_name Chest

@onready var sprite = $AnimatedSprite2D
@onready var loot_component = $LootComponent

var is_opened := false
var player_in_range := false

func _ready():
	add_to_group("lootable")  
	loot_component.generate_loot()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.play("closed")  # Начинаем с закрытого состояния

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		print("Игрок вошел в зону сундука")

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		print("Игрок вышел из зоны сундука")

func interact():
	if is_opened or not player_in_range:
		return
	
	# Проигрываем анимацию открытия
	sprite.play("opening")
	await sprite.animation_finished  # Ждем завершения анимации
	
	# Переключаем на статичный кадр открытого сундука
	sprite.play("opened")
	is_opened = true
	
	# Показываем лут
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var ui = player.get_loot_ui()
		if ui:
			var loot = loot_component.get_loot()
			var grouped_loot = _group_loot_items(loot)
			ui.show_loot(grouped_loot, self)

# Группирует одинаковые предметы в один слот
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
