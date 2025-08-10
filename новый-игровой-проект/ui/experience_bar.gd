extends Control

@onready var xp_bar: TextureProgressBar = $XPBar
@onready var xp_text: Label = $XPText
@onready var level_label: Label = $LevelLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var player: Node

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.xp_gained.connect(_on_xp_gained)
		player.level_up.connect(_on_level_up)
		
		xp_bar.max_value = player.xp_to_level_up
		xp_bar.value = player.current_xp
		xp_text.text = "%d/%d XP" % [player.current_xp, player.xp_to_level_up]
		level_label.text = "Lv. %d" % player.current_level
		
		if player.current_level >= player.max_level:
			xp_bar.visible = false
			xp_text.text = "MAX LEVEL"
	else:
		push_error("Player not found in group 'player'")

func _on_xp_gained(amount: int, current_xp: int, required_xp: int):
	# Анимация заполнения
	var tween = create_tween()
	tween.tween_property(xp_bar, "value", current_xp, 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# Обновляем текст
	xp_text.text = "%d/%d XP" % [current_xp, required_xp]
	

func _on_level_up(new_level: int):
	level_label.text = "Lv. %d" % new_level
	
	# 1. Заполняем до конца текущую шкалу
	var tween = create_tween()
	tween.tween_property(xp_bar, "value", xp_bar.max_value, 0.3)
	await tween.finished
	
	# 2. Эффект "сброса" - шкала уходит вправо
	var slide_tween = create_tween()
	slide_tween.tween_property(xp_bar, "value", 0, 0.2)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	slide_tween.parallel().tween_property(xp_bar, "modulate:a", 0, 0.2)
	await slide_tween.finished
	
	# 3. Обновляем значения
	xp_bar.max_value = player.xp_to_level_up
	xp_bar.value = player.current_xp
	
	# 4. Эффект появления новой шкалы
	xp_bar.modulate.a = 0
	var appear_tween = create_tween()
	appear_tween.tween_property(xp_bar, "modulate:a", 1, 0.3)
	
	# 5. Если есть XP - плавно заполняем
	if player.current_xp > 0:
		var start_value = 0
		xp_bar.value = start_value
		var fill_tween = create_tween()
		fill_tween.tween_property(xp_bar, "value", player.current_xp, 0.5)
	
	xp_text.text = "%d/%d XP" % [player.current_xp, player.xp_to_level_up]
