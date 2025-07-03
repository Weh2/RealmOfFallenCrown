extends Panel
class_name EquipmentSlot

@export var slot_type: String = "main_hand"
@onready var item_texture = $TextureRect/Sprite2D

var inventory: Inv
var player: Node

func setup(p_inventory: Inv, p_player: Node):
	inventory = p_inventory
	player = p_player
	if inventory:
		if not inventory.equipment_updated.is_connected(update_slot):
			inventory.equipment_updated.connect(update_slot)
	update_slot()

func update_slot():
	var slot = inventory.equipment_slots.get(slot_type)
	if slot and slot.item:
		print("Обновляем слот:", slot_type, " предметом:", slot.item.name)
		item_texture.texture = slot.item.texture
		item_texture.visible = true
		
		# Обновляем оружие только для main_hand
		if slot_type == "main_hand" and player.has_node("Weapon"):
			player.get_node("Weapon").update_weapon(slot.item)
	else:
		print("Слот", slot_type, "пуст")
		item_texture.visible = false
		if slot_type == "main_hand" and player.has_node("Weapon"):
			player.get_node("Weapon").unequip_weapon()

func _get_drag_data(_pos):
	var slot = inventory.equipment_slots.get(slot_type)
	if not slot or not slot.item:
		return null
	
	print("Начали перетаскивание из слота:", slot_type)
	var drag_data = {
		"origin": self,
		"item": slot.item,
		"slot_type": slot_type
	}
	
	var drag_preview = TextureRect.new()
	drag_preview.texture = item_texture.texture
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.size = Vector2(32, 32)
	set_drag_preview(drag_preview)
	
	return drag_data

func _can_drop_data(_pos, data):
	if not data is Dictionary or not data.has("item") or not inventory:
		print("Проверка drop: невалидные данные")
		return false
	
	var can_equip = inventory._can_equip(data["item"], slot_type)
	print("Можно ли экипировать", data["item"].name, "в", slot_type, ":", can_equip)
	return can_equip

func _drop_data(_pos, data):
	print("Пытаемся экипировать", data["item"].name, "в слот", slot_type)
	if inventory.equip_item(data["item"], slot_type):
		print("Предмет успешно экипирован!")
		update_slot()
	else:
		print("Ошибка экипировки!")
