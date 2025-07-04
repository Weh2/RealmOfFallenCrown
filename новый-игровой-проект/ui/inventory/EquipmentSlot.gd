extends Panel
class_name EquipmentSlot

@export var slot_type: String = "main_hand"
@onready var item_texture = $TextureRect/Sprite2D

func _ready():
	GlobalInventory.inventory.equipment_updated.connect(update_slot)
	update_slot()

func update_slot():
	var slot = GlobalInventory.inventory.equipment_slots.get(slot_type)
	if slot and slot.item:
		item_texture.texture = slot.item.texture
		item_texture.visible = true
		print(slot_type, ": предмет установлен - ", slot.item.name)
	else:
		item_texture.visible = false
		print(slot_type, ": слот пуст")

func _get_drag_data(_pos):
	var slot = GlobalInventory.inventory.equipment_slots.get(slot_type)
	if not slot or not slot.item:
		return null
	
	return {
		"origin": self,
		"item": slot.item,
		"slot_type": slot_type
	}

func _can_drop_data(_pos, data):
	if not (data is Dictionary and data.has("item")):
		return false
	
	return GlobalInventory.inventory._can_equip(data["item"], slot_type)

func _drop_data(_pos, data):
	print("Попытка экипировать ", data["item"].name, " в ", slot_type)
	
	if GlobalInventory.inventory.equip_item(data["item"], slot_type):
		print("Успешно экипировано")
	else:
		print("Ошибка экипировки")
	
	# Принудительное обновление
	update_slot()
