extends TextureProgressBar

@onready var player: Node
var health_component: Node

func _ready():
	# Ждем готовности сцены
	await get_tree().process_frame
	
	# Получаем игрока
	player = get_node_or_null("/root/Game/Player")
	
	if !player:
		push_error("Player node not found at path: /root/Game/Player")
		return
	
	# Получаем HealthComponent
	health_component = player.get_node_or_null("HealthComponent")
	
	if !health_component:
		push_error("HealthComponent not found on player!")
		return
	
	# Подключаем сигнал
	if health_component.has_signal("health_changed"):
		health_component.health_changed.connect(update_health_bar)
	else:
		push_error("health_changed signal missing in HealthComponent!")
		return
	
	# Инициализируем значения
	max_value = health_component.max_health
	value = health_component.current_health
	update_health_bar(value, max_value)

func update_health_bar(current: float, _max: float):
	if !is_inside_tree():
		return
		
	value = current
	tint_progress = Color.RED if current < max_value * 0.3 else Color.GREEN
