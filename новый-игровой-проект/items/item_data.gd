extends Resource
class_name ItemData

@export var name: String = "Предмет"
@export var icon: Texture2D          # Иконка 64x64 пикселей
@export var max_stack: int = 1       # Максимальный размер стека
@export var consumable: bool = true  # Расходуется ли при использовании
@export var quantity: int = 1        # Текущее количество

# Базовый метод использования
func use(user: Node) -> bool:
	print("Использован: ", name)
	return true  # Возвращает успешность использования
