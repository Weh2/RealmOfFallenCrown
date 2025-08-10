extends Panel

@onready var rich_text := $RichTextLabel

func update_tooltip(text: String) -> void:
	rich_text.text = text
	# Автоматически подстраиваем размер под текст
	var size = rich_text.get_content_height()
	custom_minimum_size.y = size + 20  # + отступы
