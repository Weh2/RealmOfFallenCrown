extends TileMap
class_name WorldGenerator

enum BIOME {
	DUNGEON,      # Подземелья и катакомбы
	FOREST,       # Тёмные леса с мистическими существами
	CASTLE,       # Заброшенные замки и укрепления
	BATTLEFIELD,  # Поля сражений с призраками
	VILLAGE       # Разрушенные деревни
}

# Настройки генерации
@export_category("Generation Settings")
@export var map_width: int = 256
@export var map_height: int = 256
@export var biome: BIOME = BIOME.DUNGEON
@export var generation_seed: int = 0:
	set(value):
		generation_seed = value
		if Engine.is_editor_hint():
			generate_world()
@export var chunk_size: int = 32

# Настройки биомов
@export_subgroup("Dungeon Settings")
@export var dungeon_room_count: int = 10
@export var dungeon_min_room_size: int = 5
@export var dungeon_max_room_size: int = 15
@export var dungeon_wall_chance: float = 0.45

@export_subgroup("Forest Settings")
@export var forest_tree_density: float = 0.2
@export var forest_path_width: int = 3

# Тайлы
@export_subgroup("Tile Atlas Coordinates")
@export var floor_tile: Vector2i = Vector2i(0, 0)
@export var wall_tile: Vector2i = Vector2i(1, 0)
@export var water_tile: Vector2i = Vector2i(2, 0)
@export var tree_tile: Vector2i = Vector2i(3, 0)
@export var ruin_tile: Vector2i = Vector2i(4, 0)

# Системные переменные
var loaded_chunks = {}
var noise = FastNoiseLite.new()
var rng = RandomNumberGenerator.new()

func _ready():
	if generation_seed == 0:
		generation_seed = Time.get_unix_time_from_system()
	rng.seed = generation_seed
	setup_noise()
	generate_world()

func setup_noise():
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = generation_seed
	noise.frequency = 0.05
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

## Основная функция генерации
func generate_world():
	clear()
	loaded_chunks.clear()
	
	match biome:
		BIOME.DUNGEON:
			generate_dungeon()
		BIOME.FOREST:
			generate_forest()
		BIOME.CASTLE:
			generate_castle()
		BIOME.BATTLEFIELD:
			generate_battlefield()
		BIOME.VILLAGE:
			generate_village()
	
	place_special_features()
	spawn_dynamic_entities()

## Генерация подземелий (алгоритм комнат и коридоров)
func generate_dungeon():
	var rooms = []
	
	# Генерация комнат
	for i in range(dungeon_room_count):
		var room_width = rng.randi_range(dungeon_min_room_size, dungeon_max_room_size)
		var room_height = rng.randi_range(dungeon_min_room_size, dungeon_max_room_size)
		var x = rng.randi_range(1, map_width - room_width - 1)
		var y = rng.randi_range(1, map_height - room_height - 1)
		var new_room = Rect2i(x, y, room_width, room_height)
		
		# Проверка пересечения с другими комнатами
		var failed = false
		for other_room in rooms:
			if new_room.intersects(other_room):
				failed = true
				break
		
		if not failed:
			rooms.append(new_room)
			fill_room(new_room)
	
	# Соединение комнат коридорами
	if rooms.size() > 1:
		for i in range(rooms.size() - 1):
			connect_rooms(rooms[i], rooms[i + 1])
	
	# Добавление стен
	for x in range(map_width):
		for y in range(map_height):
			if get_cell_atlas_coords(0, Vector2i(x, y)) != floor_tile:
				# Проверяем соседей, чтобы определить стену
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
							if get_cell_atlas_coords(0, Vector2i(nx, ny)) == floor_tile:
								set_cell(0, Vector2i(x, y), 0, wall_tile)
								break

func fill_room(room: Rect2i):
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			set_cell(0, Vector2i(x, y), 0, floor_tile)

