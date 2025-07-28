extends Area2D
class_name InteractionArea

signal interacted

var player_in_range = false

func _ready():
	collision_mask = 1  # Маска на слой игрока
	# Отключаем детект родительского StaticBody2D
	$CollisionShape2D.disabled = false

func _on_body_entered(body):
	# Пропускаем саму бочку и другие не-игровые объекты
	if body == get_parent() or not body.has_method("get_input_direction"):
		return
	
	print("✅ Игрок вошёл в зону:", body.name)
	player_in_range = true
	body.near_interactable = self

func _on_body_exited(body):
	if body == get_parent():
		return
		
	if body.has_method("get_input_direction") and body.near_interactable == self:
		print("❌ Игрок вышел из зоны")
		player_in_range = false
		body.near_interactable = null

func interact():
	if player_in_range:
		print("🔥 Активируем бочку!")
		interacted.emit()
