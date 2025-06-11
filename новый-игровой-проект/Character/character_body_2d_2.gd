extends CharacterBody2D

# Движение
@export var speed = 300.0
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var camera = $Camera2D

# Компонент здоровья
@onready var health_component = $HealthComponent

# Параметры тряски камеры
@export var shake_power: float = 5.0
@export var shake_duration: float = 0.5

# Флаги состояния
var is_flashing := false

# Сигналы
signal health_changed(new_health)
signal died

func _ready():
	# Инициализация здоровья
	if health_component:
		health_component.max_health = 100  # Устанавливаем начальное значение
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_death)
	else:
		push_error("HealthComponent not found!")

func _physics_process(delta):
	# Движение
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	move_and_slide()

	# Анимации
	if velocity.length() > 0:
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				animation_player.play("walk_right")
			else:
				animation_player.play("walk_left")
		else:
			if velocity.y > 0:
				animation_player.play("walk_down")
			else:
				animation_player.play("walk_up")
	else:
		animation_player.play("idle")

# Обработчик изменения здоровья
func _on_health_changed(current: float, max_health: float):
	# Визуальные эффекты при получении урона
	if current < health_component.current_health:
		flash_sprite(Color.RED, 0.1, 3)
		apply_knockback()
		camera.apply_shake(shake_power, shake_duration)
	
	health_component.current_health = current
	health_changed.emit(current)

# Обработчик смерти
func _on_death():
	died.emit()
	animation_player.play("death")
	set_physics_process(false)
	camera.apply_shake(shake_power * 2, shake_duration * 1.5)
	await flash_sprite(Color.DARK_RED, 0.2, 5)
	await animation_player.animation_finished
	queue_free()

# Мигание спрайта
func flash_sprite(color: Color, duration: float, times: int = 1):
	if is_flashing:
		return
		
	is_flashing = true
	for i in times:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", color, duration)
		tween.tween_property(sprite, "modulate", Color.WHITE, duration)
		await tween.finished
	is_flashing = false

# Отбрасывание
func apply_knockback(power: float = 200.0):
	velocity = -velocity.normalized() * power
	move_and_slide()

# Внешний интерфейс для работы с здоровьем
func take_damage(damage: int):
	if health_component:
		health_component.take_damage(damage)
	else:
		push_error("Cannot take damage - HealthComponent missing!")

func heal(amount: int):
	if health_component:
		health_component.heal(amount)
	else:
		push_error("Cannot heal - HealthComponent missing!")

func set_invincible(time: float):
	if health_component:
		health_component.set_invincible(time)
	else:
		push_error("Cannot set invincibility - HealthComponent missing!")
