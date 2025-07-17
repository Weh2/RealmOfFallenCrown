extends Panel

# Ссылки на ноды
@onready var item_visual: Sprite2D = $CenterContainer/Panel/item_display
@onready var amount_text: Label = $CenterContainer/Panel/Label

# Настройки
@export var show_empty_slot_texture: bool = true
@export var empty_slot_texture: Texture2D

func update_slot(item: InvItem, amount: int):
	if not item_visual or not amount_text:
		push_error("Не найдены ноды для отображения предмета!")
		return
	
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
