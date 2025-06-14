extends CharacterBody2D

@export var speed = 300.0
@onready var sprite = $Sprite2D
@onready var movement_animation_player = $AnimationPlayer
@onready var camera = $Camera2D
@onready var health_component = $HealthComponent
@onready var weapon = $Weapon

@export var shake_power: float = 5.0
@export var shake_duration: float = 0.5

var is_flashing := false

signal health_changed(new_health)
signal died

func _ready():
	if health_component:
		health_component.max_health = 100
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_death)
	else:
		push_error("HealthComponent not found!")

func _physics_process(_delta):
	if weapon.is_attacking():
		return
		
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * speed
	move_and_slide()

	if velocity.length() > 0:
		if abs(velocity.x) > abs(velocity.y):
			movement_animation_player.play("walk_right" if velocity.x > 0 else "walk_left")
		else:
			movement_animation_player.play("walk_down" if velocity.y > 0 else "walk_up")
	else:
		movement_animation_player.play("idle")

func _input(event):
	if event.is_action_pressed("attack"):
		weapon.start_attack(velocity)

func _on_health_changed(current: float, _max_health: float):
	if health_component and current < health_component.current_health:
		flash_sprite(Color.RED, 0.1, 3)
		apply_knockback()
		camera.apply_shake(shake_power, shake_duration)
	
	health_changed.emit(current)

func _on_death():
	died.emit()
	movement_animation_player.play("death")
	set_physics_process(false)
	camera.apply_shake(shake_power * 2, shake_duration * 1.5)
	await flash_sprite(Color.DARK_RED, 0.2, 5)
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
