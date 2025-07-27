extends StaticBody2D

signal interact_called  # Новый сигнал

@onready var interaction_area = $InteractionArea
var player_in_range = false

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		body.set_meta("near_lever", self)

func _on_body_exited(body):
	if body.is_in_group("player") and body.get_meta("near_lever") == self:
		player_in_range = false
		body.remove_meta("near_lever")

func interact():
	if player_in_range:
		emit_signal("interact_called")  # Генерируем сигнал вместо прямого вызова
		print("Рычаг активирован")
