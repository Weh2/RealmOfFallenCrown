extends Panel

@onready var item_visual: Sprite2D = $CenterContainer/Panel/item_display
@onready var amount_text: Label = $CenterContainer/Panel/Label
@onready var selectSprite: Sprite2D = $CenterContainer/Panel/select

var inv: Inv = null 
var current_slot: InvSlot  # Текущий слот, связанный с этим UI


func _ready():
	# Явно подключаем сигнал gui_input
	gui_input.connect(_on_gui_input)


# Обновление отображения слота
func update(slot: InvSlot):
	if slot == null:
		push_warning("Attempted to update slot with null")
		item_visual.visible = false
		amount_text.visible = false
		return
	
	current_slot = slot
	if slot.item == null:
		item_visual.visible = false
		amount_text.visible = false
	else:
		item_visual.visible = true
		item_visual.texture = slot.item.texture
		amount_text.text = str(slot.amount)
		amount_text.visible = slot.amount > 1

# --- Drag & Drop система ---
func _get_drag_data(_pos):
	if current_slot and current_slot.item:
		# Создаем превью для перетаскивания
		var drag_preview = TextureRect.new()
		drag_preview.texture = item_visual.texture
		drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		drag_preview.size = Vector2(32, 32)
		set_drag_preview(drag_preview)
		
		# Возвращаем данные о перетаскиваемом предмете
		return {
			"origin_slot": self,
			"slot_data": current_slot,
			"item": current_slot.item,
			"amount": current_slot.amount
		}
	return null

func _can_drop_data(_pos, data):
	# Проверяем, что перетаскивается предмет
	return data is Dictionary and data.has("item")

func _drop_data(_pos, data):
	if not (data is Dictionary and data.has("slot_data")):
		return
	
	var source_slot: InvSlot = data["slot_data"]
	var target_slot: InvSlot = current_slot
	
	if get_parent().get_parent().name == "EquipmentPanel":
		var slot_index = get_index()
		
		# Проверяем тип предмета
		if source_slot.item and source_slot.item.item_type != slot_index:
			print("Нельзя экипировать ", source_slot.item.name, " в этот слот")
			
			return
			
		if inv.equip_item(slot_index, source_slot.item):
			source_slot.item = null
			source_slot.amount = 0
			return
	# Если слоты одинаковые - ничего не делаем
	if source_slot == target_slot:
		return
	
	# Если target_slot пустой - перемещаем предмет
	if not target_slot.item:
		target_slot.item = source_slot.item
		target_slot.amount = source_slot.amount
		source_slot.item = null
		source_slot.amount = 0
	
	# Если предметы одинаковые и стакаемые - объединяем
	elif (target_slot.item.get_id() == source_slot.item.get_id() 
		  and target_slot.item.stackable 
		  and source_slot.item.stackable):
		var total = target_slot.amount + source_slot.amount
		var max_stack = target_slot.item.max_stack
		target_slot.amount = min(total, max_stack)
		source_slot.amount = total - target_slot.amount
		if source_slot.amount <= 0:
			source_slot.item = null
	
	# Если разные предметы - меняем местами
	else:
		var temp_item = target_slot.item
		var temp_amount = target_slot.amount
		target_slot.item = source_slot.item
		target_slot.amount = source_slot.amount
		source_slot.item = temp_item
		source_slot.amount = temp_amount
	
	# Обновляем оба слота
	data["origin_slot"].update(source_slot)
	update(target_slot)


func _on_mouse_entered() -> void:
	selectSprite.visible = true


func _on_mouse_exited() -> void:
	selectSprite.visible = false


func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_try_use_item()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# Ваша существующая логика для перетаскивания
			pass

func _try_use_item():
	print("Попытка использовать предмет из слота")
	if not current_slot:
		print("Ошибка: current_slot отсутствует")
		return
	if not current_slot.item:
		print("Ошибка: предмет в слоте отсутствует")
		return
	
	print("Используем предмет:", current_slot.item.name)
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Ошибка: игрок не найден в группе 'player'")
		return
	
	print("Вызываем apply_effects для", current_slot.item.name)
	current_slot.item.apply_effects(player)
	
	# Визуальная обратная связь
	if player.has_method("show_message"):
		player.show_message("Использован %s" % current_slot.item.name)
	
	# Уменьшаем количество
	current_slot.amount -= 1
	if current_slot.amount <= 0:
		current_slot.item = null
	
	update(current_slot)
	inv.update.emit()
