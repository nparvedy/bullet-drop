extends Node2D
class_name Weapon

@export var bullet_scene: PackedScene
@export var weapon_name: String = "Pistolet de Survie"
@export var base_damage: float = 120.0
@export var fire_rate: float = 0.5 # 0.5s entre chaque tir
@export var max_ammo: int = 100
@export var current_ammo: int = 100
@export var bullet_speed: float = 950.0
@export var orbit_distance: float = 24.0

var can_shoot: bool = true
var fire_cooldown_timer: float = 0.0
var recoil_offset: float = 0.0

@onready var muzzle: Marker2D = $Muzzle
@onready var gun_sprite: Sprite2D = $GunSprite

func _ready() -> void:
	if not bullet_scene:
		bullet_scene = load("res://scenes/weapons/Bullet.tscn")
	if has_node("/root/EventBus"):
		EventBus.player_ammo_changed.emit(current_ammo, max_ammo)

func _process(delta: float) -> void:
	# Gestion du cooldown de tir (0.5s)
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer -= delta
		if fire_cooldown_timer <= 0.0:
			can_shoot = true

	# Recul de l'arme
	if recoil_offset > 0.0:
		recoil_offset = max(0.0, recoil_offset - delta * 25.0)
		if gun_sprite:
			gun_sprite.position.x = 6.0 - recoil_offset

	_aim_at_mouse()

func _aim_at_mouse() -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	rotation = dir.angle()
	
	# Gestion du flip vertical pour que le pistolet reste droit
	if gun_sprite:
		if abs(rotation) > PI / 2.0:
			gun_sprite.flip_v = true
			if muzzle:
				muzzle.position.y = 1.0
		else:
			gun_sprite.flip_v = false
			if muzzle:
				muzzle.position.y = -1.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		try_shoot()

func try_shoot() -> bool:
	if not can_shoot:
		return false
	
	if current_ammo <= 0:
		_play_empty_click()
		return false

	# Tir effectif
	current_ammo -= 1
	can_shoot = false
	fire_cooldown_timer = fire_rate
	recoil_offset = 6.0

	_spawn_bullet()
	
	if has_node("/root/EventBus"):
		EventBus.player_ammo_changed.emit(current_ammo, max_ammo)
	
	return true

func _spawn_bullet() -> void:
	if not bullet_scene:
		return
	
	var bullet_inst = bullet_scene.instantiate()
	bullet_inst.damage = base_damage
	bullet_inst.speed = bullet_speed
	bullet_inst.is_enemy_bullet = false
	
	var spawn_pos = muzzle.global_position if muzzle else global_position + Vector2.RIGHT.rotated(rotation) * 20.0
	bullet_inst.global_position = spawn_pos
	bullet_inst.direction = Vector2.RIGHT.rotated(rotation)
	bullet_inst.rotation = rotation
	
	var level_root = get_tree().current_scene
	if level_root:
		level_root.add_child(bullet_inst)
	else:
		get_parent().add_child(bullet_inst)

func _play_empty_click() -> void:
	recoil_offset = 2.0

func add_ammo(amount: int) -> void:
	current_ammo = min(current_ammo + amount, 999)
	if has_node("/root/EventBus"):
		EventBus.player_ammo_changed.emit(current_ammo, max_ammo)
