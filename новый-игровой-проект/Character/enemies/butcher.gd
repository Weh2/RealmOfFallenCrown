extends CharacterBody2D

@export var speed = 120
@export var damage = 15
@export var attack_cooldown = 1.5  # Задержка между атаками

var target = null
var can_attack = true

func _physics_process(delta):
	if target:  # target — игрок
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

		# Поворот спрайта
		$Sprite2D.flip_h = direction.x < 0

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		target = body

func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and can_attack:
		body.take_damage(damage)  # Вызов метода из скрипта здоровья
		can_attack = false
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
