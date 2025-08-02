extends Node2D

var main_menu_instance = null
var pause_menu_instance = null
var game_started = false

func _ready():
	# Деактивируем игровые объекты при старте
	_set_game_objects_active(false)
	
	# Создаем CanvasLayer для меню, если его нет
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 200  # Чтобы меню было поверх всего
	add_child(canvas_layer)
	canvas_layer.name = "MenuLayer"
	
	# Показываем главное меню
	show_main_menu()
	set_process_input(false)

func _set_game_objects_active(active: bool):
	# Управляем состоянием игровых объектов (Butcher, Warrior, PrisonRoom)
	for child in get_children():
		if child.name != "MenuLayer":  # Пропускаем слой с меню
			child.set_process(active)
			child.set_physics_process(active)
			child.visible = active

func show_main_menu():
	main_menu_instance = preload("res://ui/main_menu.tscn").instantiate()
	get_node("MenuLayer").add_child(main_menu_instance)
	main_menu_instance.connect("start_game", _on_start_game)
	main_menu_instance.connect("exit_game", _on_exit_game)

func _on_start_game():
	# Удаляем меню
	if main_menu_instance:
		main_menu_instance.queue_free()
	
	# Активируем игровые объекты
	_set_game_objects_active(true)
	
	# Включаем обработку ввода
	set_process_input(true)
	game_started = true

func _on_exit_game():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("ui_cancel") and game_started:
		if pause_menu_instance == null:
			pause_menu_instance = preload("res://ui/pause_menu.tscn").instantiate()
			get_node("MenuLayer").add_child(pause_menu_instance)
			pause_menu_instance.connect("continue_game", _on_continue_game)
			pause_menu_instance.connect("exit_game", _on_exit_game)
			pause_menu_instance.show_menu()

func _on_continue_game():
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null

func _on_exit_to_menu():
	# Возврат в главное меню
	_set_game_objects_active(false)
	game_started = false
	show_main_menu()
	set_process_input(false)
