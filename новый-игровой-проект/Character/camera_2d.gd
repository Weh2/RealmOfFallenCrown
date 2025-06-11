extends Camera2D

var shake_amount: float = 0.0
var shake_duration: float = 0.0
var original_offset: Vector2

func _ready():
	original_offset = offset

func _process(delta):
	if shake_duration > 0:
		shake_duration -= delta
		offset = original_offset + Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		if shake_duration <= 0:
			offset = original_offset

# Функция для запуска тряски
func apply_shake(power: float, duration: float):
	shake_amount = power
	shake_duration = duration
