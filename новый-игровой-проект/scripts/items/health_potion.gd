class_name HealthPotion
extends ItemData

@export var heal_amount: int = 25
@export var consumable := true  # Добавляем для ясности

func use(user: Node) -> bool:
	if user.has_method("heal"):
		user.heal(heal_amount)
		print("Исцеление: +", heal_amount, " HP")
		return true  # Предмет успешно использован
	return false  # Не удалось использовать (например, у персонажа нет метода heal)
