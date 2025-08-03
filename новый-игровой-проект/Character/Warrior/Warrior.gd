extends CharacterBody2D

@export var speed = 200.0
@onready var sprite = $AnimatedSprite2D  # Изменено с Sprite2D на AnimationSprite2D
@onready var camera = $Camera2D
@onready var health_component = $HealthComponent
@onready var health_ui = $HealthUI
@onready var weapon = $Weapon
@onready var stamina_ui = $StaminaUI
@onready var block_area = $BlockArea
@export var inv: Inv
@onready var hotbar_ui = $hotbar_ui
@onready var loot_detection_area = $LootDetectionArea
@export var shake_power: float = 5.0
@export var shake_duration: float = 0.5
var invincible := false
@export var loot_ui_scene: PackedScene = preload("res://scripts/LootUI.tscn")
var loot_ui: Panel = null  


var current_loot_target: Node = null 

# Система прокачки
@export var max_level: int = 50
@export var xp_to_level_up: int = 100
var current_level: int = 1
var current_xp: int = 0
var skill_points: int = 0



# Базовые характеристики
@export var base_stats = {
	"health": 100,
	"attack": 10,
	"defense": 0,
	"stamina": 100,
	"speed": 300,
	"luck": 5
}

# Текущие модификаторы
var stat_modifiers = {
	"health": 0,
	"attack": 0,
	"defense": 0,
	"stamina": 0,
	"speed": 0,
	"luck": 0
}

signal xp_gained(amount: int, current_xp: int, required_xp: int)
signal level_up(new_level: int)

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
@export var dash_duration := 0.20
@export var dash_cooldown := 0.8
@export var dash_stamina_cost := 25.0
var is_dashing := false
var can_dash := true

signal health_changed(new_health)
signal stamina_changed(new_stamina)
signal died


func _ready():
	add_to_group("loot_handlers")
	if loot_ui_scene:
		loot_ui = loot_ui_scene.instantiate()
		add_child(loot_ui)
		loot_ui.hide()
		
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.loot_opened.connect(loot_ui.show_loot)
		
	call_deferred("_update_equipment_stats")
	var old_inv = get_node_or_null("/root/InvUI")
	if old_inv:
		old_inv.queue_free()

	var inv_ui = $Inv_UI
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

	if loot_ui_scene:
		loot_ui = loot_ui_scene.instantiate()
		add_child(loot_ui)
		loot_ui.hide()
	if has_node("LootDetectionArea"):
		loot_detection_area.body_entered.connect(_on_loot_detection_area_body_entered)
		loot_detection_area.body_exited.connect(_on_loot_detection_area_body_exited)

	if inv:
		inv.equipment_updated.connect(_update_equipment_stats)
	else:
		push_error("Inventory not initialized!")

func gain_xp(amount: int):
	if current_level >= max_level:
		return
	
	current_xp += amount
	emit_signal("xp_gained", amount, current_xp, xp_to_level_up)
	
	# Проверка уровня
	if current_xp >= xp_to_level_up:
		_level_up()

func _level_up():
	current_level += 1
	skill_points += 3  # Даем 3 очка навыков за уровень
	current_xp = max(current_xp - xp_to_level_up, 0)
	xp_to_level_up = int(xp_to_level_up * 1.2)  # Увеличиваем требуемый опыт
	
	# Небольшое автоулучшение характеристик
	base_stats.health += 5
	base_stats.stamina += 3
	base_stats.attack += 1
	
	emit_signal("level_up", current_level)
	_update_equipment_stats()  # Обновляем статы

func upgrade_stat(stat: String, amount: int = 1):
	if skill_points >= amount:
		stat_modifiers[stat] += amount
		skill_points -= amount
		_update_equipment_stats()
		return true
	return false



func get_loot_ui() -> Panel:
	return loot_ui


func _on_loot_detection_area_body_entered(body):
	print("Тело вошло в зону лута:", body.name, 
		  " can_be_looted:", body.can_be_looted if "can_be_looted" in body else "N/A",
		  " слои:", body.collision_layer)
	

	if body.is_in_group("corpses"):
		if body.has_method("open_loot") or (body.has_node("LootComponent") and body.can_be_looted):
			current_loot_target = body

