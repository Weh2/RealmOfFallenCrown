extends Node

var inventory: Inv

func _ready():
	inventory = preload("res://ui/inventory/playerinv.tres")
	print("GlobalInventory готов. Инвентарь загружен:", inventory != null)
