extends Panel

@onready var points_label = $MainContainer/PointsLabel
@onready var stats_container = $MainContainer/StatsContainer
@onready var accept_button = $MainContainer/AcceptButton
@onready var stat_tooltip = preload("res://ui/StatTooltip.tscn").instantiate()

var player: Node
var temp_stats = {}
var temp_points = 0
var is_tooltip_visible := false
var hide_timer: Timer
var current_stat: String = ""

func _ready():
	add_child(stat_tooltip)
	stat_tooltip.hide()
	add_to_group("upgrade_panels")
	
	# Таймер для задержки скрытия
	hide_timer = Timer.new()
	hide_timer.one_shot = true
	hide_timer.timeout.connect(_real_hide_tooltip)
	add_child(hide_timer)
	
	# Обработка наведения на саму подсказку
	stat_tooltip.mouse_entered.connect(_on_tooltip_mouse_entered)
	stat_tooltip.mouse_exited.connect(_on_tooltip_mouse_exited)

func setup(p):  
	player = p
	hide()
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
	
	for child in stats_container.get_children():
		child.queue_free()
	
	add_stat_row("⚔️ Сила", "strength")
	add_stat_row("🏹 Ловкость", "agility")
	add_stat_row("🛡️ Выносливость", "endurance")
	add_stat_row("📖 Интеллект", "intellect")
	
	accept_button.disabled = temp_points > 0

func add_stat_row(name: String, stat: String):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Контейнер для названия + области наведения
	var name_container = Control.new()
	name_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Текст характеристики
	var label = Label.new()
	label.text = "%s (Ур. %d)" % [name, temp_stats[stat]]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Увеличенная область наведения
	var tooltip_area = ColorRect.new()
	tooltip_area.color = Color(0, 0, 0, 0)
	tooltip_area.mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_area.custom_minimum_size = Vector2(200, 40)  # Увеличенная область
	
	# Подключаем сигналы
	tooltip_area.mouse_entered.connect(_show_stat_tooltip.bind(stat, tooltip_area))
	tooltip_area.mouse_exited.connect(_hide_stat_tooltip)
	
	name_container.add_child(label)
	name_container.add_child(tooltip_area)
	
	# Кнопки и значения
	var left_btn = Button.new()
	left_btn.text = "<"
	left_btn.disabled = temp_stats[stat] <= 1
	left_btn.pressed.connect(_on_stat_decreased.bind(stat))
	
	var value_label = Label.new()
	value_label.text = str(temp_stats[stat])
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size.x = 30
	
	var right_btn = Button.new()
	right_btn.text = ">"
	right_btn.disabled = temp_points <= 0
	right_btn.pressed.connect(_on_stat_increased.bind(stat))
	
	hbox.add_child(name_container)
	hbox.add_child(left_btn)
	hbox.add_child(value_label)
	hbox.add_child(right_btn)
	stats_container.add_child(hbox)

func _show_stat_tooltip(stat: String, control: Control):
	# Отменяем скрытие, если оно запланировано
	hide_timer.stop()
	
	# Если уже показываем эту подсказку - ничего не делаем
	if is_tooltip_visible and current_stat == stat:
		return
	
	current_stat = stat
	
	var descriptions = {
		"strength": "[b][color=#ff5555]⚔️ Сила[/color][/b]\n" +
					"• +3% к физическому урону\n" +
					"• +5 к здоровью за уровень\n" +
					"• +1% защита каждые 5 ур.",
		"agility": "[b][color=#55ff55]🏹 Ловкость[/color][/b]\n" +
				   "• +5% скорость атаки каждые 2 ур.\n" +
				   "• +1.5% шанс критического удара\n" +
				   "• +1% шанс уклонения",
		"endurance": "[b][color=#5555ff]🛡️ Выносливость[/color][/b]\n" +
					 "• +10 к выносливости за уровень\n" +
					 "• +2% сопротивление урону\n" +
					 "• -1% получаемый урон",
		"intellect": "[b][color=#aa55ff]📖 Интеллект[/color][/b]\n" +
					 "• +8% урон от способностей\n" +
					 "• -2% время перезарядки\n" +
					 "• +10% длительность эффектов"
	}
	
	var rich_text = stat_tooltip.get_node("RichTextLabel")
	rich_text.text = descriptions.get(stat, "Нет описания")
	
	# Настройка отображения
	rich_text.scroll_active = false
	rich_text.custom_minimum_size = Vector2(300, 150)
	stat_tooltip.reset_size()
	
	# Позиционирование
	stat_tooltip.position = Vector2(200, 500)
	
	# Анимация появления
	stat_tooltip.modulate.a = 0
	stat_tooltip.show()
	is_tooltip_visible = true
	
	var tween = create_tween()
	tween.tween_property(stat_tooltip, "modulate:a", 1.0, 0.2)

func _hide_stat_tooltip():
	# Если курсор перешел на саму подсказку - не скрываем
	if stat_tooltip.get_global_rect().grow(20).has_point(get_global_mouse_position()):
		return
	
	# Ставим задержку перед скрытием
	hide_timer.start(0.3)

func _real_hide_tooltip():
	var tween = create_tween()
	tween.tween_property(stat_tooltip, "modulate:a", 0.0, 0.15)
	await tween.finished
	stat_tooltip.hide()
	is_tooltip_visible = false
	current_stat = ""

func _on_tooltip_mouse_entered():
	# При наведении на подсказку отменяем таймер скрытия
	hide_timer.stop()

func _on_tooltip_mouse_exited():
	# При уходе с подсказки запускаем скрытие
	_hide_stat_tooltip()

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
	
	for stat in temp_stats:
		var diff = temp_stats[stat] - player.base_stats[stat]
		if diff > 0:
			player.upgrade_stat(stat, diff)
	
	hide()
	player.stats_updated.emit()

func _on_close_button_pressed():
	hide()
