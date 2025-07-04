extends Panel
class_name EquipmentSlot

@export var slot_type: String = "main_hand"
@onready var item_texture = $TextureRect/Sprite2D

func _ready():
	GlobalInventory.inventory.equipment_updated.connect(update_slot)
	update_slot()

func update_slot():
	var slot = GlobalInventory.inventory.equipment_slots.get(slot_type)
	print("--- Обновление слота ---")
	print("Слот:", slot_type)
	print("Содержимое:", slot.item.name if slot and slot.item else "пусто")
	
	if slot and slot.item:
		item_texture.texture = slot.item.texture
		item_texture.visible = true
	else:
		item_texture.visible = false
		
		
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
	if not data is Dictionary or not data.has("item"):
		return
		
	# Создаем полностью новый объект для предмета
	var item_copy = data["item"].duplicate()
	
	if GlobalInventory.inventory.equip_item(item_copy, slot_type):
		# Принудительное обновление через таймер
		await get_tree().process_frame
		update_slot()
