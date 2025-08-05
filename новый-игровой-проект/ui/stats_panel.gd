extends Panel

@onready var player = get_tree().get_first_node_in_group("player")
@onready var level_label = $VBoxContainer/LevelContainer/LevelValue
@onready var stats_container = $VBoxContainer

func _ready():
	hide()
	if player:
		player.stats_updated.connect(update_stats)
		update_stats()
	else:
		push_error("Player not found in group 'player'")

func update_stats():
	if !is_instance_valid(player):
		push_error("Player instance is invalid")
		return
	
	# Обновляем уровень
	level_label.text = "Уровень: %d" % player.current_level
	
	# Очищаем предыдущие статы (кроме LevelContainer и CloseButton)
	for child in stats_container.get_children():
		if child.name != "LevelContainer" and child.name != "CloseButton":
			child.queue_free()
	
	# Добавляем характеристики с иконками и форматированием
	add_stat_row("❤ Здоровье", "%d/%d" % [player.health, player.base_stats["health"] + player.stat_modifiers["health"]])
	add_stat_row("⚔ Атака", str(player.attack) + " (база: %d)" % player.base_stats["attack"])
	add_stat_row("🛡 Защита", str(player.defense))
	add_stat_row("⚡ Выносливость", "%d/%d" % [player.current_stamina, player.max_stamina])
	add_stat_row("🏃 Скорость", str(player.speed))
	add_stat_row("🍀 Удача", str(player.base_stats["luck"] + player.stat_modifiers["luck"]))
	
	# Добавляем очки прокачки если они есть
	if player.skill_points > 0:
		var points_label = Label.new()
		points_label.text = "Очков улучшений: %d" % player.skill_points
		points_label.add_theme_color_override("font_color", Color.GOLD)
		stats_container.add_child(points_label)

func add_stat_row(name: String, value: String):
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
	
	stats_container.add_child(row)

func _on_close_button_pressed():
	hide()

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
