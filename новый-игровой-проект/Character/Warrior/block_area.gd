extends Area2D

@export var block_damage_reduction := 0.7  # Уменьшение урона на 70%
@export var stamina_cost_per_second := 20.0
@export var parry_window := 0.2  # Окно парирования в секундах

@onready var collision_shape := $CollisionShape2D
var is_blocking := false
var is_parry_active := false

func enable_block() -> bool:
	var player = get_parent()
	if player.current_stamina <= 0:
		return false
	
	is_blocking = true
	collision_shape.disabled = false
	start_parry_window()
	return true

func disable_block():
	is_blocking = false
	is_parry_active = false
	collision_shape.disabled = true

func start_parry_window():
	is_parry_active = true
	await get_tree().create_timer(parry_window).timeout
	is_parry_active = false

func _process(delta):
	if is_blocking:
		var player = get_parent()
		player.current_stamina -= stamina_cost_per_second * delta
		if player.current_stamina <= 0:
			disable_block()

# Главное исправление - обработка входящего урона
func reduce_damage(base_damage: float) -> float:
	if is_blocking:
		return base_damage * (1.0 - block_damage_reduction)
	return base_damage

func _on_body_entered(body):
	if body.has_method("take_damage") and is_parry_active:
		body.take_damage(0, true)  # Полное парирование
		get_parent().emit_signal("parry_success")
