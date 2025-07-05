extends CharacterBody2D

@export var speed = 300.0
@onready var sprite = $Sprite2D
@onready var movement_animation_player = $AnimationPlayer
@onready var camera = $Camera2D
@onready var health_component = $HealthComponent
@onready var health_ui = $HealthUI
@onready var weapon = $Weapon
@onready var stamina_ui = $StaminaUI
@onready var block_area = $BlockArea
@export var inv: Inv
@onready var hotbar_ui = $HotbarUI

@export var shake_power: float = 5.0
@export var shake_duration: float = 0.5


# Stamina system
@export var max_stamina: float = 100.0
var current_stamina: float = max_stamina:
	set(value):
		current_stamina = clamp(value, 0, max_stamina)
		stamina_ui.set_stamina(current_stamina)
		stamina_changed.emit(current_stamina)
		if current_stamina <= 0:
			_on_stamina_depleted()
			
@export var stamina_regen_rate: float = 15.0
@export var stamina_consumption_rate: float = 25.0
@export var block_damage_reduction: float = 0.7
var is_blocking := false
var is_flashing := false

# Dash system
@export var dash_speed_multiplier := 2.5
@export var dash_duration := 0.20  # Изменено с 0.20 на 0.15 как во втором скрипте
@export var dash_cooldown := 0.8
@export var dash_stamina_cost := 25.0
var is_dashing := false
var can_dash := true

signal health_changed(new_health)
signal stamina_changed(new_stamina)
signal died

func _ready():
	inv.equipment_updated.connect(_update_equipment_stats)
	_update_equipment_stats()
	# Удаляем старый висячий инвентарь
	var old_inv = get_node_or_null("/root/InvUI")
	if old_inv:
		old_inv.queue_free()
	
	# Гарантируем, что используется только правильный инвентарь
	var inv_ui = $Inv_UI  # Или правильный путь к вашему инвентарю
	inv_ui.add_to_group("player_inventory")
	await get_tree().process_frame
	
	health_ui.get_node("UIRoot").position = Vector2(20, 20)
	stamina_ui.get_node("UIRoot").position = Vector2(20, 60)
	
	if health_component:
		health_component.max_health = 100
		health_ui.update_health(health_component.current_health, health_component.max_health)
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_death)
	else:
		push_error("HealthComponent not found!")
	
	current_stamina = max_stamina
	stamina_ui.setup(max_stamina)

func _update_equipment_stats():
	if not inv or inv.equipment_slots.size() < 8:
		return
	
	# Обновляем оружие
	var weapon_slot = inv.equipment_slots[InvItem.ItemType.WEAPON]
	if weapon_slot and weapon_slot.item:
		$Weapon.update_weapon(weapon_slot.item)
		print("Оружие экипировано: ", weapon_slot.item.name)
	else:
		$Weapon.unequip_weapon()
		print("Оружие снято")
	
	# Рассчитываем бонусы
	var bonuses = {
		"attack": 0,
		"defense": 0,
		"health": 0,
		"stamina": 0
	}
	
	for slot in inv.equipment_slots:
		if slot and slot.item:
			for stat in bonuses:
				bonuses[stat] += slot.item.stats.get(stat, 0)
	
	# Применяем бонусы
	if health_component:
		var new_max_health = 100 + bonuses["health"]
		if health_component.max_health != new_max_health:
			var health_percent = health_component.current_health / health_component.max_health
			health_component.max_health = new_max_health
			health_component.current_health = health_percent * new_max_health
			print("Макс. здоровье обновлено: ", new_max_health)
	
	max_stamina = 100 + bonuses["stamina"]
	current_stamina = min(current_stamina, max_stamina)
	print("Бонусы применены: ", bonuses)