func connect_rooms(room1: Rect2i, room2: Rect2i):
	var center1 = room1.position + room1.size / 2
	var center2 = room2.position + room2.size / 2
	
	# Горизонтальный коридор
	var step_x = sign(center2.x - center1.x)
	for x in range(center1.x, center2.x + step_x, step_x):
		set_cell(0, Vector2i(x, center1.y), 0, floor_tile)
		# Добавляем стены по бокам коридора
		if biome == BIOME.DUNGEON:
			set_cell(0, Vector2i(x, center1.y - 1), 0, wall_tile)
			set_cell(0, Vector2i(x, center1.y + 1), 0, wall_tile)
	
	# Вертикальный коридор
	var step_y = sign(center2.y - center1.y)
	for y in range(center1.y, center2.y + step_y, step_y):
		set_cell(0, Vector2i(center2.x, y), 0, floor_tile)
		# Добавляем стены по бокам коридора
		if biome == BIOME.DUNGEON:
			set_cell(0, Vector2i(center2.x - 1, y), 0, wall_tile)
			set_cell(0, Vector2i(center2.x + 1, y), 0, wall_tile)

## Генерация леса (на основе шума)
func generate_forest():
	for x in range(map_width):
		for y in range(map_height):
			var value = noise.get_noise_2d(x, y)
			
			# Основной пол
			set_cell(0, Vector2i(x, y), 0, floor_tile)
			
			# Деревья
			if value > forest_tree_density:
				set_cell(0, Vector2i(x, y), 0, tree_tile)
			
			# Водоёмы
			elif value < -0.3:
				set_cell(0, Vector2i(x, y), 0, water_tile)
			
			# Тропы (меньше деревьев вдоль линий шума)
			elif abs(value) < 0.1:
				for dx in range(-forest_path_width, forest_path_width + 1):
					for dy in range(-forest_path_width, forest_path_width + 1):
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
							if get_cell_atlas_coords(0, Vector2i(nx, ny)) == tree_tile:
								set_cell(0, Vector2i(nx, ny), 0, floor_tile)

## Генерация замка (предзаданные модули + процедурные элементы)
func generate_castle():
	# Сначала генерируем основу замка
	var castle_width = rng.randi_range(30, 50)
	var castle_height = rng.randi_range(30, 50)
	var start_x = (map_width - castle_width) / 2
	var start_y = (map_height - castle_height) / 2
	
	# Внешние стены
	for x in range(start_x, start_x + castle_width):
		set_cell(0, Vector2i(x, start_y), 0, wall_tile)
		set_cell(0, Vector2i(x, start_y + castle_height - 1), 0, wall_tile)
	
	for y in range(start_y, start_y + castle_height):
		set_cell(0, Vector2i(start_x, y), 0, wall_tile)
		set_cell(0, Vector2i(start_x + castle_width - 1, y), 0, wall_tile)
	
	# Внутренние комнаты
	var room_count = rng.randi_range(5, 10)
	var rooms = []
	
	for i in range(room_count):
		var room_width = rng.randi_range(5, 15)
		var room_height = rng.randi_range(5, 10)
		var x = rng.randi_range(start_x + 2, start_x + castle_width - room_width - 2)
		var y = rng.randi_range(start_y + 2, start_y + castle_height - room_height - 2)
		
		var new_room = Rect2i(x, y, room_width, room_height)
		rooms.append(new_room)
		fill_room(new_room)
	
	# Соединение комнат
	for i in range(rooms.size() - 1):
		connect_rooms(rooms[i], rooms[i + 1])
	
	# Добавление разрушений
	for x in range(start_x, start_x + castle_width):
		for y in range(start_y, start_y + castle_height):
			if rng.randf() < 0.1 and get_cell_atlas_coords(0, Vector2i(x, y)) == wall_tile:
				set_cell(0, Vector2i(x, y), 0, ruin_tile)

