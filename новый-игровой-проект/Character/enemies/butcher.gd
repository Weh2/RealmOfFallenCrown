extends CharacterBody2D

# Настройки врага
@export var speed := 120
@export var attack_damage := 15
@export var attack_cooldown := 1.5
@export var attack_range := 50.0
@export var health := 100
@export var corpse_texture: Texture2D

# Уровень врага (добавлено)
@export var current_level: int = 1
@export var level_scaling: Dictionary = {
	"health": 10,
	"damage": 2
}

# Настройки патрулирования
@export var patrol_speed: float = 80.0
@export var wait_time_at_point: float = 1.0
var current_patrol_index := 0
var patrol_points: Array[Vector2] = []
var is_patrolling := true
var patrol_direction := Vector2.ZERO
var is_waiting := false  # Флаг ожидания
var wait_timer := 0.0   

# Состояния врага
enum State {PATROL, IDLE, CHASE, ATTACK, DEAD}
var current_state = State.PATROL
var target = null
var is_dead := false
var attack_in_progress := false
var can_be_looted := false

# Лут система
var generated_loot: Array = []
signal loot_opened(items: Array)

@onready var loot_component = $LootComponent
signal enemy_died()

# Ноды
@onready var sprite := $AnimatedSprite2D
@onready var attack_timer := $AttackTimer
@onready var loot_area := $LootArea
@onready var detection_area := $DetectionArea
@onready var attack_area := $AttackArea
@onready var hitbox := $Hitbox

func _ready():
	scale_enemy_by_level()
	_setup_patrol_points()
	play_animation("idle")

func scale_enemy_by_level():
	health += level_scaling["health"] * (current_level - 1)
	attack_damage += level_scaling["damage"] * (current_level - 1)
	
	# Визуальное отличие для врагов высокого уровня
	if current_level > 1:
		var scale_factor = 1.0 + (current_level - 1) * 0.05
		sprite.scale *= scale_factor
		sprite.modulate = Color(1.0, 0.9, 0.9)  # Легкий красный оттенок


func _setup_patrol_points():
	patrol_points.clear()
	# Собираем все дочерние Marker2D как точки патрулирования
	for child in get_children():
		if child is Marker2D:
			patrol_points.append(child.global_position)
	
	# Если маркеров нет - создаем дефолтный маршрут
	if patrol_points.is_empty():
		patrol_points.append(global_position + Vector2(100, 0))
		patrol_points.append(global_position + Vector2(-100, 0))
		print("Создан дефолтный маршрут патрулирования")

func _physics_process(delta):
	if is_dead: 
		return
	
	match current_state:
		State.PATROL:
			_handle_patrol_state()
		State.IDLE:
			_handle_idle_state()
		State.CHASE:
			_handle_chase_state()
		State.ATTACK:
			_handle_attack_state()
		State.DEAD:
			pass

func _handle_patrol_state():
	if patrol_points.is_empty():
		play_animation("idle")
		return
	
	# Если враг в режиме ожидания
	if is_waiting:
		wait_timer -= get_process_delta_time()
		play_animation("idle")  # Проигрываем анимацию каждый кадр
		if wait_timer <= 0:
			is_waiting = false
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		return
	
	var target_pos = patrol_points[current_patrol_index]
	patrol_direction = (target_pos - global_position).normalized()
	
	# Движение к точке
	velocity = patrol_direction * patrol_speed
	move_and_slide()
	
	# Поворот спрайта
	if patrol_direction.x != 0:
		sprite.flip_h = patrol_direction.x < 0
	
	# Анимация движения
	play_animation("walk")
	
	# Проверка достижения точки
	if global_position.distance_to(target_pos) < 5.0:
		velocity = Vector2.ZERO
		is_waiting = true
		wait_timer = wait_time_at_point
		play_animation("idle")  # Начинаем анимацию ожидания

func _handle_idle_state():
	play_animation("idle")
	if target and _is_target_alive(target):
		var distance = global_position.distance_to(target.global_position)
		if distance <= attack_range:
			current_state = State.ATTACK
		else:
			current_state = State.CHASE

func _handle_chase_state():
	if not target or not _is_target_alive(target):
		current_state = State.PATROL
		return
	
	var chase_direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	if distance <= attack_range:
		current_state = State.ATTACK
		return
	
	velocity = chase_direction * speed
	move_and_slide()
	play_animation("walk")
	sprite.flip_h = chase_direction.x < 0

func _handle_attack_state():
	if not target or not _is_target_alive(target):
		current_state = State.PATROL
		return
	
	var distance = global_position.distance_to(target.global_position)
	if distance > attack_range * 1.1:
		current_state = State.CHASE
		return
	
	velocity = Vector2.ZERO
	if not attack_in_progress and attack_timer.is_stopped():
		_attack_player()

func _attack_player():
	if is_dead or attack_in_progress: 
		return
	
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

func take_damage(incoming_damage: int):
	if is_dead: 
		return
	
	health -= incoming_damage
	play_animation("hurt")
	
	if health <= 0:
		die()

func die():
	if is_dead: 
		return
	
	is_dead = true
	can_be_looted = true
	current_state = State.DEAD
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
	
	# Генерация лута
	if has_node("LootComponent"):
		loot_component.generate_loot()
	else:
		generated_loot = []
	can_be_looted = true
	
	# Даем игроку опыт (исправленная версия)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("gain_xp"):
		var base_xp = 10
		var xp_amount = base_xp * current_level
		
		# Учет разницы уровней (дополнительный бонус/штраф)
		var player_level = 1
		if player.has_method("get_current_level"):
			player_level = player.get_current_level()
		
		var level_diff = current_level - player_level
		var diff_multiplier = 1.0 + level_diff * 0.1
		diff_multiplier = clamp(diff_multiplier, 0.5, 2.0)
		
		xp_amount = int(xp_amount * diff_multiplier)
		player.gain_xp(xp_amount)
		

	
	enemy_died.emit()




func open_loot():
	if can_be_looted:
		if has_node("LootComponent"):
			return loot_component.get_loot()
		return generated_loot
	return []

func play_animation(anim_name: String):
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func _is_target_alive(player):
	return player and player.has_method("take_damage") and not player.is_dead if player.has_method("is_dead") else true

# Обработчики сигналов
func _on_detection_area_body_entered(body):
	if not is_dead and body.is_in_group("player") and _is_target_alive(body):
		target = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if body == target:
		target = null
		current_state = State.PATROL

func _on_attack_area_body_entered(body):
	if not is_dead and body.is_in_group("player") and _is_target_alive(body) and not target:
		target = body
		current_state = State.ATTACK

func _on_attack_timer_timeout():
	if is_dead: 
		return
	if target and global_position.distance_to(target.global_position) <= attack_range:
		_attack_player()
	else:
		current_state = State.CHASE
