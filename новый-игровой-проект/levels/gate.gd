extends StaticBody2D

@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape2D


func _ready():
	animation_player.animation_finished.connect(_on_animation_finished)
	print("Сигналы подключены")
	add_to_group("gates")

func open():
	print("Метод open() вызван!")
	if $AnimatedSprite2D.sprite_frames.has_animation("open"):
		print("Анимация найдена в AnimatedSprite2D")
		$AnimatedSprite2D.play("open")
	else:
		print("ОШИБКА: Анимация не найдена в AnimatedSprite2D")
	
	# Отключаем коллайдер сразу (или через таймер)
	$CollisionShape2D.set_deferred("disabled", true)


func _on_animation_finished(anim_name):
	if anim_name == "open":
		# Отключаем коллайдер после анимации
		collision_shape.set_deferred("disabled", true)
