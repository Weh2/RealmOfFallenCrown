extends Panel

@onready var item_visual: Sprite2D = $CenterContainer/Panel/item_display
@onready var amount_text: Label = $CenterContainer/Panel/Label
@onready var selectSprite: Sprite2D = $CenterContainer/Panel/select


var current_slot: InvSlot  # Текущий слот, связанный с этим UI

# Обновление отображения слота
func update(slot: InvSlot):
	current_slot = slot  # Сохраняем ссылку на слот
	if !slot.item:
		item_visual.visible = false
		amount_text.visible = false
	else:
		item_visual.visible = true
		item_visual.texture = slot.item.texture
		amount_text.text = str(slot.amount)
		amount_text.visible = slot.amount > 1  # Показываем количество только если > 1

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
	elif (target_slot.item.id == source_slot.item.id 
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
