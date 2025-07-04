extends Node2D

@onready var hitbox = $Hitbox/CollisionShape2D
@onready var player_anim = $"../AnimationPlayer"
@onready var weapon_sprite = $Sprite2D

var is_attack_active := false
var current_attack_dir = Vector2.RIGHT
var attack_duration := 0.3
var current_weapon: InvItem = null  # Добавляем ссылку на текущее оружие

func _ready():
	assert(hitbox != null, "Hitbox not found!")
	assert(player_anim != null, "Main AnimationPlayer not found in parent!")
	hitbox.disabled = true
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)

# Обновляем оружие при экипировке
func update_weapon(weapon_data: InvItem):
	current_weapon = weapon_data
	weapon_sprite.texture = weapon_data.texture
	weapon_sprite.visible = true
	# Можно добавить изменение размера хитбокса в зависимости от оружия
	# hitbox.shape.extents = Vector2(weapon_data.range, 10)

func update_direction(facing_left: bool):
	if facing_left:
		position = Vector2(-30, 0)
		if weapon_sprite:
			weapon_sprite.flip_h = true
	else:
		position = Vector2(30, 0)
		if weapon_sprite:
			weapon_sprite.flip_h = false

func start_attack(move_direction: Vector2):
	if is_attack_active or not current_weapon: 
		return
		
	is_attack_active = true
	
	# Обновляем направление
	if move_direction.length() > 0:
		current_attack_dir = move_direction.normalized()
		rotation = current_attack_dir.angle()
		update_direction(current_attack_dir.x < 0)
	
	# Определяем анимацию
	var anim_name = "attack_right"
	if current_attack_dir.length() > 0:
		if abs(current_attack_dir.x) > abs(current_attack_dir.y):
			anim_name = "attack_right" if current_attack_dir.x > 0 else "attack_left"
		else:
			anim_name = "attack_down" if current_attack_dir.y > 0 else "attack_up"
	
	player_anim.play(anim_name)
	hitbox.disabled = false
	
	await get_tree().create_timer(attack_duration).timeout
	
	hitbox.disabled = true
	is_attack_active = false

func is_attacking() -> bool:
	return is_attack_active

func _on_hitbox_body_entered(body):
	if body != get_parent() and body.has_method("take_damage") and current_weapon:
		body.take_damage(current_weapon).stats.get("attack", 0)

# Добавляем функцию для сброса оружия (при снятии)
func unequip_weapon():
	current_weapon = null
	weapon_sprite.visible = false
