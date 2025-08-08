extends Panel

@onready var player = get_tree().get_first_node_in_group("player")
@onready var level_label = $VBoxContainer/LevelContainer/LevelValue
@onready var stats_container = $VBoxContainer
@onready var upgrade_button = $VBoxContainer/UpgradeButton

func _ready():
	hide()
	# Удаляем старое подключение, если было
	if player and player.stats_updated.is_connected(update_stats):
		player.stats_updated.disconnect(update_stats)
	
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.stats_updated.connect(update_stats)
		update_stats()

func update_stats():

	
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

func _on_upgrade_button_pressed():
	get_tree().call_group("upgrade_panel", "show")

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
