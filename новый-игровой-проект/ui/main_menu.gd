extends CanvasLayer

signal start_game
signal exit_game

func _ready():
	visible = true

func _on_play_button_pressed():
	emit_signal("start_game")
	queue_free() # Удаляем меню после начала игры

func _on_exit_button_pressed():
	emit_signal("exit_game")
