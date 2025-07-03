extends Panel
class_name EquipmentSlot

@export var slot_type: String = "main_hand"
@onready var item_texture = $TextureRect/Sprite2D

var inventory: Inv
var player: Node  # Добавляем ссылку на игрока

func setup(p_inventory: Inv, p_player: Node):
	inventory = p_inventory
	player = p_player
	if inventory:
		inventory.equipment_updated.connect(update_slot)
	update_slot()

func update_slot():
	var slot = inventory.equipment_slots[slot_type]
	if slot and slot.item:
		item_texture.texture = slot.item.texture
		item_texture.visible = true
		# Обновляем оружие на персонаже
		if slot_type == "main_hand" and player.has_node("Weapon"):
			player.get_node("Weapon").update_weapon(slot.item)
	else:
		item_texture.visible = false
		# Снимаем оружие если слот пуст
		if slot_type == "main_hand" and player.has_node("Weapon"):
			player.get_node("Weapon").unequip_weapon()

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
	if not inventory: return false
	
	return inventory._can_equip(data["item"], slot_type)

func _drop_data(_pos, data):
	if inventory.equip_item(data["item"], slot_type):
		# Если предмет успешно экипирован, обновляем слот
		update_slot()
