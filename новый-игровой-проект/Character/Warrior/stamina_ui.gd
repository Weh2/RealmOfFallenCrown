extends CanvasLayer

signal stamina_changed(new_value)  # Сигнал при изменении стамины
signal stamina_depleted           # Сигнал при полном истощении стамины

@export var max_value: float = 100.0
var current_value: float = 100.0:
	set(value):
		var new_value = clamp(value, 0, max_value)
		if new_value != current_value:
			current_value = new_value
			update_display(current_value, max_value)
			stamina_changed.emit(current_value)
			if current_value <= 0:
				stamina_depleted.emit()

@onready var progress_bar: ProgressBar = $UIRoot/StaminaBar
@onready var stamina_label: Label = $UIRoot/StaminaBar.get_node("Label") if $UIRoot/StaminaBar.has_node("Label") else null

func _ready():
	if not _validate_nodes():
		return
	
	configure_theme()
	update_display(max_value, max_value)  # Инициализация с полной стаминой

func _validate_nodes() -> bool:
	if not progress_bar:
		push_error("StaminaBar not found! Available nodes: ", $UIRoot.get_children())
		return false
	return true

func configure_theme():
	var theme = Theme.new()
	
	# Стиль фона (тёмно-синий с прозрачностью)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.25, 0.85)
	bg_style.set_corner_radius_all(5)
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.2, 0.2, 0.4)
	theme.set_stylebox("background", "ProgressBar", bg_style)
	
	# Базовый стиль заполнения (голубой)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.3, 0.6, 0.9)
	fill_style.set_corner_radius_all(5)
	theme.set_stylebox("fill", "ProgressBar", fill_style)
	
	progress_bar.theme = theme
	progress_bar.max_value = max_value

func setup(max_stamina: float):
	max_value = max_stamina
	current_value = max_stamina  # Автоматически вызовет update_display через setter

func update_display(value: float, max_value: float):
	if not progress_bar:
		return
	
	progress_bar.max_value = max_value
	progress_bar.value = value
	
	# Динамическое изменение цвета
	var fill_style = progress_bar.get_theme_stylebox("fill").duplicate()
	var stamina_percent = value / max_value
	
	if stamina_percent < 0.25:       # Критический уровень
		fill_style.bg_color = Color(0.9, 0.2, 0.3)    # Красный
	elif stamina_percent < 0.5:      # Низкий уровень
		fill_style.bg_color = Color(0.9, 0.7, 0.2)    # Оранжевый
	elif stamina_percent < 0.75:     # Средний уровень
		fill_style.bg_color = Color(0.4, 0.8, 0.9)    # Светло-голубой
	else:                            # Высокий уровень
		fill_style.bg_color = Color(0.2, 0.5, 0.9)    # Голубой
	
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Обновляем текст лейбла, если он существует
	if stamina_label:
		stamina_label.text = "%d/%d" % [value, max_value]
		# Динамическое изменение цвета текста
		if stamina_percent < 0.25:
			stamina_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		else:
			stamina_label.add_theme_color_override("font_color", Color(1, 1, 1))

func set_stamina(value: float):
	current_value = clamp(value, 0, max_value)  # Автоматически вызовет все обновления через setter
