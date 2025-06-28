extends Control
class_name HotbarUI

@onready var slot1 = $HBoxContainer/Slot1
@onready var slot2 = $HBoxContainer/Slot2
@onready var inv: Inv = preload("res://ui/inventory/playerinv.tres")

func _ready():
	inv.hotbar_updated.connect(update_slots)
	update_slots()

func update_slots():
	slot1.update(inv.hotbar_slots[0])
	slot2.update(inv.hotbar_slots[1])
