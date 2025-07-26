extends StaticBody2D

@onready var interaction_area = $InteractionArea
var is_pulled = false

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	print("Рычаг готов. Группы ворот:", get_tree().get_nodes_in_group("gates").size())

func _on_body_entered(body):
	print("В зоне:", body.name)
	if body.is_in_group("player"):
		print("Игрок в зоне взаимодействия")
		# Альтернативный вариант обработки ввода
		set_process_input(true)

func _on_body_exited(body):
	if body.is_in_group("player"):
		set_process_input(false)

func _input(event):
	if event.is_action_pressed("interact") and !is_pulled:
		print("Кнопка нажата")
		if $AnimatedSprite2D.sprite_frames.has_animation("pull"):
			$AnimatedSprite2D.play("pull")
			is_pulled = true
			var gate = get_tree().get_first_node_in_group("gates")
			if gate:
				print("Найдены ворота:", gate.name)
				gate.open()
			else:
				print("Ворота не найдены в группе 'gates'")

func _on_animation_finished():
	if $AnimatedSprite2D.animation == "pull":
		$AnimatedSprite2D.play("idle")
