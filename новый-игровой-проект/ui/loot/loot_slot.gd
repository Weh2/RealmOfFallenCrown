extends Panel

# Ссылки на ноды
@onready var item_visual: Sprite2D = $CenterContainer/Panel/item_display
@onready var amount_text: Label = $CenterContainer/Panel/Label

# Настройки
@export var show_empty_slot_texture: bool = true
@export var empty_slot_texture: Texture2D

var current_item: InvItem = null
var current_quantity: int = 0
var slot_index: int = -1

signal slot_clicked(index: int, item: InvItem, quantity: int)

func update_slot(item: InvItem, amount: int):
	if not item_visual or not amount_text:
		push_error("Не найдены ноды для отображения предмета!")
		return
	
	current_item = item
	current_quantity = amount
	
	if item:
		# Отображаем предмет
		item_visual.visible = true
		item_visual.texture = item.texture if item.texture else load("res://assets/icons/unknown.png")
		amount_text.text = str(amount)
		amount_text.visible = amount > 1
		tooltip_text = "%s (x%d)" % [item.name, amount]
	else:
		# Очищаем слот
		item_visual.visible = show_empty_slot_texture
		item_visual.texture = empty_slot_texture if show_empty_slot_texture else null
		amount_text.visible = false
		tooltip_text = "Пустой слот"

func _ready():
	# Инициализация пустого слота
	update_slot(null, 0)
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if current_item:
				emit_signal("slot_clicked", slot_index, current_item, current_quantity)
				# После клика обновляем слот
				update_slot(null, 0)

func _get_drag_data(_pos):
	if current_item:
		var drag_preview = TextureRect.new()
		drag_preview.texture = item_visual.texture
		drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		drag_preview.size = Vector2(32, 32)
		set_drag_preview(drag_preview)
		
		return {
			"origin_slot": self,
			"item": current_item,
			"quantity": current_quantity
		}
	return null

func _can_drop_data(_pos, data):
	return data is Dictionary and data.has("item")

func _drop_data(_pos, data):
	if current_item == null:
		emit_signal("slot_clicked", slot_index, data["item"], data["quantity"])
