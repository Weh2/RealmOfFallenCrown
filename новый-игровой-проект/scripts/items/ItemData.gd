extends Resource
class_name ItemData

@export var name: String = "Предмет"
@export var icon: Texture2D
@export var max_stack: int = 1

func use(user: Node) -> bool:
	print("Used: ", name)
	return true
