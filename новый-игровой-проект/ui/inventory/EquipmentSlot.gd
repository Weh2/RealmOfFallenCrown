extends Panel
class_name EquipmentSlot

@export var slot_type: String = "main_hand"
@onready var item_texture = $TextureRect/Sprite2D

var inventory: Inv
var player: Node

func _ready():
	# Получаем инвентарь из глобального скрипта
	inventory = GlobalInventory.inventory
	
	if !inventory:
		push_error("Глобальный инвентарь не доступен!")
		return
	
	inventory.equipment_updated.connect(update_slot)
	print("Слот", slot_type, "инициализирован")


func _find_inventory():
	# Ищем инвентарь в родителях
	var parent = get_parent()
	while parent:
		if parent.has_method("get_inventory"):
			inventory = parent.get_inventory()
			break
		parent = parent.get_parent()
	
	if !inventory:
		printerr("Не удалось найти инвентарь для слота ", slot_type)

	
	
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
	if !inventory:
		printerr("Инвентарь не инициализирован в слоте ", slot_type)
		return false

func _drop_data(_pos, data):
	if !inventory:
		push_error("Инвентарь отсутствует при попытке экипировки")
		return
		
	if inventory.equip_item(data["item"], slot_type):
		print(data["item"].name, " успешно экипирован в ", slot_type)
		update_slot()
		# Принудительно обновляем статистики игрока
		if player.has_method("calculate_stats"):
			player.calculate_stats()
	else:
		print("Ошибка экипировки ", data["item"].name)

	
	inventory.equip_item(data["item"], slot_type)
	update_slot()
	
func setup(p_player: Node):
	player = p_player
	update_slot()
