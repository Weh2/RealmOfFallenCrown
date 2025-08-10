extends Control

@onready var inv: Inv = preload("res://ui/inventory/playerinv.tres")
@onready var regular_slots: Array = $NinePatchRect/GridContainer.get_children()
@onready var equipment_slots: Array = $EquipmentPanel/GridContainer.get_children()
@onready var item_tooltip = preload("res://ui/ItemTooltip.tscn").instantiate()



var is_open = false
var is_tooltip_visible := false
var hide_timer: Timer

func _ready():
	add_child(item_tooltip)
	item_tooltip.hide()
	
	# Инициализация таймера
	hide_timer = Timer.new()
	hide_timer.one_shot = true
	hide_timer.timeout.connect(_real_hide_tooltip)
	add_child(hide_timer)
	
	# Подключение сигналов
	inv.update.connect(update_regular_slots)
	inv.equipment_updated.connect(update_equipment_slots)
	
	for ui_slot in regular_slots + equipment_slots:
		ui_slot.inv = inv
		ui_slot.slot_hovered.connect(_on_slot_hovered)
		ui_slot.slot_unhovered.connect(_on_slot_unhovered)

	update_regular_slots()
	update_equipment_slots()
	close()

func _on_slot_hovered(slot_data: InvSlot):
	if slot_data and slot_data.item:
		_show_item_tooltip(slot_data.item, get_global_mouse_position())
	hide_timer.stop()

func _on_slot_unhovered():
	_hide_item_tooltip()

func _show_item_tooltip(item: InvItem, mouse_pos: Vector2):
	if not item:
		return
	
	var tooltip_text = generate_tooltip_text(item)
	item_tooltip.update_tooltip(tooltip_text)
	
	# Получаем размеры viewport
	var viewport_size = get_viewport().get_visible_rect().size
	var tooltip_size = item_tooltip.size
	
	# Определяем базовую позицию (смещение от курсора)
	var base_offset = Vector2(20, 20)
	var pos = mouse_pos + base_offset
	
	# Корректируем позицию, если выходит за экран
	if pos.x + tooltip_size.x > viewport_size.x:
		pos.x = mouse_pos.x - tooltip_size.x - base_offset.x
	
	if pos.y + tooltip_size.y > viewport_size.y:
		pos.y = mouse_pos.y - tooltip_size.y - base_offset.y
	
	# Дополнительная проверка для инвентаря справа
	var inventory_rect = $NinePatchRect.get_global_rect()
	if pos.x < inventory_rect.position.x and mouse_pos.x > inventory_rect.position.x:
		# Если подсказка уходит левее инвентаря, а курсор внутри инвентаря
		pos.x = inventory_rect.position.x
	
	# Применяем финальную позицию
	item_tooltip.global_position = pos
	
	# Анимация появления
	item_tooltip.modulate.a = 0
	item_tooltip.show()
	is_tooltip_visible = true
	create_tween().tween_property(item_tooltip, "modulate:a", 1.0, 0.2)
	
	
	
	
func _hide_item_tooltip():
	if item_tooltip.get_global_rect().grow(20).has_point(get_global_mouse_position()):
		return
	hide_timer.start(0.3)

func _real_hide_tooltip():
	var tween = create_tween()
	tween.tween_property(item_tooltip, "modulate:a", 0.0, 0.15)
	await tween.finished
	item_tooltip.hide()
	is_tooltip_visible = false

func _get_type_name(type: int) -> String:
	match type:
		InvItem.ItemType.WEAPON: return "Оружие"
		InvItem.ItemType.SHIELD: return "Щит"
		InvItem.ItemType.BODY: return "Доспех"
		InvItem.ItemType.HEAD: return "Шлем"
		InvItem.ItemType.HANDS: return "Перчатки"
		InvItem.ItemType.LEGS: return "Поножи"
		InvItem.ItemType.RING: return "Кольцо"
		InvItem.ItemType.AMULET: return "Амулет"
		InvItem.ItemType.CONSUMABLE: return "Расходуемый"
		_: return "Предмет"

func _format_stat_name(stat: String) -> String:
	var stat_names = {
		"attack": "Атака",
		"armor": "Защита",
		"health": "Здоровье",
		"stamina": "Выносливость",
		"attack_speed": "Скорость атаки",
		"crit_chance": "Шанс крита",
		"crit_damage": "Урон крита"
	}
	return stat_names.get(stat, stat)

func generate_tooltip_text(item: InvItem) -> String:
	var text := "[b][color=#FFD700]%s[/color][/b]\n" % item.name
	text += "[i]%s[/i]\n\n" % _get_type_name(item.item_type)
	
	# Статы
	for stat in item.stats:
		if item.stats[stat] != 0:
			text += "• %s: %+d\n" % [_format_stat_name(stat), item.stats[stat]]
	
	# Особые эффекты
	if item.item_type == InvItem.ItemType.CONSUMABLE:
		text += "\n[b]Эффект:[/b]\n"
		match item.name:
			"Health Potion":
				text += "• Восстанавливает 30 здоровья\n"
			"Stamina Potion":
				text += "• Восстанавливает 50 стамины\n"
			"Meat":
				text += "• Восстанавливает 15 здоровья и 20 стамины\n"
	
	return text
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
	
	