func _physics_process(delta):
	if weapon.is_attacking() or is_dashing:
		move_and_slide()
		return
	
	# Handle blocking
	var new_blocking_state = Input.is_action_pressed("block") and current_stamina > 0
	if new_blocking_state != is_blocking:
		is_blocking = new_blocking_state
		block_area.is_blocking = is_blocking
		if is_blocking and movement_animation_player.has_animation("block"):
			movement_animation_player.play("block")
		elif not is_blocking:
			movement_animation_player.play("idle")
	
	# Stamina management
	if is_blocking:
		current_stamina = max(current_stamina - stamina_consumption_rate * delta, 0)
		if current_stamina <= 0:
			is_blocking = false
			block_area.is_blocking = false
	else:
		current_stamina = min(current_stamina + stamina_regen_rate * delta, max_stamina)
	
	# Movement only when not blocking and not dashing
	if !is_blocking and !is_dashing:
		var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		if input_direction.x != 0:
			sprite.flip_h = input_direction.x < 0
			$Weapon.update_direction(input_direction.x < 0)
		
		velocity = input_direction * speed   
		move_and_slide()
		
		if velocity.length() > 0:
			if abs(velocity.x) > abs(velocity.y):
				movement_animation_player.play("walk_right" if velocity.x > 0 else "walk_left")
			else:
				movement_animation_player.play("walk_down" if velocity.y > 0 else "walk_up")
		elif movement_animation_player.has_animation("idle"):
			movement_animation_player.play("idle")



func _input(event):
	if event.is_action_pressed("hotbar_1"):
		inv.use_hotbar_slot(0, self)
	elif event.is_action_pressed("hotbar_2"):
		inv.use_hotbar_slot(1, self)
	
	if event.is_action_pressed("dash") and can_dash and current_stamina >= dash_stamina_cost and !is_blocking:
		start_dash()
	elif event.is_action_pressed("attack") and !is_blocking and !is_dashing:
		weapon.start_attack(velocity)
	
func start_dash():
	can_dash = false
	is_dashing = true
	current_stamina -= dash_stamina_cost
	
	var dash_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT if !sprite.flip_h else Vector2.LEFT
	
	velocity = dash_direction.normalized() * speed * dash_speed_multiplier
	if movement_animation_player.has_animation("dash"):
		movement_animation_player.play("dash")
	
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func take_damage(damage: int, source_position: Vector2 = Vector2.ZERO):
	if is_dashing:  # Полная неуязвимость во время дэша (как во втором скрипте)
		return
	
	if is_blocking and check_block_direction(source_position):
		damage = int(damage * (1.0 - block_damage_reduction))  # Упрощенный расчет урона как во втором скрипте
		flash_sprite(Color.ROYAL_BLUE, 0.1, 1)
		camera.apply_shake(shake_power * 0.5, shake_duration * 0.7)
	else:
		flash_sprite(Color.RED, 0.1, 3)
		camera.apply_shake(shake_power, shake_duration)
	
	if health_component:
		health_component.take_damage(damage)
	
	# Отбрасывание
	if source_position != Vector2.ZERO:
		var knockback_direction = (global_position - source_position).normalized()
		velocity = knockback_direction * 200
		move_and_slide()

func check_block_direction(source_position: Vector2) -> bool:
	if source_position == Vector2.ZERO:
		return false
	
	var attack_direction = (source_position - global_position).normalized()
	var block_direction = Vector2(-1 if sprite.flip_h else 1, 0)
	return attack_direction.dot(block_direction) > 0.7

func _on_stamina_depleted():
	is_blocking = false
	block_area.is_blocking = false
	if movement_animation_player.has_animation("idle"):
		movement_animation_player.play("idle")

func _on_health_changed(current: float, max_hp: float):
	health_ui.update_health(current, max_hp)
	health_changed.emit(current)
	

func _on_death():
	died.emit()
	if movement_animation_player.has_animation("death"):
		movement_animation_player.play("death")
	set_physics_process(false)
	camera.apply_shake(shake_power * 2, shake_duration * 1.5)
	await flash_sprite(Color.DARK_RED, 0.2, 5)
	if movement_animation_player.has_animation("death"):
		await movement_animation_player.animation_finished
	queue_free()

func flash_sprite(color: Color, duration: float, times: int = 1):
	if is_flashing or not sprite:
		return
		
	is_flashing = true
	for i in times:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", color, duration)
		tween.tween_property(sprite, "modulate", Color.WHITE, duration)
		await tween.finished
	is_flashing = false

func heal(amount: int):
	if health_component:
		health_component.heal(amount)

func set_invincible(time: float):
	if health_component:
		health_component.set_invincible(time)


func collect(item):
	inv.insert(item)
