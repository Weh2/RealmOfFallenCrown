extends StaticBody2D

@onready var interaction_area = $InteractionArea
var player_in_range = false

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		body.set_meta("near_lever", self)
		print("Игрок вошел в зону рычага")

func _on_body_exited(body):
	if body.is_in_group("player") and body.get_meta("near_lever") == self:
		player_in_range = false
		body.remove_meta("near_lever")
		print("Игрок вышел из зоны рычага")

func interact():
	if player_in_range:
		var gates = get_tree().get_nodes_in_group("gates")
		for gate in gates:
			if gate.global_position.distance_to(global_position) < 600.0:
				if gate.is_opened:  # Используем свойство is_opened из Gate
					gate.close()
				else:
					gate.open()
				break