## Генерация поля битвы
func generate_battlefield():
	# Основа - открытое пространство с элементами разрушения
	for x in range(map_width):
		for y in range(map_height):
			var value = noise.get_noise_2d(x * 0.1, y * 0.1)
			
			if value > 0.5:
				set_cell(0, Vector2i(x, y), 0, ruin_tile)
			elif value < -0.3:
				set_cell(0, Vector2i(x, y), 0, water_tile)
			else:
				set_cell(0, Vector2i(x, y), 0, floor_tile)
	
	# Добавляем траншеи и укрепления
	for i in range(5):
		var trench_x = rng.randi_range(10, map_width - 10)
		var trench_width = rng.randi_range(3, 7)
		
		for x in range(trench_x, trench_x + trench_width):
			for y in range(10, map_height - 10):
				if (x + y) % 4 == 0:
					set_cell(0, Vector2i(x, y), 0, wall_tile)

## Генерация деревни
func generate_village():
	# Сначала генерируем дорогу
	var road_y = map_height / 2
	for x in range(map_width):
		for dy in range(-2, 3):
			set_cell(0, Vector2i(x, road_y + dy), 0, floor_tile)
	
	# Генерация домов вдоль дороги
	var house_count = rng.randi_range(5, 10)
	for i in range(house_count):
		var house_width = rng.randi_range(5, 10)
		var house_height = rng.randi_range(5, 8)
		var house_x = rng.randi_range(10, map_width - house_width - 10)
		var house_y = road_y + (rng.randi_range(0, 1) * 2 - 1) * rng.randi_range(10, 20)
		
		# Стены дома
		for x in range(house_x, house_x + house_width):
			set_cell(0, Vector2i(x, house_y), 0, wall_tile)
			set_cell(0, Vector2i(x, house_y + house_height - 1), 0, wall_tile)
		
		for y in range(house_y, house_y + house_height):
			set_cell(0, Vector2i(house_x, y), 0, wall_tile)
			set_cell(0, Vector2i(house_x + house_width - 1, y), 0, wall_tile)
		
		# Внутренность дома
		for x in range(house_x + 1, house_x + house_width - 1):
			for y in range(house_y + 1, house_y + house_height - 1):
				set_cell(0, Vector2i(x, y), 0, floor_tile)
		
		# Дверь
		set_cell(0, Vector2i(house_x + house_width / 2, house_y + house_height - 1), 0, floor_tile)
	
	# Добавление разрушений
	for x in range(map_width):
		for y in range(map_height):
			if rng.randf() < 0.15 and get_cell_atlas_coords(0, Vector2i(x, y)) == wall_tile:
				set_cell(0, Vector2i(x, y), 0, ruin_tile)

## Размещение специальных объектов
func place_special_features():
	match biome:
		BIOME.DUNGEON:
			place_dungeon_features()
		BIOME.FOREST:
			place_forest_features()
		BIOME.CASTLE:
			place_castle_features()
		BIOME.BATTLEFIELD:
			place_battlefield_features()
		BIOME.VILLAGE:
			place_village_features()

func place_dungeon_features():
	# Алтари и сундуки в подземельях
	var used_cells = get_used_cells(0)
	for i in range(3):
		if used_cells.size() > 0:
			var pos = used_cells[rng.randi() % used_cells.size()]
			if get_cell_atlas_coords(0, pos) == floor_tile:
				set_cell(1, pos, 0, Vector2i(5, 0)) # Алтарь

func place_forest_features():
	# Алтари древних богов в лесу
	for i in range(2):
		var x = rng.randi_range(20, map_width - 20)
		var y = rng.randi_range(20, map_height - 20)
		if get_cell_atlas_coords(0, Vector2i(x, y)) == floor_tile:
			set_cell(1, Vector2i(x, y), 0, Vector2i(6, 0)) # Лесной алтарь
			# Очищаем пространство вокруг алтаря
			for dx in range(-3, 4):
				for dy in range(-3, 4):
					var nx = x + dx
					var ny = y + dy
					if get_cell_atlas_coords(0, Vector2i(nx, ny)) == tree_tile:
						set_cell(0, Vector2i(nx, ny), 0, floor_tile)

