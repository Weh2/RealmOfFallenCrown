extends Resource
class_name InvItem

@export var name: String = "Предмет"
@export var texture: Texture2D
@export var stackable: bool = true  # Добавляем новое свойство
@export var max_stack: int = 99     # Максимальный размер стека
