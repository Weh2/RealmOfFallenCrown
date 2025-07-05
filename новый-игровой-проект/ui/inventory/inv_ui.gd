extends Control

@onready var inv: Inv = preload("res://ui/inventory/playerinv.tres")
@onready var regular_slots: Array = $NinePatchRect/GridContainer.get_children() # переименовали slots в regular_slots
@onready var equipment_slots: Array = $EquipmentPanel/GridContainer.get_children() # ссылка на новые слоты экипировки

var is_open = false

func _ready():
	inv.update.connect(update_regular_slots)
	inv.equipment_updated.connect(update_equipment_slots)
	# Передаем инвентарь в каждый слот
	for slot in regular_slots:
		slot.inv = inv
	for slot in equipment_slots:
		slot.inv = inv

	update_regular_slots()
	update_equipment_slots()
	close()

func update_regular_slots(): # переименовали update_slots
	for i in range(min(inv.slots.size(), regular_slots.size())):
		regular_slots[i].update(inv.slots[i])

func update_equipment_slots():
	if inv == null:
		push_error("Inventory is null!")
		return
	
	for i in range(min(inv.equipment_slots.size(), equipment_slots.size())):
		if inv.equipment_slots[i] == null:
			push_warning("Equipment slot %d is null!" % i)
			inv.equipment_slots[i] = InvSlot.new()  # Автоматически создаем слот если он null
		
		equipment_slots[i].update(inv.equipment_slots[i])



func _process(delta):
	if Input.is_action_just_pressed("inventory"):
		if is_open:
			close()
		else:
			open()

func open():
	visible = true
	is_open = true

func close():
	visible = false
	is_open = false
	
	