func place_castle_features():
	# Особенности замка - королевские реликвии, тронный зал
	var used_cells = get_used_cells(0).filter(
		func(cell): return get_cell_atlas_coords(0, cell) == floor_tile
	)
	
	# Трон
	if used_cells.size() > 0:
		var throne_pos = used_cells[used_cells.size() / 2]
		set_cell(1, throne_pos, 0, Vector2i(7, 0)) # Трон
		
	# Сокровищница
	for i in range(3):
		if used_cells.size() > 0:
			var pos = used_cells[rng.randi() % used_cells.size()]
			set_cell(1, pos, 0, Vector2i(8, 0)) # Сундук с сокровищами

func place_battlefield_features():
	# Особенности поля битвы - брошенное оружие, массовые захоронения
	for i in range(10):
		var x = rng.randi_range(10, map_width - 10)
		var y = rng.randi_range(10, map_height - 10)
		if get_cell_atlas_coords(0, Vector2i(x, y)) == floor_tile:
			set_cell(1, Vector2i(x, y), 0, Vector2i(9, 0)) # Брошенное оружие
	
	# Массовые захоронения
	for i in range(3):
		var x = rng.randi_range(20, map_width - 20)
		var y = rng.randi_range(20, map_height - 20)
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				set_cell(1, Vector2i(x + dx, y + dy), 0, Vector2i(10, 0)) # Кости

func place_village_features():
	# Особенности деревни - колодцы, рыночные площади
	var used_cells = get_used_cells(0).filter(
		func(cell): return get_cell_atlas_coords(0, cell) == floor_tile
	)
	
	# Колодец в центре
	if used_cells.size() > 0:
		var well_pos = used_cells[used_cells.size() / 2]
		set_cell(1, well_pos, 0, Vector2i(11, 0)) # Колодец
		
	# Рыночная площадь
	for i in range(5):
		if used_cells.size() > 0:
			var pos = used_cells[rng.randi() % used_cells.size()]
			set_cell(1, pos, 0, Vector2i(12, 0)) # Торговая палатка

## Спаун динамических объектов и врагов
func spawn_dynamic_entities():
	var used_cells = get_used_cells(0).filter(
		func(cell): return get_cell_atlas_coords(0, cell) == floor_tile
	)
	
	# Спаун врагов в зависимости от биома
	var enemy_count = rng.randi_range(10, 20)
	for i in range(enemy_count):
		if used_cells.size() > 0:
			var pos = used_cells[rng.randi() % used_cells.size()]
			spawn_enemy_at(pos)
	
	# Спаун NPC и объектов
	if biome == BIOME.VILLAGE:
		spawn_villagers(used_cells)

func spawn_enemy_at(position: Vector2i):
	var enemy_scene: PackedScene
	match biome:
		BIOME.DUNGEON:
			enemy_scene = load("res://enemies/cultist.tscn")
		BIOME.FOREST:
			enemy_scene = load("res://enemies/werewolf.tscn")
		BIOME.CASTLE:
			enemy_scene = load("res://enemies/cursed_knight.tscn")
		BIOME.BATTLEFIELD:
			enemy_scene = load("res://enemies/ghost.tscn")
		BIOME.VILLAGE:
			enemy_scene = load("res://enemies/bandit.tscn")
	
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		enemy.position = map_to_local(position)
		get_parent().add_child(enemy)

func spawn_villagers(cells: Array):
	# Спаун NPC в деревнях
	var villager_scenes = [
		load("res://npcs/peasant.tscn"),
		load("res://npcs/merchant.tscn"),
		load("res://npcs/blacksmith.tscn")
	]
	
	for i in range(5):  # Количество NPC
		if cells.size() > 0:
			var pos = cells[rng.randi() % cells.size()]
			var villager = villager_scenes[rng.randi() % villager_scenes.size()].instantiate()
			villager.position = map_to_local(pos)
			get_parent().add_child(villager)

