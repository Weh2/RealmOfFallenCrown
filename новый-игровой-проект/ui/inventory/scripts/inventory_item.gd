extends Resource
class_name InvItem

enum ItemType {
	WEAPON,
	SHIELD,
	BODY,
	HANDS,
	LEGS,
	HEAD,
	RING,
	AMULET,
	CONSUMABLE
}

@export var name: String = "Предмет"
@export var texture: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var stats: Dictionary = {
	"attack": 0,
	"defense": 0,
	"health": 0,
	"stamina": 0
}