func _on_loot_detection_area_body_exited(body):
	print("Тело вышло:", body.name, " группы:", body.get_groups())
	if body == current_loot_target and not body.can_be_looted:
		current_loot_target = null

func _update_equipment_stats():
	print("DEBUG: Вызов _update_equipment_stats")
	if not inv or inv.equipment_slots.size() < 8:
		return
	
	# Базовые характеристики + модификаторы от прокачки
	var base_stats = {
		"health": 100 + stat_modifiers["health"],
		"attack": 10 + stat_modifiers["attack"],
		"defense": 0 + stat_modifiers["defense"],
		"stamina": 100 + stat_modifiers["stamina"],
		"speed": 300 + stat_modifiers["speed"]
	}
	
	# Бонусы от экипировки
	var bonuses = {
		"health": 0,
		"attack": 0,
		"defense": 0,
		"stamina": 0,
		"speed": 0
	}
	
	# Суммируем бонусы от всей экипировки
	for slot in inv.equipment_slots:
		if slot and slot.item:
			for stat in bonuses:
				bonuses[stat] += slot.item.stats.get(stat, 0)
	
	# Применяем характеристики к компонентам
	if health_component:
		health_component.max_health = base_stats["health"] + bonuses["health"]
		health_component.current_health = min(health_component.current_health, health_component.max_health)
		health_ui.update_health(health_component.current_health, health_component.max_health)
	
	# Обновляем оружие
	var weapon_slot = inv.equipment_slots[InvItem.ItemType.WEAPON]
	if weapon_slot and weapon_slot.item:
		if has_node("Weapon") and $Weapon.has_method("update_weapon"):
			$Weapon.update_weapon(weapon_slot.item)
		else:
			push_error("Weapon node or method missing!")
	else:
		if has_node("Weapon") and $Weapon.has_method("unequip_weapon"):
			$Weapon.unequip_weapon()
	
	# Стамина и скорость
	max_stamina = base_stats["stamina"] + bonuses["stamina"]
	current_stamina = min(current_stamina, max_stamina)
	speed = base_stats["speed"] + bonuses["speed"]
	
	stamina_ui.set_stamina(current_stamina)
	
	print("=== Статы после обновления ===")
	print("Здоровье: ", health_component.max_health)
	print("Урон: ", $Weapon.get_attack_damage())
	print("Стамина: ", max_stamina)
	print("Скорость: ", speed)
	print("Защита: ", base_stats["defense"] + bonuses["defense"])

func _physics_process(delta):
	if weapon.is_attacking() or is_dashing:
		move_and_slide()
		return
	
	# Handle blocking
	var new_blocking_state = Input.is_action_pressed("block") and current_stamina > 0
	if new_blocking_state != is_blocking:
		is_blocking = new_blocking_state
		block_area.is_blocking = is_blocking
		if is_blocking:
			sprite.play("block")
		else:
			sprite.play("idle")
	
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
			sprite.play("walk")  # Используем одну анимацию ходьбы
		else:
			sprite.play("idle")

func _input(event):
	if event.is_action_pressed("interact"):
		var nearest_lever = get_meta("near_lever") if has_meta("near_lever") else null
		if nearest_lever:
			nearest_lever.interact()
		for area in $LootDetectionArea.get_overlapping_areas():
			if area.is_in_group("lootable") and area.has_method("interact"):
				area.interact()
				return 
		if loot_ui.visible:
			loot_ui.hide()
			return
			
		if current_loot_target and current_loot_target.can_be_looted:
			var distance = global_position.distance_to(current_loot_target.global_position)
			var max_loot_distance = 100.0
			
			if distance <= max_loot_distance:
				var loot = current_loot_target.open_loot()
				if loot:
					loot_ui.show_loot(loot, current_loot_target)
			else:
				print("Слишком далеко для лута!")
				current_loot_target = null
			
	if event.is_action_pressed("hotbar_1"):
		inv.use_hotbar_slot(0, self)
	elif event.is_action_pressed("hotbar_2"):
		inv.use_hotbar_slot(1, self)
	
	if event.is_action_pressed("dash") and can_dash and current_stamina >= dash_stamina_cost and !is_blocking:
		start_dash()
	if event.is_action_pressed("attack") and !is_blocking and !is_dashing:
		var attack_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if attack_dir == Vector2.ZERO:
			attack_dir = Vector2.RIGHT if !sprite.flip_h else Vector2.LEFT
		weapon.update_direction(attack_dir.x < 0)
		weapon.start_attack(attack_dir)
	
