extends Panel

@onready var player = get_tree().get_first_node_in_group("player")
@onready var level_label = $VBoxContainer/LevelContainer/LevelValue
@onready var stats_container = $VBoxContainer
@onready var upgrade_button = $UpgradeButton
@onready var stat_tooltip = preload("res://ui/StatTooltip.tscn").instantiate()


func _ready():
	hide()
	if player:
		player.stats_updated.connect(update_stats)
		player.level_up.connect(_on_player_level_up)
		update_stats()
	add_child(stat_tooltip)
	stat_tooltip.hide()


func _on_player_level_up(_new_level: int):
	# При повышении уровня обновляем кнопку
	upgrade_button.disabled = player.skill_points <= 0
	update_stats()

func update_stats():
	if !player: return
	
	# Обновляем состояние кнопки улучшений
	upgrade_button.disabled = player.skill_points <= 0
	upgrade_button.visible = player.skill_points > 0  # Скрываем если нет очков
	
	level_label.text = "Уровень: %d" % player.current_level
	
	# Очищаем предыдущие статы (кроме LevelContainer и кнопок)
	for child in stats_container.get_children():
		if child.name not in ["LevelContainer", "CloseButton", "UpgradeButton"]:
			child.queue_free()
	
	# Основные характеристики (с проверкой health_component)
	var current_health = player.health if !player.health_component else player.health_component.current_health
	var max_health = player.health if !player.health_component else player.health_component.max_health
	
	add_stat_row("❤ Здоровье", "%d/%d" % [current_health, max_health])
	add_stat_row("⚔ Атака", str(player.attack))
	add_stat_row("🛡 Броня", str(player.armor))
	add_stat_row("⚡ Выносливость", "%d/%d" % [player.current_stamina, player.max_stamina])
	
	# Производные характеристики
	var physical_defense = (player.resistances["physical"]["from_stats"] + player.resistances["physical"]["from_armor"]) * 100
	add_stat_row("🛡 Физ. защита", "%.1f%%" % physical_defense)
	add_stat_row("☠ Сопр. ядам", "%.1f%%" % (player.resistances["poison"] * 100))
	add_stat_row("🔮 Сопр. магии", "%.1f%%" % (player.resistances["magic"] * 100))
	
	# Боевые показатели
	add_stat_row("🗡 Скорость атаки", "+%.1f%%" % player.get_stat_bonus("attack_speed"))
	add_stat_row("🎯 Шанс крита", "%.1f%%" % player.get_stat_bonus("crit_chance"))
	add_stat_row("💥 Крит. урон", "+%.1f%%" % player.get_stat_bonus("crit_damage"))
	add_stat_row("⏱ Перезарядка", "-%.1f%%" % player.get_stat_bonus("cooldown_reduction"))

func add_stat_row(name: String, value: String, bonus: String = "", stat_name: String = ""):
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	
	if bonus != "":
		var bonus_label = Label.new()
		bonus_label.text = " (+%s)" % bonus
		bonus_label.modulate = Color.GREEN_YELLOW
		row.add_child(bonus_label)
	
	# Добавляем обработчики для подсказки, если указан stat_name
	if stat_name != "":
	# Создаем локальную копию переменной для использования в лямбде
		var tooltip_stat_name = stat_name
	
	# Обработка наведения мыши
		row.mouse_entered.connect(func():
			stat_tooltip.display(tooltip_stat_name)
		# Позиционируем подсказку над строкой
			var pos = row.get_global_rect().position
			stat_tooltip.position = pos + Vector2(0, -stat_tooltip.size.y - 5)
	)
	
	# Обработка ухода мыши
	row.mouse_exited.connect(func():
		stat_tooltip.hide()
	)
	
	stats_container.add_child(row)



func _on_close_button_pressed():
	hide()

func _on_upgrade_button_pressed():
	$UpgradePanel.show()
	$UpgradePanel.update_display()

func _input(event):
	if event.is_action_pressed("stats_panel"):
		if visible:
			hide()
		else:
			if is_instance_valid(player):
				update_stats()
				show()
			else:
				push_error("Cannot show stats - player is invalid")
