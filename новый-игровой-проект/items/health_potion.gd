class_name HealthPotion
extends ItemData

@export var heal_amount: int = 25

func use(user: Node) -> bool:
	if user.has_method("heal"):
		user.heal(heal_amount)
		print("Восстановлено ", heal_amount, " HP")
		return true
	return false
