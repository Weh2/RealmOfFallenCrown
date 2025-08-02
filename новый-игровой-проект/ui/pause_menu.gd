extends CanvasLayer

signal continue_game
signal exit_game

func _ready():
	visible = false

func _on_continue_button_pressed():
	emit_signal("continue_game")
	queue_free()

func _on_exit_button_pressed():
	emit_signal("exit_game")

func show_menu():
	visible = true
