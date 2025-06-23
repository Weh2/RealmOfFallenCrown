extends StaticBody2D

@export var item: InvItem
var player = null


func _on_interactable_area_body_entered(body):
	if body.has_method("collect"):  # Проверяем метод collect
		body.collect(item)  # Сначала добавляем в инвентарь
		queue_free()       # Затем удаляем

func playercollect():
	player.collect(item)
