extends CanvasLayer

@onready var health_bar: TextureProgressBar = $UIRoot/HealthBar


func _ready():
	if not _validate_nodes():
		return
	
	configure_theme()
	update_health(100, 100)  # Инициализация с дефолтными значениями

func _validate_nodes() -> bool:
	if not health_bar:
		push_error("HealthBar not found! Check path: UIRoot/HealthBar")
		return false
	return true

func configure_theme():
	var theme = Theme.new()
	
	# Стиль фона (тёмный полупрозрачный)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0, 0, 0.85)
	bg_style.set_corner_radius_all(5)
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.3, 0, 0)
	theme.set_stylebox("background", "ProgressBar", bg_style)
	
	# Базовый стиль заполнения
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.2, 0.2)  # Красный
	fill_style.set_corner_radius_all(5)
	theme.set_stylebox("fill", "ProgressBar", fill_style)
	
	health_bar.theme = theme

func update_health(current: float, max_hp: float):
	if not health_bar:
		return
	
	health_bar.max_value = max_hp
	health_bar.value = current
	
	# Динамическое изменение цвета
	var fill_style = health_bar.get_theme_stylebox("fill").duplicate()
	var health_ratio = current / max_hp
	
	if health_ratio < 0.25:       # Критический уровень
		fill_style.bg_color = Color(0.9, 0.1, 0.1)    # Ярко-красный
	elif health_ratio < 0.5:      # Низкий уровень
		fill_style.bg_color = Color(0.9, 0.4, 0.1)    # Оранжево-красный
	elif health_ratio < 0.75:     # Средний уровень
		fill_style.bg_color = Color(0.9, 0.7, 0.1)    # Жёлто-оранжевый
	else:                         # Высокий уровень
		fill_style.bg_color = Color(0.2, 0.8, 0.2)    # Зелёный
	
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
