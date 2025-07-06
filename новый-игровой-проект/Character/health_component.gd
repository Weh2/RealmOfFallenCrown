extends Node

signal health_changed(current: float, max: float)
signal died()

@export var max_health: float = 100.0
var current_health: float
var is_invincible: bool = false

func _ready():
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(damage: float):
	if is_invincible:
		return
	
	current_health = max(current_health - damage, 0)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func die():
	died.emit()

func set_invincible(time: float):
	is_invincible = true
	await get_tree().create_timer(time).timeout
	is_invincible = false

func reset_health(new_max: float):
	var ratio = current_health / max_health
	max_health = new_max
	current_health = min(ratio * new_max, new_max)
	health_changed.emit(current_health, max_health)
