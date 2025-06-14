extends CharacterBody2D

@export var speed = 120
@export var attack_damage = 15  # Переименовали для ясности
@export var attack_cooldown = 1.5
@export var attack_range = 50.0
@export var health := 100

var target = null
var can_attack = true

func take_damage(incoming_damage: int):  # Исправленный параметр
	health -= incoming_damage
	print("Enemy health: ", health)
	
	if health <= 0:
		queue_free()
		print("Enemy died!")

func _physics_process(_delta):  # Исправленный параметр
	if not target:
		return
	
	if not _is_target_alive(target):
		target = null
		return
	
	var direction = (target.global_position - global_position).normalized()
	var distance_to_target = global_position.distance_to(target.global_position)
	
	if distance_to_target > attack_range:
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if can_attack:
			_attack_player()

func _is_target_alive(player):
	if not player or not player.has_node("HealthComponent"):
		return false
	return player.get_node("HealthComponent").current_health > 0

func _attack_player():
	can_attack = false
	target.get_node("HealthComponent").take_damage(attack_damage)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_detection_area_body_entered(body):
	if body.is_in_group("player") and _is_target_alive(body):
		target = body

func _on_detection_area_body_exited(body):
	if body == target:
		target = null

func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and _is_target_alive(body):
		if not target:
			target = body
