extends CharacterBody2D
class_name Player

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var max_shield: float = 0.0
@export var current_shield: float = 0.0
@export var armor: float = 0.0
@export var hp_regen: float = 5.0 # 5 PV par seconde
@export var move_speed: float = 260.0

@export_group("Esquive / Dash")
@export var max_dash_charges: int = 1
var current_dash_charges: int = 1
@export var dash_speed: float = 850.0
@export var dash_duration: float = 0.18
@export var base_dash_cooldown: float = 2.0
var dash_cooldown: float = 2.0
var dash_recharge_timer: float = 0.0

var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

var is_invulnerable: bool = false
var hurt_flash_timer: float = 0.0
var look_angle: float = 0.0
var magnet_radius: float = 120.0

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
	
	_load_permanent_upgrades()
	
	current_health = max_health
	current_shield = max_shield
	current_dash_charges = max_dash_charges
	dash_cooldown = base_dash_cooldown
	
	_emit_health_updated()
	_emit_dash_updated()

func _load_permanent_upgrades() -> void:
	if not is_inside_tree():
		return
	var save_mgr = get_node_or_null("/root/SaveManager")
	if not save_mgr:
		return
		
	var hp_lvl = save_mgr.upgrades.get("max_hp_boost", 0)
	max_health += hp_lvl * 20.0
	
	var shield_lvl = save_mgr.upgrades.get("starting_shield", 0)
	max_shield += shield_lvl * 20.0
	
	var armor_lvl = save_mgr.upgrades.get("armor", 0)
	armor += armor_lvl * 5.0
	
	var regen_lvl = save_mgr.upgrades.get("hp_regen_boost", 0)
	hp_regen += regen_lvl * 1.5
	
	var dash_lvl = save_mgr.upgrades.get("extra_dash", 0)
	max_dash_charges += dash_lvl
	
	var cd_lvl = save_mgr.upgrades.get("dash_cooldown", 0)
	dash_cooldown = max(0.8, base_dash_cooldown * (1.0 - cd_lvl * 0.15))
	
	var spd_lvl = save_mgr.upgrades.get("move_speed", 0)
	move_speed += spd_lvl * (260.0 * 0.08)
	
	var mag_lvl = save_mgr.upgrades.get("magnet_radius", 0)
	magnet_radius += mag_lvl * (120.0 * 0.35)

func _physics_process(delta: float) -> void:
	# Régénération passive des points de vie
	if current_health < max_health and current_health > 0:
		current_health = min(max_health, current_health + hp_regen * delta)
		_emit_health_updated()

	# Recharge des charges de Dash
	if current_dash_charges < max_dash_charges:
		dash_recharge_timer += delta
		if dash_recharge_timer >= dash_cooldown:
			dash_recharge_timer = 0.0
			current_dash_charges = min(max_dash_charges, current_dash_charges + 1)
		_emit_dash_updated()

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

	# Contrôles de déplacement normaux
	var input_vector = _get_movement_input()
	
	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 12.0 * delta)
	
	move_and_slide()

	# Détection de l'input d'esquive
	if Input.is_action_just_pressed("dash") and current_dash_charges > 0:
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

	# Orientation du regard vers la souris
	var mouse_pos = get_global_mouse_position()
	var dir_to_mouse = (mouse_pos - global_position).normalized()
	var dist_to_mouse = global_position.distance_to(mouse_pos)
	var intensity = clamp(dist_to_mouse / 150.0, 0.0, 1.0)
	look_angle = dir_to_mouse.angle()
	
	if eyes_container:
		eyes_container.position = dir_to_mouse * (4.5 * intensity)
	if pupils:
		pupils.position = dir_to_mouse * (3.0 * intensity)
	
	if weapon:
		var weapon_offset = dir_to_mouse * 18.0
		weapon.position = weapon_offset

func _get_movement_input() -> Vector2:
	var move_vec = Vector2.ZERO
	
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_vec.y -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_vec.y += 1.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_vec.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_vec.x += 1.0
		
	return move_vec.clamp(Vector2(-1, -1), Vector2(1, 1))

func _start_dash() -> void:
	is_dashing = true
	is_invulnerable = true
	dash_time_left = dash_duration
	current_dash_charges -= 1
	ghost_timer = 0.0
	
	var mouse_pos = get_global_mouse_position()
	dash_direction = (mouse_pos - global_position).normalized()
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT
		
	_emit_dash_updated()

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
		return
	
	# Réduction par l'armure
	var incoming_dmg = amount
	if armor > 0.0:
		var reduction_factor = 100.0 / (100.0 + armor * 4.0)
		incoming_dmg = max(1.0, amount * reduction_factor)
	
	# Absorption par le bouclier
	if current_shield > 0.0:
		if current_shield >= incoming_dmg:
			current_shield -= incoming_dmg
			incoming_dmg = 0.0
		else:
			incoming_dmg -= current_shield
			current_shield = 0.0
	
	# Dégâts sur les PV
	if incoming_dmg > 0.0:
		current_health = max(0.0, current_health - incoming_dmg)
	
	hurt_flash_timer = 0.15
	_emit_health_updated()
	
	if current_health <= 0.0:
		_die()

func get_weapon() -> Weapon:
	if not weapon:
		weapon = get_node_or_null("Weapon") as Weapon
	return weapon

func apply_bonus(type: int) -> void:
	match type:
		0: # BonusType.DAMAGE
			var w = get_weapon()
			if w:
				w.add_damage_percent(0.20)
		1: # BonusType.MAX_HP
			var extra = max_health * 0.50
			max_health += extra
			current_health = min(max_health, current_health + extra)
			_emit_health_updated()
		2: # BonusType.FIRE_RATE
			var w = get_weapon()
			if w:
				w.add_fire_rate_bonus(1.0)
		3: # BonusType.SHIELD
			if max_shield <= 0:
				max_shield = 20.0
				current_shield = 20.0
			else:
				max_shield = round(max_shield * 1.20)
				current_shield = max_shield
			_emit_health_updated()
		4: # BonusType.REGEN
			hp_regen = hp_regen * 1.50
		5: # BonusType.EXTRA_DASH
			max_dash_charges += 1
			current_dash_charges += 1
			_emit_dash_updated()

func _emit_health_updated() -> void:
	if is_inside_tree():
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.player_health_changed.emit(int(ceil(current_health)), int(ceil(max_health)), int(ceil(current_shield)), int(ceil(max_shield)))

func _emit_dash_updated() -> void:
	if is_inside_tree():
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			var pct = 1.0
			if current_dash_charges < max_dash_charges and dash_cooldown > 0.0:
				pct = clamp(dash_recharge_timer / dash_cooldown, 0.0, 1.0)
			eb.player_dash_updated.emit(current_dash_charges, max_dash_charges, pct)

func get_magnet_radius() -> float:
	return magnet_radius

func _die() -> void:
	if is_inside_tree():
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.player_died.emit()
	set_physics_process(false)
	set_process(false)
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
