extends Node2D

@export var damage = 40
@onready var hitbox = $Hitbox/CollisionShape2D
@onready var player_anim = $"../AnimationPlayer"  # Получаем AnimationPlayer из родителя

var is_attack_active := false
var current_attack_dir = Vector2.RIGHT  # Текущее направление атаки

func _ready():
	assert(hitbox != null, "Hitbox not found!")
	assert(player_anim != null, "Main AnimationPlayer not found in parent!")
	hitbox.disabled = true
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)

func start_attack(move_direction: Vector2):
	if is_attack_active: 
		return
		
	is_attack_active = true
	
	# Обновляем направление и поворачиваем оружие
	if move_direction.length() > 0:
		current_attack_dir = move_direction.normalized()
		rotation = current_attack_dir.angle()  # Поворачиваем весь нод Weapon
	
	# Определяем анимацию
	var anim_name = "attack_right"
	if current_attack_dir.length() > 0:
		if abs(current_attack_dir.x) > abs(current_attack_dir.y):
			anim_name = "attack_right" if current_attack_dir.x > 0 else "attack_left"
		else:
			anim_name = "attack_down" if current_attack_dir.y > 0 else "attack_up"
	
	# Проигрываем анимацию из основного AnimationPlayer
	player_anim.play(anim_name)
	
	# Включаем хитбокс через 0.2 сек
	await get_tree().create_timer(0.2).timeout
	hitbox.disabled = false
	
	# Ждем окончания анимации
	await player_anim.animation_finished
	
	# Отключаем хитбокс
	hitbox.disabled = true
	is_attack_active = false

func is_attacking() -> bool:
	return is_attack_active

func _on_hitbox_body_entered(body):
	if body != get_parent() and body.has_method("take_damage"):
		body.take_damage(damage)
		print("Нанесен урон ", damage, " врагу ", body.name)
