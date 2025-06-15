extends CharacterBody2D

@export var speed = 300.0
@onready var sprite = $Sprite2D
@onready var movement_animation_player = $AnimationPlayer
@onready var camera = $Camera2D
@onready var health_component = $HealthComponent
@onready var weapon = $Weapon
@onready var stamina_bar = $StaminaUI/TextureProgressBar
@onready var block_area = $BlockArea

@export var shake_power: float = 5.0
@export var shake_duration: float = 0.5

# Stamina system
@export var max_stamina: float = 100.0
var current_stamina: float = max_stamina
@export var stamina_regen_rate: float = 15.0
@export var stamina_consumption_rate: float = 25.0
@export var block_damage_reduction: float = 0.7
var is_blocking := false
var is_flashing := false

signal health_changed(new_health)
signal stamina_changed(new_stamina)
signal died

func _ready():
	if health_component:
		health_component.max_health = 100
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_death)
	else:
		push_error("HealthComponent not found!")
	
	current_stamina = max_stamina
	update_stamina_bar()

func _physics_process(delta):
	if weapon.is_attacking():
		return
	
	# Handle blocking
	var new_blocking_state = Input.is_action_pressed("block") and current_stamina > 0
	if new_blocking_state != is_blocking:
		is_blocking = new_blocking_state
		block_area.is_blocking = is_blocking
		if is_blocking and movement_animation_player.has_animation("block"):
			movement_animation_player.play("block")
		elif not is_blocking:
			movement_animation_player.play("idle")
	
	# Stamina management
	if is_blocking:
		current_stamina = max(current_stamina - stamina_consumption_rate * delta, 0)
		if current_stamina <= 0:
			is_blocking = false
			block_area.is_blocking = false
	else:
		current_stamina = min(current_stamina + stamina_regen_rate * delta, max_stamina)
	
	update_stamina_bar()
	emit_signal("stamina_changed", current_stamina)
	
	# Movement only when not blocking
	if !is_blocking:
		var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		# Sprite flipping
		if input_direction.x != 0:
			sprite.flip_h = input_direction.x < 0
			$Weapon.update_direction(input_direction.x < 0)
		
		velocity = input_direction * speed   
		move_and_slide()
		
		# Animation handling
		if velocity.length() > 0:
			if abs(velocity.x) > abs(velocity.y):
				movement_animation_player.play("walk_right" if velocity.x > 0 else "walk_left")
			else:
				movement_animation_player.play("walk_down" if velocity.y > 0 else "walk_up")
		elif movement_animation_player.has_animation("idle"):
			movement_animation_player.play("idle")

func update_stamina_bar():
	if stamina_bar:
		stamina_bar.value = current_stamina
		# Меняем цвет при низкой стамине
		stamina_bar.tint_progress = Color.RED if current_stamina < 30 else Color.GREEN

func _input(event):
	if event.is_action_pressed("attack") and !is_blocking:
		weapon.start_attack(velocity)

func _on_health_changed(current: float, _max_health: float):
	if health_component and current < health_component.current_health:
		# Apply reduced damage if blocking
		var actual_damage = health_component.current_health - current
		if is_blocking:
			actual_damage *= (1.0 - block_damage_reduction)
			flash_sprite(Color.BLUE, 0.1, 1)  # Different color for blocked hit
		else:
			flash_sprite(Color.RED, 0.1, 3)
			apply_knockback()
			camera.apply_shake(shake_power, shake_duration)
	
	health_changed.emit(current)

func _on_death():
	died.emit()
	if movement_animation_player.has_animation("death"):
		movement_animation_player.play("death")
	set_physics_process(false)
	camera.apply_shake(shake_power * 2, shake_duration * 1.5)
	await flash_sprite(Color.DARK_RED, 0.2, 5)
	if movement_animation_player.has_animation("death"):
		await movement_animation_player.animation_finished
	queue_free()

func flash_sprite(color: Color, duration: float, times: int = 1):
	if is_flashing or not sprite:
		return
		
	is_flashing = true
	for i in times:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", color, duration)
		tween.tween_property(sprite, "modulate", Color.WHITE, duration)
		await tween.finished
	is_flashing = false

func apply_knockback(power: float = 200.0):
	velocity = -velocity.normalized() * power
	move_and_slide()

func take_damage(damage: int):
	if health_component:
		health_component.take_damage(damage)

func heal(amount: int):
	if health_component:
		health_component.heal(amount)

func set_invincible(time: float):
	if health_component:
		health_component.set_invincible(time)
