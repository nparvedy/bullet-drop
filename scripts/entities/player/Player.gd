extends CharacterBody2D
class_name Player

@export var max_health: int = 100
@export var current_health: int = 100
@export var move_speed: float = 260.0

@export_group("Esquive / Dash")
@export var dash_speed: float = 850.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 2.0

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

var is_invulnerable: bool = false
var hurt_flash_timer: float = 0.0
var look_angle: float = 0.0

@onready var body_sprite: Sprite2D = $BodySprite
@onready var eyes_container: Node2D = $Eyes
@onready var eyes_base: Sprite2D = $Eyes/EyesBase
@onready var pupils: Sprite2D = $Eyes/Pupils
@onready var weapon: Weapon = $Weapon
@onready var camera: Camera2D = $Camera2D

# Ghost trail management
var ghost_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	# Collision Layer 2 (Player = 2), Mask 1 (World = 1) + 4 (Enemies = 4)
	collision_layer = 2
	collision_mask = 1 | 4
	
	if has_node("/root/EventBus"):
		EventBus.player_health_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
	# Timers de dash
	if dash_cooldown_left > 0.0:
		dash_cooldown_left -= delta
		if dash_cooldown_left <= 0.0:
			dash_cooldown_left = 0.0
			if has_node("/root/EventBus"):
				EventBus.player_dash_ready.emit()

	# Gestion du dash actif
	if is_dashing:
		dash_time_left -= delta
		velocity = dash_direction * dash_speed
		move_and_slide()
		
		# Effet visuel de traînée fantôme
		ghost_timer += delta
		if ghost_timer >= 0.04:
			ghost_timer = 0.0
			_spawn_dash_ghost()
			
		if dash_time_left <= 0.0:
			_end_dash()
		return

	# Contrôles de déplacement normaux (ZQSD + WASD + Flèches)
	var input_vector = _get_movement_input()
	
	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 12.0 * delta)
	
	move_and_slide()

	# Détection de l'input d'esquive (MAJ / Shift)
	if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
		_start_dash()

func _process(delta: float) -> void:
	# Flash de blessure / Dash modulate
	if hurt_flash_timer > 0.0:
		hurt_flash_timer -= delta
		if body_sprite:
			body_sprite.modulate = Color(1.0, 0.3, 0.3)
	elif is_dashing:
		if body_sprite:
			body_sprite.modulate = Color(0.6, 0.9, 1.0, 0.7)
	else:
		if body_sprite:
			body_sprite.modulate = Color.WHITE

	# Orientation du regard vers la souris avec les sprites PNG transparents
	var mouse_pos = get_global_mouse_position()
	var dir_to_mouse = (mouse_pos - global_position).normalized()
	var dist_to_mouse = global_position.distance_to(mouse_pos)
	var intensity = clamp(dist_to_mouse / 150.0, 0.0, 1.0)
	look_angle = dir_to_mouse.angle()
	
	# Déplacement des yeux et des pupilles selon la souris
	if eyes_container:
		eyes_container.position = dir_to_mouse * (4.5 * intensity)
	if pupils:
		pupils.position = dir_to_mouse * (3.0 * intensity)
	
	# Positionnement de l'arme autour du joueur
	if weapon:
		var weapon_offset = dir_to_mouse * 18.0
		weapon.position = weapon_offset

func _get_movement_input() -> Vector2:
	var move_vec = Vector2.ZERO
	
	# Lecture des actions si configurées
	if Input.is_action_pressed("move_up"):
		move_vec.y -= 1.0
	if Input.is_action_pressed("move_down"):
		move_vec.y += 1.0
	if Input.is_action_pressed("move_left"):
		move_vec.x -= 1.0
	if Input.is_action_pressed("move_right"):
		move_vec.x += 1.0
		
	# Fallbacks touches directes ZQSD / WASD
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_vec.y += 1.0
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_vec.x += 1.0
		
	return move_vec.clamp(Vector2(-1, -1), Vector2(1, 1))

func _start_dash() -> void:
	is_dashing = true
	is_invulnerable = true
	dash_time_left = dash_duration
	dash_cooldown_left = dash_cooldown
	ghost_timer = 0.0
	
	# Dash dans la direction de la souris
	var mouse_pos = get_global_mouse_position()
	dash_direction = (mouse_pos - global_position).normalized()
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT
		
	if has_node("/root/EventBus"):
		EventBus.player_dash_started.emit(dash_cooldown)

func _end_dash() -> void:
	is_dashing = false
	is_invulnerable = false
	if body_sprite:
		body_sprite.modulate = Color.WHITE

func _spawn_dash_ghost() -> void:
	var ghost = Sprite2D.new()
	ghost.texture = body_sprite.texture if body_sprite else null
	ghost.scale = body_sprite.scale if body_sprite else Vector2(0.5, 0.5)
	ghost.global_position = global_position
	ghost.modulate = Color(0.4, 0.8, 1.0, 0.5)
	ghost.z_index = z_index - 1
	var ghost_script = preload("res://scripts/entities/player/DashGhost.gd")
	ghost.set_script(ghost_script)
	get_parent().add_child(ghost)

func take_damage(amount: float) -> void:
	if is_invulnerable or is_dashing:
		return # Invulnérable pendant l'esquive
	
	current_health = int(max(0, current_health - amount))
	hurt_flash_timer = 0.15
	
	if has_node("/root/EventBus"):
		EventBus.player_health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		_die()

func _die() -> void:
	if has_node("/root/EventBus"):
		EventBus.player_died.emit()
	set_physics_process(false)
	set_process(false)
	# Disparition avec effet de réduction d'échelle
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.4)
	tween.tween_callback(queue_free)

func add_ammo(amount: int) -> void:
	if weapon:
		weapon.add_ammo(amount)

func get_current_ammo() -> int:
	if weapon:
		return weapon.current_ammo
	return 0
