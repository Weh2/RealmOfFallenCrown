extends Area2D
class_name InteractionArea

signal interacted

var player_in_range = false

func _ready():
	# Явная настройка масок
	collision_mask = 1  # Только слой игрока
	monitoring = true
	
	# Проверка формы коллайдера
	if not $CollisionShape2D.shape:
		push_error("CollisionShape2D не имеет формы!")
	else:
		print("Тип формы:", $CollisionShape2D.shape)

func _on_body_entered(body):
	print("Тело вошло в зону:", body.name, "| Группы:", body.get_groups())
	if body.is_in_group("player"):
		print("✅ Игрок вошёл в зону взаимодействия")
		player_in_range = true
		body.near_interactable = self

func _on_body_exited(body):
	if body.is_in_group("player"):
		print("❌ Игрок вышел из зоны")
		player_in_range = false
		if body.near_interactable == self:
			body.near_interactable = null

func interact():
	print("Вызов interact() | player_in_range =", player_in_range)
	if player_in_range:
		interacted.emit()
