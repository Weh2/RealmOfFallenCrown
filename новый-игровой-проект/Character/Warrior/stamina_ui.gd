extends CanvasLayer

@export var max_value: float = 100.0
var current_value: float = 100.0

@onready var progress_bar: ProgressBar = $ProgressBar

func setup(max_stamina: float):
	max_value = max_stamina
	current_value = max_value
	configure_style()
	update_progress()

func configure_style():
	var theme = Theme.new()
	
	# Background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	bg_style.set_corner_radius_all(5)
	theme.set_stylebox("background", "ProgressBar", bg_style)
	
	# Fill style
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.2)
	fill_style.set_corner_radius_all(5)
	theme.set_stylebox("fill", "ProgressBar", fill_style)
	
	progress_bar.theme = theme
	progress_bar.max_value = max_value

func update_progress():
	if not is_instance_valid(progress_bar):
		return
	
	progress_bar.value = current_value
	
	var fill_style = progress_bar.get_theme_stylebox("fill").duplicate()
	
	if current_value < max_value * 0.3:
		fill_style.bg_color = Color(0.8, 0.2, 0.2)
	elif current_value < max_value * 0.6:
		fill_style.bg_color = Color(0.8, 0.8, 0.2)
	else:
		fill_style.bg_color = Color(0.2, 0.8, 0.2)
	
	progress_bar.add_theme_stylebox_override("fill", fill_style)

func set_stamina(value: float):
	current_value = clamp(value, 0, max_value)
	update_progress()
