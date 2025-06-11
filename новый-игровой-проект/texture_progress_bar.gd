extends TextureProgressBar

@onready var player: Node = get_node("/root/Game/Player")  # Укажите путь к игроку

func _ready():
	# Подключаем сигнал из HealthComponent
яя	player.health_component.health_changed.connect(update_health_bar)
	max_value = player.health_component.max_health
	value = player.health_component.current_health

# Обновляем полоску при изменении здоровья
func update_health_bar(current: float, _max: float):
	value = current
	# Меняем цвет при низком HP
	if current < max_value * 0.3:
		tint_progress = Color.RED
	else:
		tint_progress = Color.GREEN