func _on_loot_opened(items: Array):
	print("Получен лут:", items)
	if loot_ui:
		loot_ui.show_loot(items)
	else:
		push_error("LootUI не инициализирован")


func start_dash():
	can_dash = false
	is_dashing = true
	current_stamina -= dash_stamina_cost
	
	var dash_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT if !sprite.flip_h else Vector2.LEFT
	
	velocity = dash_direction.normalized() * speed * dash_speed_multiplier
	sprite.play("dash")
	
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
	
	
	
func take_damage(damage: int, source_position: Vector2 = Vector2.ZERO):
	if invincible or is_dashing:
		return
	
	# Рассчитываем базовую защиту (характеристика + бонусы экипировки)
	var total_defense = stat_modifiers["defense"]
	for slot in inv.equipment_slots:
		if slot and slot.item:
			total_defense += slot.item.stats.get("defense", 0)
	
	# Применяем защиту (минимум 1 урона)
	var damage_after_defense = max(1, damage - total_defense)
	
	# Дополнительное снижение урона при блоке
	if is_blocking and check_block_direction(source_position):
		damage_after_defense = int(damage_after_defense * (1.0 - block_damage_reduction))
		flash_sprite(Color.ROYAL_BLUE, 0.1, 1)
		camera.apply_shake(shake_power * 0.5, shake_duration * 0.7)
	else:
		flash_sprite(Color.RED, 0.1, 3)
		camera.apply_shake(shake_power, shake_duration)
	
	# Устанавливаем неуязвимость на короткое время
	invincible = true
	get_tree().create_timer(0.5).timeout.connect(func(): invincible = false)
	
	# Наносим урон
	if health_component:
		health_component.take_damage(damage_after_defense)
	
	# Отбрасывание персонажа
	if source_position != Vector2.ZERO:
		var knockback_direction = (global_position - source_position).normalized()
		velocity = knockback_direction * 200
		move_and_slide()
	
	print("Получено урона: ", damage, " | После защиты: ", damage_after_defense)

func check_block_direction(source_position: Vector2) -> bool:
	if source_position == Vector2.ZERO:
		return false
	
	var attack_direction = (source_position - global_position).normalized()
	var block_direction = Vector2(-1 if sprite.flip_h else 1, 0)
	return attack_direction.dot(block_direction) > 0.7

func _on_stamina_depleted():
	is_blocking = false
	block_area.is_blocking = false
	sprite.play("idle")

func _on_health_changed(current: float, max_hp: float):
	health_ui.update_health(current, max_hp)
	health_changed.emit(current)
	

func _on_death():
	died.emit()
	sprite.play("death")
	set_physics_process(false)
	camera.apply_shake(shake_power * 2, shake_duration * 1.5)
	await flash_sprite(Color.DARK_RED, 0.2, 5)
	await sprite.animation_finished
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


func collect(item: InvItem):
	print("Adding item to inventory: ", item.name)
	if inv:
		if item.stackable:
			inv.insert(item)
		else:
			inv.insert(item.duplicate())
		print("Item added to inventory")
	else:
		push_error("Inventory not found!")

func _on_enemy_loot_dropped(items: Array[InvItem], drop_position: Vector2):
	for item in items:
		if global_position.distance_to(drop_position) < 100.0:
			collect(item)
			print("Получен предмет: ", item.name)

func collect_multiple(item: InvItem, quantity: int):
	if not inv:
		return
		
	if item.stackable:
		# Для стакаемых предметов добавляем сразу все количество
		var remaining = quantity
		while remaining > 0:
			var added = inv.insert(item, remaining)
			if added <= 0:  # Если не удалось добавить (нет места)
				break
			remaining -= added
	else:
		# Для нестакаемых - по одному
		for i in range(quantity):
			inv.insert(item.duplicate(), 1)
