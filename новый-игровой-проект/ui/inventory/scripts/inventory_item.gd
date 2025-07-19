extends Resource
class_name InvItem

enum ItemType {
	WEAPON = 0,
	SHIELD = 1,
	BODY = 2,
	HEAD = 3,
	HANDS = 4,
	LEGS = 5,
	RING = 6,
	AMULET = 7,
	CONSUMABLE = 8
}

@export_category("Item Properties")
@export var name: String = "Item"
@export var texture: Texture2D
@export var item_type: ItemType = ItemType.WEAPON
@export var stackable: bool = false
@export var max_stack: int = 1
@export var stats: Dictionary = {
	"attack": 0,
	"defense": 0,
	"health": 0,
	"stamina": 0
}

# Метод для получения уникального идентификатора предмета
func get_id() -> String:
	return "%s_%d" % [name, item_type]

func apply_effects(player: Node):
	match name:
		"Health Potion":
			player.heal(30)
		"Stamina Potion":
			player.current_stamina = min(player.current_stamina + 50, player.max_stamina)
		"Meat":
			player.heal(stats.get("health", 15))
			player.current_stamina = min(
				player.current_stamina + stats.get("stamina", 20),
				player.max_stamina
			)
