extends CharacterBody2D

@export var speed = 120
@export var damage = 15
@export var attack_cooldown = 1.5
@export var attack_range = 50.0
@export var health := 100  # Перенесли в export для удобства настройки

@onready var hurtbox = $Hurtbox  # Обязательно добавьте Area2D с CollisionShape2D
@onready var health_component = $HealthComponent  # Если используете компонент

var target = null
var can_attack = true

func _ready():
	# Автоподключение сигналов
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	add_to_group("enemies")  # Важно для идентификации
	
	# Инициализация здоровья, если используете HealthComponent
	if health_component:
		health_component.died.connect(_on_death)
		

func take_damage(damage: int):
	if health_component:  # Если используете компонент здоровья
		health_component.take_damage(damage)
	else:
		health -= damage
		print("Enemy took ", damage, " damage. Remaining HP: ", health)
		
		if health <= 0:
			_on_death()
	var sprite = $Sprite2D
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _on_death():
	print("Enemy died!")
	queue_free()

func _on_hurtbox_body_entered(body):
	if body.is_in_group("player_weapons"):  # Группа для атак игрока
		if body.has_method("get_damage"):
			take_damage(body.get_damage())
		elif body.has_method("take_damage"):  # Совместимость со старым кодом
			take_damage(body.damage)
			

# Остальные функции (_physics_process, _attack_player и т.д.) остаются без изменений

func _physics_process(delta):
	if not target:
		return
	
	# Проверяем жив ли игрок
	if not _is_target_alive(target):
		target = null
		return
	
	# Двигаемся к игроку
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
	target.get_node("HealthComponent").take_damage(damage)
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

func _on_attack_area_body_exited(body):
	pass  # Не нужно сбрасывать цель при выходе из зоны атаки
