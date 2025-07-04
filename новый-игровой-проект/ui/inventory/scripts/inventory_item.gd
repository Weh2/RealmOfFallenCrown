extends Resource
class_name InvItem

enum ItemType {
	Weapon = 0,   # Теперь с большой буквы как в инспекторе
	Shield = 1,
	Body = 2,
	Head = 3,
	Hands = 4,
	Legs = 5,
	Ring = 6,
	Amulet = 7,
	Consumable = 8
}

@export var name: String = "Предмет"
@export var texture: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1
@export var item_type: ItemType = ItemType.Consumable
@export var stats: Dictionary = {
	"attack": 0,
	"defense": 0,
	"health": 0,
	"stamina": 0
}
