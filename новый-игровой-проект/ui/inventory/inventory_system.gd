extends Node

var inventory: Inv

func _enter_tree():
	# Загружаем инвентарь при добавлении в дерево
	inventory = preload("res://ui/inventory/playerinv.tres")
	if !inventory:
		push_error("Не удалось загрузить инвентарь!")
	else:
		print("GlobalInventory: инвентарь загружен")

	if not inventory:
		inventory = preload("res://ui/inventory/playerinv.tres")
