extends GPUParticles2D

func _ready():
	# 1. Создаём текстуру (с проверкой наличия файла)
	var texture: Texture2D
	if FileAccess.file_exists("res://assets/particles/blood.png"):
		texture = load("res://assets/particles/blood.png")
	else:
		# Создаём красный круг программно
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color(1, 0, 0, 0.8))  # Красный с прозрачностью
		texture = ImageTexture.create_from_image(image)

	# 2. Настраиваем материал
	var material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	# 3. Создаём QuadMesh
	var quad = QuadMesh.new()
	quad.size = Vector2(0.3, 0.3)
	quad.material = material
	material.set_texture(CanvasItemMaterial.TEXTURE_DIFFUSE, texture)
	
	# 4. Применяем к частицам
	draw_pass_1 = quad

	# 5. Настройки эмиттера
	one_shot = true
	amount = 50
	process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 0.5, 0)
	process_material.spread = 45
