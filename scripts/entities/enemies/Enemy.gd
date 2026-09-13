extends CharacterBody2D
class_name Enemy

signal died(enemy)

@export var level: int = 1
@export var zone_number: int = 1
@export var max_health: float = 200.0
@export var current_health: float = 200.0
@export var move_speed: float = 95.0
@export var damage: float = 30.0

@export_group("Capacités de Combat")
@export var can_shoot: bool = false
@export var shoot_interval: float = 1.0
@export var bullet_scene: PackedScene
@export var ammo_drop_scene: PackedScene
@export var bonus_drop_scene: PackedScene

# États d'IA
enum State { CHASE, DODGE, PAUSE }
var current_state: State = State.CHASE
var state_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO
var next_dodge_time: float = 2.5

# Tir
var shoot_timer: float = 0.0

# Affichage barre de vie temporaire (3 secondes)
var health_bar_visible_timer: float = 0.0
var hit_flash_timer: float = 0.0
var target_player: Node2D = null
var look_angle: float = 0.0

@onready var body_sprite: Sprite2D = $BodySprite
@onready var eyes_container: Node2D = $Eyes
@onready var eyes_base: Sprite2D = $Eyes/EyesBase
@onready var pupils: Sprite2D = $Eyes/Pupils
@onready var gun_sprite: Sprite2D = $GunSprite

@onready var health_bar_container: Node2D = $HealthBarContainer
@onready var health_bar_bg: ColorRect = $HealthBarContainer/Bg
@onready var health_bar_fill: ColorRect = $HealthBarContainer/Fill
@onready var health_bar_damage_lag: ColorRect = $HealthBarContainer/DamageLag

var displayed_health_pct: float = 1.0
var tween_health: Tween

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	
	if not bullet_scene:
		bullet_scene = load("res://scenes/weapons/Bullet.tscn")
	if not ammo_drop_scene:
		ammo_drop_scene = load("res://scenes/weapons/AmmoDrop.tscn")
	if not bonus_drop_scene:
		bonus_drop_scene = load("res://scenes/weapons/BonusDrop.tscn")

	_apply_level_stats()

	_update_appearance()

	next_dodge_time = randf_range(2.0, 4.0)
	shoot_timer = randf_range(0.2, shoot_interval)

	if health_bar_container:
		health_bar_container.visible = false

func set_enemy_level(new_level: int, new_zone: int = 1) -> void:
	level = new_level
	zone_number = new_zone
	_apply_level_stats()

func _apply_level_stats() -> void:
	var stats = {}
	var db = get_node_or_null("/root/MonsterStatsDatabase") if is_inside_tree() else null
	if db:
		stats = db.get_monster_stats(level)
	else:
		stats = {
			"max_health": 200.0 + (level - 1) * 50.0,
			"damage": 30.0 + (level - 1) * 6.0,
			"fire_rate": max(0.5, 1.0 - (level - 1) * 0.05),
			"move_speed": 95.0 + (level - 1) * 5.0
		}
	
	max_health = stats.get("max_health", 200.0)
	current_health = max_health
	damage = stats.get("damage", 30.0)
	shoot_interval = stats.get("fire_rate", 1.0)
	move_speed = stats.get("move_speed", 95.0)

func _update_appearance() -> void:
	if body_sprite:
		if can_shoot:
			body_sprite.texture = preload("res://assets/sprites/enemies/enemy_shooter.png")
		else:
			body_sprite.texture = preload("res://assets/sprites/enemies/enemy_chaser.png")
	if gun_sprite:
		gun_sprite.visible = can_shoot

func _physics_process(delta: float) -> void:
	_find_player()
	
	if target_player and is_instance_valid(target_player):
		var to_player = target_player.global_position - global_position
		look_angle = to_player.angle()
		
		state_timer += delta
		match current_state:
			State.CHASE:
				if state_timer >= next_dodge_time:
					_start_dodge(to_player)
				else:
					velocity = to_player.normalized() * move_speed
					move_and_slide()
					
			State.DODGE:
				velocity = dodge_direction * (move_speed * 1.35)
				move_and_slide()
				if state_timer >= 0.7:
					current_state = State.CHASE
					state_timer = 0.0
					next_dodge_time = randf_range(2.5, 4.5)
					
			State.PAUSE:
				velocity = velocity.move_toward(Vector2.ZERO, move_speed * 6.0 * delta)
				move_and_slide()
				if state_timer >= 0.3:
					current_state = State.DODGE
					state_timer = 0.0
		
		# Tir ennemi
		if can_shoot:
			shoot_timer += delta
			if shoot_timer >= shoot_interval:
				shoot_timer = 0.0
				_shoot_at_player(to_player.normalized())
	else:
		velocity = Vector2.ZERO

