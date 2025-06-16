extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/Label  # Опционально

func _ready():
	configure_style()
	# Инициализация с дефолтными значениями
	update_health(100, 100) 

func configure_style():
	var theme = Theme.new()
	
	# Стиль фона (темно-красный)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0, 0, 0.8)  # RGB: 51, 0, 0
	bg_style.set_corner_radius_all(5)
	theme.set_stylebox("background", "ProgressBar", bg_style)
	
	# Стиль заполнения (базовый красный)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0, 0)  # RGB: 204, 0, 0
	fill_style.set_corner_radius_all(5)
	theme.set_stylebox("fill", "ProgressBar", fill_style)
	
	health_bar.theme = theme

func update_health(current: float, max_hp: float):
	health_bar.max_value = max_hp
	health_bar.value = current
	
	# Динамическое изменение цвета
	var fill_style = health_bar.get_theme_stylebox("fill").duplicate()
	var health_percent = current / max_hp
	
	if health_percent < 0.3:       # Критический уровень
		fill_style.bg_color = Color(0.8, 0, 0)        # Красный
	elif health_percent < 0.6:     # Средний уровень
		fill_style.bg_color = Color(0.8, 0.5, 0)      # Оранжевый
	else:                          # Высокий уровень
		fill_style.bg_color = Color(0.2, 0.8, 0.2)    # Зеленый
	
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Обновляем текст (если Label существует)
	if health_label:
		health_label.text = "HP: %d/%d" % [current, max_hp]
