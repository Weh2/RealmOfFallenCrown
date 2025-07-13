extends CharacterBody2D

# Настройки
@export var speed := 120
@export var attack_damage := 15
@export var attack_cooldown := 1.5
@export var attack_range := 50.0
@export var health := 100
@export var corpse_texture: Texture2D

# Ссылки на ноды
@onready var sprite := $AnimatedSprite2D
@onready var attack_timer := $AttackTimer  # Изменено с AttackCooldownTimer на AttackTimer
@onready var loot_area := $LootArea # Добавляем ссылку на LootArea


# Состояния
enum State {IDLE, CHASE, ATTACK, DEAD}
var current_state = State.IDLE
var target = null
var is_dead := false
var attack_in_progress := false

func _ready():
	play_animation("idle")

func take_damage(incoming_damage: int):
	if is_dead: return
	
	health -= incoming_damage
	play_animation("hurt")
	print("Enemy health: ", health)
	
	if health <= 0:
		die()

func die():
	if is_dead: return
	is_dead = true
	
	# Отключаем физику и коллайдеры
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$DetectionArea/CollisionShape2D.set_deferred("disabled", true)
	$AttackArea/CollisionShape2D.set_deferred("disabled", true)
	
	# Проигрываем анимацию смерти
	play_animation("death")
	await sprite.animation_finished
	
	# Останавливаем на последнем кадре
	sprite.stop()
	sprite.frame = sprite.sprite_frames.get_frame_count("death") - 1
	
	# Включаем область лута (только если нода существует)
	if has_node("LootArea"):
		$LootArea/CollisionShape2D.disabled = false
	
	add_to_group("corpses")
	_drop_loot()

func _convert_to_corpse():
	# Останавливаем анимацию
	sprite.stop()
	
	# Создаем новый SpriteFrames с одной текстурой (труп)
	var new_frames = SpriteFrames.new()
	new_frames.add_animation("corpse")
	new_frames.add_frame("corpse", corpse_texture)
	
	# Устанавливаем новые кадры
	sprite.sprite_frames = new_frames
	sprite.play("corpse")
	
	# Включаем область для лута
	add_to_group("corpses")

func _drop_loot():
	if has_node("LootComponent"):
		var loot = $LootComponent.get_loot()
		if loot.size() > 0:
			get_tree().call_group("loot_handlers", "_on_enemy_loot_dropped", loot, global_position)


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
	if distance_to_target > attack_range * 1.1:  # Небольшой гистерезис
		current_state = State.CHASE
		return
	
	velocity = Vector2.ZERO
	if not attack_in_progress and attack_timer.is_stopped():  # Изменено здесь
		_attack_player()

func _attack_player():
	if is_dead or attack_in_progress: return
	
	attack_in_progress = true
	play_animation("attack")
	
	# Ждем момент для нанесения урона (0.3 секунды)
	await get_tree().create_timer(0.3).timeout
	
	if target and _is_target_alive(target) and global_position.distance_to(target.global_position) <= attack_range * 1.1:
		target.take_damage(attack_damage, global_position)
	
	# Ждем окончания анимации атаки
	await sprite.animation_finished
	
	# Сбрасываем анимацию после атаки
	play_animation("idle")  # Или "walk" в зависимости от ситуации
	attack_in_progress = false
	
	# Запускаем кулдаун
	attack_timer.start(attack_cooldown)

	# После кулдауна сразу проверяем состояние
	await attack_timer.timeout
	if not is_dead:
		if target and global_position.distance_to(target.global_position) <= attack_range:
			_attack_player()  # Новая атака
		else:
			current_state = State.CHASE
			play_animation("walk")

func _on_AttackTimer_timeout():  # Изменено имя сигнала
	# Проверяем дистанцию сразу после кулдауна
	if target and global_position.distance_to(target.global_position) <= attack_range:
		_attack_player()
	else:
		current_state = State.CHASE

func play_animation(anim_name: String):
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func _is_target_alive(player):
	return player and player.has_method("take_damage")

func _on_detection_area_body_entered(body):
	if body.is_in_group("player") and _is_target_alive(body):
		target = body

func _on_detection_area_body_exited(body):
	if body == target:
		target = null
		current_state = State.IDLE

func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and _is_target_alive(body) and not target:
		target = body
