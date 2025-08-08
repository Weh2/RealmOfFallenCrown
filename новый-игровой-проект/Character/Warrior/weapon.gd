extends Node2D

@onready var hitbox = $Hitbox/CollisionShape2D
@onready var player_sprite = $"../AnimatedSprite2D"
@onready var weapon_sprite = $Sprite2D

enum AttackType { NORMAL, COMBO1, COMBO2 }
var current_attack = AttackType.NORMAL
var is_attack_active := false
var current_attack_dir = Vector2.RIGHT
@export var current_weapon: InvItem = null
var base_attack: int = 10
var attack_cooldown := false
var combo_window := 0.8
var combo_timer := 0.0
var can_combo := false

# Базовые параметры атаки
@export var base_attack_speed: float = 1.0  # Время между атаками в секундах
var attack_speed_modifier: float = 1.0
var last_attack_time: float = 0.0

func _ready():
	assert(hitbox != null, "Hitbox not found!")
	assert(player_sprite != null, "Main AnimatedSprite2D not found in parent!")
	hitbox.disabled = true
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)
	player_sprite.animation_finished.connect(_on_animation_finished)

func update_weapon(weapon_data: InvItem) -> void:
	current_weapon = weapon_data
	visible = true
	hitbox.disabled = false
	
	# Обновляем модификаторы скорости атаки из предмета
	if weapon_data.stats.has("attack_speed"):
		attack_speed_modifier = 1.0 - (weapon_data.stats["attack_speed"] * 0.01)
		attack_speed_modifier = max(attack_speed_modifier, 0.3)  # Не может быть быстрее 70%
	
	print("Weapon updated: ", weapon_data.name, 
		  " | Attack speed modifier: ", attack_speed_modifier)

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
	if current_weapon:
		damage += current_weapon.stats.get("attack", 0)
	
	# Бонус к урону за комбо-атаки
	match current_attack:
		AttackType.COMBO1:
			damage *= 1.2
		AttackType.COMBO2:
			damage *= 1.4
	
	# Проверка на критический удар
	var crit_chance = get_parent().get_stat_bonus("crit_chance")
	var is_critical = randf() <= crit_chance
	
	if is_critical:
		var crit_damage_bonus = 1.5 + get_parent().get_stat_bonus("crit_damage")
		damage *= crit_damage_bonus
		print("CRITICAL HIT! Damage: ", damage, 
			  " (Chance: ", crit_chance * 100, "%, Multiplier: x", crit_damage_bonus, ")")
	
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
	# Проверка кулдауна с учетом скорости атаки
	var current_time = Time.get_ticks_msec() / 1000.0
	if attack_cooldown and (current_time - last_attack_time) < (base_attack_speed * attack_speed_modifier):
		return
	
	last_attack_time = current_time
	
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
	
	# Ускорение анимации в зависимости от скорости атаки
	var anim_speed = 1.0 / attack_speed_modifier
	player_sprite.speed_scale = anim_speed
	
	var anim_name = get_attack_animation()
	player_sprite.play(anim_name)
	print("Playing attack: ", anim_name, " (Speed: ", anim_speed, "x)")
	
	# Включаем хитбокс с задержкой (можно регулировать под анимацию)
	await get_tree().create_timer(0.1 / anim_speed).timeout
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
	attack_speed_modifier = 1.0  # Сбрасываем модификатор скорости
	player_sprite.speed_scale = 1.0  # Возвращаем нормальную скорость анимации
	print("Weapon unequipped")
