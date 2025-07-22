extends Node2D

@onready var hitbox = $Hitbox/CollisionShape2D
@onready var player_sprite = $"../AnimatedSprite2D"
@onready var weapon_sprite = $Sprite2D

enum AttackType { NORMAL, COMBO1, COMBO2 }
var current_attack = AttackType.NORMAL
var is_attack_active := false
var current_attack_dir = Vector2.RIGHT
@export var current_weapon: InvItem = null  # Используем только одно свойство
var base_attack: int = 10
var attack_cooldown := false
var combo_window := 0.8
var combo_timer := 0.0
var can_combo := false

func _ready():
	assert(hitbox != null, "Hitbox not found!")
	assert(player_sprite != null, "Main AnimatedSprite2D not found in parent!")
	hitbox.disabled = true
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)
	player_sprite.animation_finished.connect(_on_animation_finished)

func update_weapon(weapon_data: InvItem) -> void:
	current_weapon = weapon_data  # Сохраняем оружие в одном месте
	visible = true

	
	# Включаем хитбокс
	hitbox.disabled = false
	
	print("Weapon updated:", weapon_data.name)


func _process(delta):
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo()

func reset_combo():
	can_combo = false
	current_attack = AttackType.NORMAL
	print("Combo reset")

func _on_animation_finished():
	if player_sprite.animation.begins_with("attack"):
		end_attack()
		# Разрешаем комбо только если это не финальная атака
		if current_attack != AttackType.COMBO2:
			can_combo = true
			combo_timer = combo_window
			print("Combo window opened for: ", current_attack)
		else:
			reset_combo()


func end_attack():
	hitbox.disabled = true
	is_attack_active = false
	attack_cooldown = false

func get_attack_damage() -> int:
	var damage = base_attack
	if current_weapon:  # Проверяем current_weapon вместо current_weapon_data
		damage += current_weapon.stats.get("attack", 0)
	
	# Бонус к урону за комбо-атаки
	match current_attack:
		AttackType.COMBO1:
			damage *= 1.2
		AttackType.COMBO2:
			damage *= 1.4
	
	print("Calculated damage: ", damage)  # Добавим отладочный вывод
	return int(damage)

func update_direction(facing_left: bool) -> void:
	if facing_left:
		position = Vector2(-30, 0)
		if weapon_sprite:
			weapon_sprite.flip_h = true
	else:
		position = Vector2(30, 0)
		if weapon_sprite:
			weapon_sprite.flip_h = false

func start_attack(move_direction: Vector2):
	if attack_cooldown:
		return
	
	# Определяем тип следующей атаки
	var next_attack = AttackType.NORMAL
	if can_combo:
		match current_attack:
			AttackType.NORMAL:
				next_attack = AttackType.COMBO1
			AttackType.COMBO1:
				next_attack = AttackType.COMBO2
			AttackType.COMBO2:
				next_attack = AttackType.NORMAL
	
	current_attack = next_attack
	is_attack_active = true
	attack_cooldown = true
	can_combo = false
	
	if move_direction.length() > 0:
		current_attack_dir = move_direction.normalized()
		update_direction(current_attack_dir.x < 0)
	
	# Выбираем анимацию
	var anim_name = get_attack_animation()
	player_sprite.play(anim_name)
	print("Playing attack: ", anim_name)
	
	# Включаем хитбокс
	await get_tree().create_timer(0.1).timeout
	if is_attack_active:
		hitbox.disabled = false

func get_attack_animation() -> String:
	match current_attack:
		AttackType.COMBO1:
			return "attack_combo1"
		AttackType.COMBO2:
			return "attack_combo2"
		_:
			return "attack"

func is_attacking() -> bool:
	return is_attack_active

func _on_hitbox_body_entered(body):
	if body != get_parent() and body.has_method("take_damage") and is_attack_active:
		var final_damage = get_attack_damage()
		body.take_damage(final_damage)
		print("Нанесен урон ", final_damage, " врагу ", body.name)

func unequip_weapon() -> void:
	current_weapon = null
	visible = false
	hitbox.disabled = true
	print("Weapon unequipped")