func _process(delta: float) -> void:
	if health_bar_visible_timer > 0.0:
		health_bar_visible_timer -= delta
		if health_bar_visible_timer <= 0.0:
			if health_bar_container:
				health_bar_container.visible = false

	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if body_sprite:
			body_sprite.modulate = Color(1.8, 1.8, 1.8)
	else:
		if body_sprite:
			body_sprite.modulate = Color.WHITE

	if target_player and is_instance_valid(target_player):
		var dir_to_p = (target_player.global_position - global_position).normalized()
		if eyes_container:
			eyes_container.position = dir_to_p * 4.0
		if pupils:
			pupils.position = dir_to_p * 2.5
		if gun_sprite and can_shoot:
			gun_sprite.position = dir_to_p * 15.0
			gun_sprite.rotation = dir_to_p.angle()
			gun_sprite.flip_v = abs(dir_to_p.angle()) > PI / 2.0

func _start_dodge(to_player: Vector2) -> void:
	current_state = State.PAUSE
	state_timer = 0.0
	
	var perp = Vector2(-to_player.y, to_player.x).normalized()
	if randf() > 0.5:
		perp = -perp
	dodge_direction = perp

func _shoot_at_player(dir: Vector2) -> void:
	if not bullet_scene:
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.is_enemy_bullet = true
	bullet.damage = damage
	bullet.speed = 650.0
	bullet.direction = dir
	bullet.rotation = dir.angle()
	bullet.global_position = global_position + dir * 20.0
	
	# Ajout au parent direct (la Room ou le Niveau)
	if get_parent():
		get_parent().add_child(bullet)

func _find_player() -> void:
	if not target_player or not is_instance_valid(target_player):
		if is_inside_tree() and get_tree():
			target_player = get_tree().get_first_node_in_group("player") as Node2D

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	hit_flash_timer = 0.12
	health_bar_visible_timer = 3.0
	
	if health_bar_container:
		health_bar_container.visible = true
	
	_animate_health_bar()
	
	var bus = get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		bus.enemy_damaged.emit(self, current_health, max_health)
		
	if current_health <= 0.0:
		_die()

func _animate_health_bar() -> void:
	var target_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_width = 36.0
	
	if health_bar_fill:
		health_bar_fill.size.x = bar_width * target_pct
		if target_pct > 0.5:
			health_bar_fill.color = Color(0.2, 0.85, 0.3)
		elif target_pct > 0.25:
			health_bar_fill.color = Color(0.95, 0.7, 0.15)
		else:
			health_bar_fill.color = Color(0.9, 0.2, 0.2)

	if health_bar_damage_lag:
		if tween_health and tween_health.is_valid():
			tween_health.kill()
		tween_health = create_tween()
		tween_health.tween_property(health_bar_damage_lag, "size:x", bar_width * target_pct, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _die() -> void:
	died.emit(self)
	
	var pts = 1
	var db = get_node_or_null("/root/MonsterStatsDatabase") if is_inside_tree() else null
	if db:
		pts = db.calculate_kill_points(level, zone_number)
	var sm = get_node_or_null("/root/SaveManager") if is_inside_tree() else null
	if sm:
		sm.add_run_points(pts)
		
	_spawn_drops()
	
	var bus = get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		bus.enemy_died.emit(self, global_position, pts)
		
	set_physics_process(false)
	set_process(false)
	
	var tween = create_tween()
	if tween:
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _spawn_drops() -> void:
	var target_container = get_parent()
	if not target_container:
		return
	
	# Drop de munitions
	if ammo_drop_scene:
		var drop = ammo_drop_scene.instantiate()
		drop.global_position = global_position
		drop.ammo_amount = 5
		target_container.call_deferred("add_child", drop)
	
	# Drop de bonus
	var bonus_chance = 0.20
	var sm = get_node_or_null("/root/SaveManager") if is_inside_tree() else null
	if sm:
		var bonus_lvl = sm.upgrades.get("bonus_drop_rate", 0)
		bonus_chance += bonus_lvl * 0.05
		
	if randf() <= bonus_chance and bonus_drop_scene:
		var bonus = bonus_drop_scene.instantiate()
		bonus.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		target_container.call_deferred("add_child", bonus)