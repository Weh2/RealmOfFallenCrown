extends StaticBody2D

@export var item: InvItem
var player = null


func _on_interactable_area_body_entered(body: Node2D) -> void:
	if body.has_mathod("Player"):
		player = body
		playercollect()

func playercollect():
	player.collect(item)
