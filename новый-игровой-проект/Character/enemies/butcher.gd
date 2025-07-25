extends CharacterBody2D

# Настройки врага
@export var speed := 120
@export var attack_damage := 15
@export var attack_cooldown := 1.5
@export var attack_range := 50.0
@export var health := 100
@export var corpse_texture: Texture2D

# Состояния врага
enum State {IDLE, CHASE, ATTACK, DEAD}
var current_state = State.IDLE
var target = null
var is_dead := false
var attack_in_progress := false
var can_be_looted := false

# Настройки лута
@export_category("Loot Settings")
@export var loot_items: Array[InvItem] = [
	preload("res://ui/inventory/items/knife.tres"),
	preload("res://ui/inventory/items/meat.tres")
]
@export var loot_chance: float = 0.7  # 80% шанс выпадения
@export var min_quantity: int = 1
@export var max_quantity: int = 3

# Лут система
var generated_loot: Array = []  # Будем хранить сгенерированный лут
signal loot_opened(items: Array)
signal enemy_died()

# Ноды
@onready var sprite := $AnimatedSprite2D
@onready var attack_timer := $AttackTimer
@onready var loot_area := $LootArea
@onready var detection_area := $DetectionArea
@onready var attack_area := $AttackArea
@onready var hitbox := $Hitbox



func _ready():
	print("Загруженные предметы для лута:")
	for item in loot_items:
		if item:
			print("- ", item.resource_path, " exists:", ResourceLoader.exists(item.resource_path))
		else:
			print("- NULL item in loot_items")
	play_animation("idle")
	if has_node("LootComponent"):
		$LootComponent.connect("loot_opened", _on_loot_opened)
		
		
func _on_loot_opened(items):
	emit_signal("loot_opened", items)
# Основные функции
func take_damage(incoming_damage: int):
	if is_dead: return
	
	health -= incoming_damage
	play_animation("hurt")
	
	if health <= 0:
		die()

func die():
	if is_dead: 
		return
	is_dead = true
	can_be_looted = true
	add_to_group("corpses")
	
	# Отключаем коллайдеры
	$CollisionShape2D.disabled = true
	$Hitbox/CollisionShape2D.disabled = true
	$DetectionArea/CollisionShape2D.disabled = true
	$AttackArea/CollisionShape2D.disabled = true
	
	# Меняем слои
	set_collision_layer_value(2, false)  # Отключаем enemies
	set_collision_layer_value(5, true)   # Включаем corpses
	
	play_animation("death")
	await sprite.animation_finished
	sprite.stop()
	sprite.frame = sprite.sprite_frames.get_frame_count("death") - 1
	generated_loot = generate_loot()  # Генерируем лут один раз
	can_be_looted = true



func generate_loot() -> Array:
	var final_loot = []
	var items_to_drop = []
	
	# Сначала определяем какие типы предметов выпадут
	for item in loot_items:
		if item and randf() <= loot_chance:
			items_to_drop.append(item)
	
	# Для каждого выпадающего типа предмета определяем количество
	for item in items_to_drop:
		# Для оружия всегда 1 экземпляр
		if item.item_type == InvItem.ItemType.WEAPON:
			final_loot.append({
				"item": item.duplicate(),
				"quantity": 1  # Оружие всегда в одном экземпляре
			})
		else:
			# Для остальных предметов случайное количество
			final_loot.append({
				"item": item.duplicate(),
				"quantity": randi_range(min_quantity, max_quantity)
			})
	
	return final_loot
	

func open_loot():
	print("--- Enemy.open_loot() ---")
	print("Can be looted:", can_be_looted)
	if can_be_looted:
		print("Emitting loot_opened signal")
		return generated_loot  # Просто возвращаем текущий лут
	return []
# Лут система
func get_loot():
	return loot_items.duplicate()

func remove_item(index: int):
	if index >= 0 and index < generated_loot.size():
		generated_loot.remove_at(index)
		return true
	return false

func take_all_items():
	generated_loot.clear()
	return true


# Логика поведения
func _physics_process(delta):
	if is_dead: return
	
	if not target or not _is_target_alive(target):
		current_state = State.IDLE
		play_animation("idle")
		return
	
	var direction = (target.global_position - global_position).normalized()
	var distance_to_target = global_position.distance_to(target.global_position)
	
	match current_state:
		State.IDLE:
			_handle_idle_state(distance_to_target)
		State.CHASE:
			_handle_chase_state(distance_to_target, direction)
		State.ATTACK:
			_handle_attack_state(distance_to_target)

func _handle_idle_state(distance_to_target):
	if distance_to_target <= attack_range:
		current_state = State.ATTACK
	else:
		current_state = State.CHASE

func _handle_chase_state(distance_to_target, direction):
	if distance_to_target <= attack_range:
		current_state = State.ATTACK
		return
	
	velocity = direction * speed
	move_and_slide()
	play_animation("walk")
	sprite.flip_h = direction.x < 0

func _handle_attack_state(distance_to_target):
	if distance_to_target > attack_range * 1.1:
		current_state = State.CHASE
		return
	
	velocity = Vector2.ZERO
	if not attack_in_progress and attack_timer.is_stopped():
		_attack_player()

func _attack_player():
	if is_dead or attack_in_progress: return
	
	attack_in_progress = true
	play_animation("attack")
	
	await get_tree().create_timer(0.3).timeout
	
	if not is_dead and target and _is_target_alive(target) and global_position.distance_to(target.global_position) <= attack_range * 1.1:
		target.take_damage(attack_damage, global_position)
	
	await sprite.animation_finished
	
	if not is_dead:
		play_animation("idle")
		attack_in_progress = false
		attack_timer.start(attack_cooldown)

# Вспомогательные функции
func play_animation(anim_name: String):
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func _is_target_alive(player):
	return player and player.has_method("take_damage") and not player.is_dead if player.has_method("is_dead") else true

# Обработчики сигналов
func _on_detection_area_body_entered(body):
	if not is_dead and body.is_in_group("player") and _is_target_alive(body):
		target = body

func _on_detection_area_body_exited(body):
	if body == target:
		target = null
		current_state = State.IDLE

func _on_attack_area_body_entered(body):
	if not is_dead and body.is_in_group("player") and _is_target_alive(body) and not target:
		target = body

func _on_attack_timer_timeout():
	if is_dead: return
	if target and global_position.distance_to(target.global_position) <= attack_range:
		_attack_player()
	else:
		current_state = State.CHASE