## Чанкование для больших миров
func update_chunks(player_position: Vector2):
	var player_chunk = Vector2i(
		floor(player_position.x / chunk_size),
		floor(player_position.y / chunk_size)
	)
	
	# Загружаем новые чанки вокруг игрока
	for x in range(player_chunk.x - 2, player_chunk.x + 3):
		for y in range(player_chunk.y - 2, player_chunk.y + 3):
			var chunk_key = Vector2i(x, y)
			if not loaded_chunks.has(chunk_key):
				generate_chunk(x, y)
				loaded_chunks[chunk_key] = true
	
	# Выгружаем дальние чанки
	var chunks_to_unload = []
	for chunk in loaded_chunks:
		if abs(chunk.x - player_chunk.x) > 3 or abs(chunk.y - player_chunk.y) > 3:
			chunks_to_unload.append(chunk)
	
	for chunk in chunks_to_unload:
		unload_chunk(chunk)
		loaded_chunks.erase(chunk)

func generate_chunk(chunk_x: int, chunk_y: int):
	# Генерация части мира в указанном чанке
	var start_x = chunk_x * chunk_size
	var start_y = chunk_y * chunk_size
	
	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			if x >= 0 and x < map_width and y >= 0 and y < map_height:
				match biome:
					BIOME.DUNGEON:
						generate_dungeon_cell(x, y)
					BIOME.FOREST:
						generate_forest_cell(x, y)
					BIOME.CASTLE:
						set_cell(0, Vector2i(x, y), 0, floor_tile)
					BIOME.BATTLEFIELD:
						set_cell(0, Vector2i(x, y), 0, floor_tile)
					BIOME.VILLAGE:
						set_cell(0, Vector2i(x, y), 0, floor_tile)

func unload_chunk(chunk: Vector2i):
	# Выгрузка чанка - очистка области
	var start_x = chunk.x * chunk_size
	var start_y = chunk.y * chunk_size
	
	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			if x >= 0 and x < map_width and y >= 0 and y < map_height:
				erase_cell(0, Vector2i(x, y))
				erase_cell(1, Vector2i(x, y))

func generate_dungeon_cell(x: int, y: int):
	# Генерация отдельной клетки подземелья
	if x == 0 or x == map_width - 1 or y == 0 or y == map_height - 1:
		set_cell(0, Vector2i(x, y), 0, wall_tile)
	else:
		var value = noise.get_noise_2d(x * 0.1, y * 0.1)
		set_cell(0, Vector2i(x, y), 0, wall_tile if value > 0.3 else floor_tile)

func generate_forest_cell(x: int, y: int):
	# Генерация отдельной клетки леса
	var value = noise.get_noise_2d(x * 0.1, y * 0.1)
	if value > forest_tree_density:
		set_cell(0, Vector2i(x, y), 0, tree_tile)
	elif value < -0.3:
		set_cell(0, Vector2i(x, y), 0, water_tile)
	else:
		set_cell(0, Vector2i(x, y), 0, floor_tile)

## Сохранение и загрузка сгенерированного мира
func save_world():
	var save_data = {
		"biome": biome,
		"seed": generation_seed,
		"tiles": []
	}
	
	for cell in get_used_cells(0):
		save_data["tiles"].append({
			"x": cell.x,
			"y": cell.y,
			"tile": get_cell_atlas_coords(0, cell)
		})
	
	var save_path = "user://world_save_%d.json" % generation_seed
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func load_world():
	var save_path = "user://world_save_%d.json" % generation_seed
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		
		if data:
			clear()
			biome = data["biome"]
			generation_seed = data["seed"]
			
			for tile_data in data["tiles"]:
				set_cell(0, Vector2i(tile_data["x"], tile_data["y"]), 0, tile_data["tile"])
			
			return true
	return false
