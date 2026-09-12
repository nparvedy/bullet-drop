extends Node2D
class_name Weapon

@export var bullet_scene: PackedScene
@export var weapon_name: String = "Pistolet de Survie"
@export var base_damage: float = 120.0
@export var base_fire_rate: float = 0.5 # 0.5s = 2 tirs par seconde
@export var max_ammo: int = 100
@export var current_ammo: int = 100
@export var bullet_speed: float = 950.0
@export var orbit_distance: float = 24.0

var can_shoot: bool = true
var fire_cooldown_timer: float = 0.0
var recoil_offset: float = 0.0

# Modificateurs de statistiques
var damage_multiplier: float = 1.0
var crit_chance: float = 0.0
var crit_multiplier: float = 1.5
var fire_rate_bonus: float = 0.0 # Balle supplémentaire par seconde

@onready var muzzle: Marker2D = $Muzzle
@onready var gun_sprite: Sprite2D = $GunSprite

func _ready() -> void:
	if not bullet_scene:
		bullet_scene = load("res://scenes/weapons/Bullet.tscn")
		
	# Chargement des améliorations persistantes depuis SaveManager
	_apply_persistent_upgrades()
	
	if is_inside_tree():
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.player_ammo_changed.emit(current_ammo, max_ammo)

func _apply_persistent_upgrades() -> void:
	if not is_inside_tree():
		return
	var save_mgr = get_node_or_null("/root/SaveManager")
	if not save_mgr:
		return
	
	var dmg_lvl = save_mgr.upgrades.get("damage_boost", 0)
	damage_multiplier += dmg_lvl * 0.10
	
	var crit_c_lvl = save_mgr.upgrades.get("crit_chance", 0)
	crit_chance += crit_c_lvl * 0.05
	
	var crit_d_lvl = save_mgr.upgrades.get("crit_damage", 0)
	crit_multiplier += crit_d_lvl * 0.25
	
	var fr_lvl = save_mgr.upgrades.get("fire_rate_boost", 0)
	fire_rate_bonus += fr_lvl * 0.2
	
	var ammo_lvl = save_mgr.upgrades.get("starting_ammo", 0)
	max_ammo += ammo_lvl * 25
	current_ammo = max_ammo

func get_effective_fire_delay() -> float:
	var shots_per_sec = (1.0 / base_fire_rate) + fire_rate_bonus
	return max(0.08, 1.0 / shots_per_sec)

func _process(delta: float) -> void:
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
	
	# Orientation du sprite pour qu'il ne soit pas à l'envers
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
	fire_cooldown_timer = get_effective_fire_delay()
	recoil_offset = 6.0

	_spawn_bullet()
	
	if is_inside_tree():
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.player_ammo_changed.emit(current_ammo, max_ammo)
	
	return true

func _spawn_bullet() -> void:
	if not bullet_scene:
		return
	
	var bullet_inst = bullet_scene.instantiate()
	
	# Calcul du critique
	var is_crit = (randf() < crit_chance)
	var final_damage = base_damage * damage_multiplier * (crit_multiplier if is_crit else 1.0)
	
	bullet_inst.damage = final_damage
	bullet_inst.is_crit = is_crit
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
	if is_inside_tree():
		var eb = get_node_or_null("/root/EventBus")
		if eb:
			eb.player_ammo_changed.emit(current_ammo, max_ammo)

func add_damage_percent(pct: float) -> void:
	damage_multiplier += pct

func add_fire_rate_bonus(bonus_shots_per_sec: float) -> void:
	fire_rate_bonus += bonus_shots_per_sec
