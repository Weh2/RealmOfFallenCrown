extends StaticBody2D

@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape2D
@onready var sprite = $AnimatedSprite2D

var is_opened = false  # Трекер состояния

func _ready():
	animation_player.animation_finished.connect(_on_animation_finished)
	add_to_group("gates")
	print("Ворота инициализированы, is_opened = ", is_opened)

func open():
	if !is_opened:
		is_opened = true
		print("Открываем ворота")
		if sprite.sprite_frames.has_animation("open"):
			sprite.play("open")
		else:
			animation_player.play("open")
	# Отключаем коллайдер сразу (или через таймер)
	$CollisionShape2D.set_deferred("disabled", true)


func close():
	if is_opened:
		is_opened = false
		print("Закрываем ворота")
		if sprite.sprite_frames.has_animation("open"):
			sprite.play_backwards("open")  # Проигрываем анимацию в обратном порядке
		else:
			animation_player.play_backwards("open")
		# Включаем коллайдер сразу при начале закрытия
		collision_shape.set_deferred("disabled", false)

func _on_animation_finished(anim_name):
	if anim_name == "open":
		collision_shape.disabled = is_opened
		print("Анимация завершена. Состояние: ", "открыто" if is_opened else "закрыто")
