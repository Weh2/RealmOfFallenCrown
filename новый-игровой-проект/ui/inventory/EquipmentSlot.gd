extends Panel
class_name EquipmentSlot

@export var slot_type: String = "main_hand"  # Устанавливается в инспекторе для каждого слота
@onready var item_texture = $TextureRect/Sprite2D

var inventory: Inv

func setup(p_inventory: Inv):
	inventory = p_inventory
	if inventory:
		inventory.equipment_updated.connect(update_slot)
	update_slot()

func update_slot():
	var slot = inventory.equipment_slots[slot_type]
	if slot and slot.item:
		item_texture.texture = slot.item.texture
		item_texture.visible = true
	else:
		item_texture.visible = false

func _get_drag_data(_pos):
	var slot = inventory.equipment_slots[slot_type]
	if not slot or not slot.item:
		return null
	
	var drag_data = {
		"origin": self,
		"item": slot.item,
		"slot_type": slot_type
	}
	
	var drag_preview = TextureRect.new()
	drag_preview.texture = item_texture.texture
	set_drag_preview(drag_preview)
	
	return drag_data

func _can_drop_data(_pos, data):
	if not data is Dictionary: return false
	if not data.has("item"): return false
	if not inventory:  # Добавляем проверку
		return false
	
	# Проверяем наличие метода
	if inventory.has_method("_can_equip"):
		return inventory._can_equip(data["item"], slot_type)
	else:
		push_error("Method _can_equip not found in inventory!")
		return false
func _drop_data(_pos, data):
	inventory.equip_item(data["item"], slot_type)
