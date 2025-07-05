extends Panel
class_name EquipmentSlot

@export var slot_type: String = "main_hand"
@onready var icon: Sprite2D = $TextureRect/Sprite2D

func _ready():
	await get_tree().process_frame  # Ждем инициализации
	
	var inv = _get_inventory()
	if inv:
		if inv.has_user_signal("equipment_updated"):
			inv.equipment_updated.connect(update_slot)
		else:
			push_error("Сигнал equipment_updated не найден!")
	update_slot()

func _get_inventory():
	# Пытаемся получить инвентарь разными способами
	var manager = get_node_or_null("/root/Main/InventoryManager")
	if manager and manager.inventory:
		return manager.inventory
	return null

func update_slot():
	var inv = _get_inventory()
	if !inv:
		return
		
	var slot = inv.equipment_slots.get(slot_type)
	icon.visible = slot and slot.item
	if icon.visible:
		icon.texture = slot.item.texture
