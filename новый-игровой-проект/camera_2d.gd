extends Camera2D

# Настройки тряски
@export var max_shake_power := 10.0
var shake_amount := 0.0
var shake_duration := 0.0
var original_offset: Vector2

# Слежение за игроком
@export var target: Node2D
@export var follow_speed := 5.0
@export var margin := Vector2(100, 50)



func _ready():
	original_offset = offset
	set_physics_process(true)

func _physics_process(delta):
	# Плавное слежение за целью
	if target:
		var target_pos = target.global_position
		position = position.lerp(target_pos, follow_speed * delta)
	
	# Тряска (если активна)
	if shake_duration > 0:
		shake_duration -= delta
		var current_shake = shake_amount * (shake_duration / max_shake_power)
		offset = original_offset + _get_shake_offset(current_shake)
	else:
		offset = original_offset

# Генерация смещения для тряски
func _get_shake_offset(power: float) -> Vector2:
	var angle = randf_range(0, TAU)
	return Vector2(cos(angle), sin(angle)) * power * randf()

# Улучшенный запуск тряски
func apply_shake(power: float, duration: float):
	shake_amount = min(power, max_shake_power)  # Ограничение мощности
	shake_duration = max(duration, 0.1)  # Минимальная длительность
	
	# Коррекция под наклон камеры
	if target:
		original_offset = (target.global_position - global_position).normalized() * 15
