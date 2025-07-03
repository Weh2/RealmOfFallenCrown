extends Control

@onready var inv: Inv = preload("res://ui/inventory/playerinv.tres")
@onready var main_slots: Array = $NinePatchRect/GridContainer.get_children()
@onready var equipment_panel = $EquipmentPanel

var is_open = false

func _ready():
	# Убедитесь, что передаете игрока при setup слотов экипировки
	for slot in equipment_panel.get_children():
		if slot is EquipmentSlot:
			slot.setup(inv, get_parent())  # Предполагаем, что родитель - игрок
	# Убедитесь, что inventory загружен
	if not inv:
		push_error("Inventory resource not loaded!")
		return
	
	# Правильно инициализируем слоты экипировки
	for slot in equipment_panel.get_children():
		if slot is EquipmentSlot:
			slot.setup(inv)  # Передаем инвентарь
	# Подключаем только нужные сигналы
	inv.inventory_updated.connect(update_main_slots)
	inv.equipment_updated.connect(update_equipment)
	
	update_main_slots()
	update_equipment()
	
	equipment_panel.visible = false
	close()

func update_main_slots():
	for i in range(min(inv.slots.size(), main_slots.size())):
		main_slots[i].update(inv.slots[i])

func update_equipment():
	for slot in equipment_panel.get_children():
		if slot is EquipmentSlot:
			slot.update(inv.equipment_slots[slot.slot_type])



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
	
	
