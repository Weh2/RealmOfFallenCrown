extends Panel

@onready var points_label = $MainContainer/PointsLabel
@onready var stats_container = $MainContainer/StatsContainer
@onready var accept_button = $MainContainer/AcceptButton

var player: Node
var temp_stats = {}
var temp_points = 0


func _ready():
	add_to_group("upgrade_panels")  # Добавляем в группу для обновлений

func setup(p):  
	player = p
	hide()  # Скрываем по умолчанию
	update_display()


func update_display():
	if !player: 
		player = get_tree().get_first_node_in_group("player")
		if !player: return
	
	temp_points = player.skill_points
	temp_stats = {
		"strength": player.base_stats["strength"],
		"agility": player.base_stats["agility"],
		"endurance": player.base_stats["endurance"],
		"intellect": player.base_stats["intellect"]
	}
	update_ui()

func update_ui():
	points_label.text = "Очки улучшений: %d" % temp_points
	
	# Очищаем предыдущие элементы
	for child in stats_container.get_children():
		child.queue_free()
	
	
	# Создаем панели для каждой характеристики
	add_stat_row("⚔️ Сила", "strength")
	add_stat_row("🏹 Ловкость", "agility")
	add_stat_row("🛡️ Выносливость", "endurance")
	add_stat_row("📖 Интеллект", "intellect")
	
	# Блокируем кнопку "Принять" если есть нераспределенные очки
	accept_button.disabled = temp_points > 0

func add_stat_row(name: String, stat: String):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Название и текущий уровень
	var label = Label.new()
	label.text = "%s (Ур. %d)" % [name, temp_stats[stat]]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Кнопка уменьшения
	var left_btn = Button.new()
	left_btn.text = "<"
	left_btn.disabled = temp_stats[stat] <= 1  # Нельзя уменьшить ниже 1
	left_btn.pressed.connect(_on_stat_decreased.bind(stat))
	
	# Текущее значение
	var value_label = Label.new()
	value_label.text = str(temp_stats[stat])
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size.x = 30
	
	# Кнопка увеличения
	var right_btn = Button.new()
	right_btn.text = ">"
	right_btn.disabled = temp_points <= 0  # Нет очков для улучшения
	right_btn.pressed.connect(_on_stat_increased.bind(stat))
	
	hbox.add_child(label)
	hbox.add_child(left_btn)
	hbox.add_child(value_label)
	hbox.add_child(right_btn)
	stats_container.add_child(hbox)

func _on_stat_increased(stat: String):
	if temp_points > 0:
		temp_stats[stat] += 1
		temp_points -= 1
		update_ui()

func _on_stat_decreased(stat: String):
	if temp_stats[stat] > 1:
		temp_stats[stat] -= 1
		temp_points += 1
		update_ui()

func _on_accept_button_pressed():
	if !player: return
	
	# Применяем изменения
	for stat in temp_stats:
		var diff = temp_stats[stat] - player.base_stats[stat]
		if diff > 0:
			player.upgrade_stat(stat, diff)
	
	hide()
	player.stats_updated.emit()  # Обновляем основной интерфейс
func _on_close_button_pressed():
	# Отмена - просто закрываем без изменений
	hide()
