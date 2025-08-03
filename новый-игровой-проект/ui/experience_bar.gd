extends Control

@onready var xp_bar: TextureProgressBar = $XPBar
@onready var xp_text: Label = $XPText
@onready var level_label: Label = $LevelLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var player: Node

func _ready():
	# Ждем появления игрока
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.xp_gained.connect(_on_xp_gained)
		player.level_up.connect(_on_level_up)
		
		# Инициализируем значения
		xp_bar.max_value = player.xp_to_level_up
		xp_bar.value = player.current_xp
		xp_text.text = "%d/%d XP" % [player.current_xp, player.xp_to_level_up]
		level_label.text = "Lv. %d" % player.current_level
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
	# Обновляем уровень
	level_label.text = "Lv. %d" % new_level
	
	# Сбрасываем прогресс-бар
	xp_bar.max_value = player.xp_to_level_up
	xp_bar.value = player.current_xp
	xp_text.text = "%d/%d XP" % [player.current_xp, player.xp_to_level_up]
	

	
