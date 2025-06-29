extends Control

@onready var inv: Inv = preload("res://ui/inventory/playerinv.tres")
@onready var main_slots: Array = $NinePatchRect/GridContainer.get_children()
@onready var equipment_panel = $EquipmentPanel
@onready var hotbar_ui = $HotbarUI

var is_open = false

func _ready():
	# Инициализация
	inv.update.connect(update_main_slots)
	inv.equipment_updated.connect(update_equipment)
	inv.hotbar_updated.connect(update_hotbar)
	
	# Скрываем при старте
	equipment_panel.visible = false
	hotbar_ui.visible = true
	close()

func update_main_slots():
	for i in range(min(inv.slots.size(), main_slots.size())):
		main_slots[i].update(inv.slots[i])

func update_equipment():
	for slot in equipment_panel.get_children():
		if slot is EquipmentSlot:
			slot.update(inv.equipment_slots[slot.slot_type])

func update_hotbar():
	hotbar_ui.update_slots()

func _process(delta):
	if Input.is_action_just_pressed("inventory"):
		if is_open:
			close()
		else:
			open()

func open():
	visible = true
	equipment_panel.visible = true
	is_open = true

func close():
	visible = false
	equipment_panel.visible = false
	is_open = false
	
	
