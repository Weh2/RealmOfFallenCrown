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
@onready var attack_timer := $AttackTimer

# Состояния
var target = null
var can_attack := true
var is_dead := false

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
	
	# 1. Останавливаем все процессы
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$DetectionArea/CollisionShape2D.set_deferred("disabled", true)
	$AttackArea/CollisionShape2D.set_deferred("disabled", true)
	
	# 2. Проигрываем анимацию смерти ОДИН РАЗ
	sprite.play("death")
	
	# 3. Ждем завершения анимации
	await sprite.animation_finished
	
	
	# 5. Активируем лут
	add_to_group("corpses")
	_drop_loot()

func _convert_to_corpse():
	sprite.stop()
	sprite.sprite_frames = null  # Отключаем анимации
	sprite.texture = corpse_texture
	$LootArea/CollisionShape2D.disabled = false
	add_to_group("corpses")

func _drop_loot():
	if has_node("LootComponent"):
		var loot = $LootComponent.get_loot()
		if loot.size() > 0:
			get_tree().call_group("loot_handlers", "_on_enemy_loot_dropped", loot, global_position)

func _physics_process(delta):
	if is_dead: return
	
	if not target:
		play_animation("idle")
		return
	
	if not _is_target_alive(target):
		target = null
		return
	
	var direction = (target.global_position - global_position).normalized()
	var distance_to_target = global_position.distance_to(target.global_position)
	
	if distance_to_target > attack_range:
		velocity = direction * speed
		move_and_slide()
		play_animation("walk")
		sprite.flip_h = direction.x < 0
	else:
		velocity = Vector2.ZERO
		if can_attack:
			_attack_player()

func _attack_player():
	if is_dead: return  # Добавляем проверку на смерть
	
	can_attack = false
	play_animation("attack")
	
	if target and target.has_method("take_damage"):
		await sprite.animation_finished
		target.take_damage(attack_damage, global_position)
	
	# Создаем временный таймер вместо использования ноды
	var temp_timer = get_tree().create_timer(attack_cooldown)
	await temp_timer.timeout
	
	if not is_dead:  # Проверяем, не умер ли враг за время ожидания
		can_attack = true

func play_animation(anim_name: String):
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func _is_target_alive(player):
	return player and player.has_method("take_damage")

# Сигналы областей остаются без изменений
func _on_detection_area_body_entered(body):
	if body.is_in_group("player") and _is_target_alive(body):
		target = body

func _on_detection_area_body_exited(body):
	if body == target:
		target = null

func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and _is_target_alive(body) and not target:
		target = body
