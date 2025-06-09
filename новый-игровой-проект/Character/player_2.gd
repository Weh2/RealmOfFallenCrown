extends CharacterBody2D

@export var speed = 300.0
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D  # Или AnimatedSprite2D, если используете его

func _physics_process(delta):
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	move_and_slide()

	# Управление анимациями
	if velocity.length() > 0:  # Если персонаж движется
		if abs(velocity.x) > abs(velocity.y):  # Горизонтальное движение важнее
			if velocity.x > 0:
				animation_player.play("walk_right")
			else:
				animation_player.play("walk_left")
		else:  # Вертикальное движение
			if velocity.y > 0:
				animation_player.play("walk_down")
			else:
				animation_player.play("walk_up")
	else:
		animation_player.play("idle")
