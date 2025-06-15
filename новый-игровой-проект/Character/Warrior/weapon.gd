extends Node2D

@export var damage := 40  # Используем новый экспорт с типизацией
@onready var hitbox = $Hitbox/CollisionShape2D
@onready var player_anim = $"../AnimationPlayer"
@onready var weapon_sprite = $Sprite2D

var is_attack_active := false
var current_attack_dir = Vector2.RIGHT
var attack_duration := 0.3  # Новая переменная для длительности атаки

func _ready():
	assert(hitbox != null, "Hitbox not found!")
	assert(player_anim != null, "Main AnimationPlayer not found in parent!")
	hitbox.disabled = true
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)

func update_direction(facing_left: bool):
	# Обновленная версия с reset_vertical_position
	if facing_left:
		position = Vector2(-30, 0)  # Комбинируем оба подхода
		if weapon_sprite:
			weapon_sprite.flip_h = true
	else:
		position = Vector2(30, 0)
		if weapon_sprite:
			weapon_sprite.flip_h = false

func start_attack(move_direction: Vector2):
	if is_attack_active: 
		return
		
	is_attack_active = true
	
	# Обновляем направление
	if move_direction.length() > 0:
		current_attack_dir = move_direction.normalized()
		rotation = current_attack_dir.angle()
		
		# Обновляем позицию хитбокса на основе направления
		var facing_left = current_attack_dir.x < 0
		update_direction(facing_left)
	
	# Определяем анимацию
	var anim_name = "attack_right"
	if current_attack_dir.length() > 0:
		if abs(current_attack_dir.x) > abs(current_attack_dir.y):
			anim_name = "attack_right" if current_attack_dir.x > 0 else "attack_left"
		else:
			anim_name = "attack_down" if current_attack_dir.y > 0 else "attack_up"
	
	player_anim.play(anim_name)
	hitbox.disabled = false
	
	# Используем новую переменную длительности атаки
	await get_tree().create_timer(attack_duration).timeout
	
	hitbox.disabled = true
	is_attack_active = false

func is_attacking() -> bool:
	return is_attack_active

func _on_hitbox_body_entered(body):
	if body != get_parent() and body.has_method("take_damage"):
		body.take_damage(damage)
		print("Нанесен урон ", damage, " врагу ", body.name)
