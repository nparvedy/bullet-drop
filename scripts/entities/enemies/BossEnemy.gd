extends CharacterBody2D
class_name BossEnemy

signal died(boss)

@export var max_health: float = 3000.0
@export var current_health: float = 3000.0
@export var move_speed: float = 75.0
@export var bullet_damage: float = 100.0
@export var aoe_damage: float = 100.0
@export var fire_rate: float = 0.5
@export var level: int = 5
@export var zone_number: int = 1

@export var bullet_scene: PackedScene
@export var ammo_drop_scene: PackedScene
@export var bonus_drop_scene: PackedScene

enum BossPattern {
	DUAL_FIRE,      # Les 2 pistolets tirent en même temps
	ALTERNATING,    # Les 2 pistolets tirent en alternance
	AOE_ZONE        # Attaque de zone de balles télégraphiée
}

var current_pattern: BossPattern = BossPattern.DUAL_FIRE
var pattern_switch_timer: float = 0.0
var pattern_duration: float = 6.0

# Timers d'attaque
var shoot_timer: float = 0.0
var alternate_turn: int = 0
var aoe_cooldown_timer: float = 4.0
var is_charging_aoe: bool = false
var aoe_charge_time: float = 0.0

var target_player: Node2D = null
var hit_flash_timer: float = 0.0

@onready var body_sprite: Sprite2D = $BodySprite
@onready var eyes_container: Node2D = $Eyes
@onready var left_gun: Node2D = $LeftGun
@onready var right_gun: Node2D = $RightGun
@onready var left_muzzle: Marker2D = $LeftGun/LeftMuzzle
@onready var right_muzzle: Marker2D = $RightGun/RightMuzzle
@onready var aoe_telegraph: Node2D = $AoETelegraph
@onready var aoe_circle: Polygon2D = $AoETelegraph/Circle

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	
	if not bullet_scene:
		bullet_scene = load("res://scenes/weapons/Bullet.tscn")
	if not ammo_drop_scene:
		ammo_drop_scene = load("res://scenes/weapons/AmmoDrop.tscn")
	if not bonus_drop_scene:
		bonus_drop_scene = load("res://scenes/weapons/BonusDrop.tscn")

	# Stats du Boss depuis la base de données
	var db = get_node_or_null("/root/MonsterStatsDatabase")
	if db:
		var stats = db.get_boss_stats()
		max_health = stats.get("max_health", 3000.0)
		bullet_damage = stats.get("bullet_damage", 100.0)
		aoe_damage = stats.get("aoe_damage", 100.0)
		fire_rate = stats.get("fire_rate", 0.5)
	
	current_health = max_health
	
	if aoe_telegraph:
		aoe_telegraph.visible = false
		_build_telegraph_circle()
		
	var eb = get_node_or_null("/root/EventBus")
	if eb:
		eb.boss_spawned.emit("BOSS TITAN", max_health)
		eb.boss_health_changed.emit(current_health, max_health)

func _build_telegraph_circle() -> void:
	var points = PackedVector2Array()
	var radius = 130.0
	for i in range(32):
		var angle = (i / 32.0) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	aoe_circle.polygon = points

func _physics_process(delta: float) -> void:
	_find_player()
	
	if not target_player or not is_instance_valid(target_player):
		velocity = Vector2.ZERO
		return
	
	var to_player = target_player.global_position - global_position
	var dist = to_player.length()
	
	# Rotation des armes indépendantes orientées vers le joueur
	_aim_guns(target_player.global_position)
	
	# Gestion du changement de pattern
	pattern_switch_timer += delta
	if pattern_switch_timer >= pattern_duration:
		pattern_switch_timer = 0.0
		_switch_pattern()

	# Gestion de l'attaque AoE
	if is_charging_aoe:
		velocity = Vector2.ZERO
		aoe_charge_time -= delta
		if aoe_telegraph:
			aoe_telegraph.global_position = aoe_telegraph.global_position.lerp(target_player.global_position, 0.05)
			aoe_circle.modulate.a = 0.3 + 0.4 * sin(aoe_charge_time * 15.0)
		if aoe_charge_time <= 0.0:
			_execute_aoe_attack()
		return

	# Déplacement : maintien d'une distance de combat
	if dist > 350.0:
		velocity = to_player.normalized() * move_speed
	elif dist < 220.0:
		velocity = -to_player.normalized() * (move_speed * 0.7)
	else:
		# Mouvement latéral circulaire
		var side_dir = Vector2(-to_player.y, to_player.x).normalized()
		velocity = side_dir * (move_speed * 0.6)
	
	move_and_slide()
	
	# Exécution du tir selon le pattern actif
	shoot_timer += delta
	match current_pattern:
		BossPattern.DUAL_FIRE:
			if shoot_timer >= fire_rate:
				shoot_timer = 0.0
				_fire_dual_guns()
		BossPattern.ALTERNATING:
			if shoot_timer >= (fire_rate * 0.5):
				shoot_timer = 0.0
				_fire_alternating_guns()
		BossPattern.AOE_ZONE:
			if not is_charging_aoe:
				_start_aoe_attack()

func _switch_pattern() -> void:
	var next_patterns = [BossPattern.DUAL_FIRE, BossPattern.ALTERNATING, BossPattern.AOE_ZONE]
	next_patterns.erase(current_pattern)
	current_pattern = next_patterns.pick_random()

func _aim_guns(target_pos: Vector2) -> void:
	if left_gun:
		var dir_l = (target_pos - left_gun.global_position).normalized()
		left_gun.rotation = dir_l.angle()
		var sprite_l = left_gun.get_node_or_null("Sprite2D")
		if sprite_l:
			sprite_l.flip_v = abs(left_gun.rotation) > PI / 2.0
			
	if right_gun:
		var dir_r = (target_pos - right_gun.global_position).normalized()
		right_gun.rotation = dir_r.angle()
		var sprite_r = right_gun.get_node_or_null("Sprite2D")
		if sprite_r:
			sprite_r.flip_v = abs(right_gun.rotation) > PI / 2.0

func _fire_dual_guns() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	_spawn_single_bullet(left_muzzle.global_position, (target_player.global_position - left_muzzle.global_position).normalized())
	_spawn_single_bullet(right_muzzle.global_position, (target_player.global_position - right_muzzle.global_position).normalized())

func _fire_alternating_guns() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	if alternate_turn == 0:
		_spawn_single_bullet(left_muzzle.global_position, (target_player.global_position - left_muzzle.global_position).normalized())
		alternate_turn = 1
	else:
		_spawn_single_bullet(right_muzzle.global_position, (target_player.global_position - right_muzzle.global_position).normalized())
		alternate_turn = 0

func _spawn_single_bullet(pos: Vector2, dir: Vector2) -> void:
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	bullet.is_enemy_bullet = true
	bullet.damage = bullet_damage
	bullet.speed = 600.0
	bullet.direction = dir
	bullet.rotation = dir.angle()
	bullet.global_position = pos
	
	var level_root = get_tree().current_scene
	if level_root:
		level_root.add_child(bullet)
	else:
		get_parent().add_child(bullet)

func _start_aoe_attack() -> void:
	is_charging_aoe = true
	aoe_charge_time = 1.2
	if aoe_telegraph:
		aoe_telegraph.visible = true
		if target_player and is_instance_valid(target_player):
			aoe_telegraph.global_position = target_player.global_position

func _execute_aoe_attack() -> void:
	is_charging_aoe = false
	var strike_pos = aoe_telegraph.global_position if aoe_telegraph else global_position
	if aoe_telegraph:
		aoe_telegraph.visible = false
	
	var num_bullets = 12
	for i in range(num_bullets):
		var angle = (float(i) / float(num_bullets)) * TAU
		var dir = Vector2(cos(angle), sin(angle))
		_spawn_single_bullet(strike_pos, dir)
	
	if target_player and is_instance_valid(target_player):
		if strike_pos.distance_to(target_player.global_position) <= 130.0:
			target_player.take_damage(aoe_damage)
			
	current_pattern = BossPattern.DUAL_FIRE

func _process(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if body_sprite:
			body_sprite.modulate = Color(2.0, 2.0, 2.0)
	else:
		if body_sprite:
			body_sprite.modulate = Color(1.0, 0.25, 0.25)
			
	if target_player and is_instance_valid(target_player) and eyes_container:
		var dir_p = (target_player.global_position - global_position).normalized()
		eyes_container.position = dir_p * 6.0

func _find_player() -> void:
	if not target_player or not is_instance_valid(target_player):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target_player = players[0]

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	hit_flash_timer = 0.1
	
	var eb = get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if eb:
		eb.boss_health_changed.emit(current_health, max_health)
		
	if current_health <= 0.0:
		_die()

func _die() -> void:
	died.emit(self)
	
	var save_mgr = get_node_or_null("/root/SaveManager") if is_inside_tree() else null
	if save_mgr:
		save_mgr.add_run_points(25)
		
	_spawn_victory_drops()
	
	var eb = get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if eb:
		eb.boss_defeated.emit()
		eb.zone_cleared.emit()
		
	set_physics_process(false)
	set_process(false)
	
	var tween = create_tween()
	if tween:
		tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _spawn_victory_drops() -> void:
	var level_root = null
	if is_inside_tree() and get_tree():
		level_root = get_tree().current_scene
	if not level_root and get_parent():
		level_root = get_parent()
	if not level_root:
		return
		
	for i in range(3):
		if bonus_drop_scene:
			var b = bonus_drop_scene.instantiate()
			b.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			level_root.call_deferred("add_child", b)
	for i in range(2):
		if ammo_drop_scene:
			var a = ammo_drop_scene.instantiate()
			a.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			a.ammo_amount = 20
			level_root.call_deferred("add_child", a)
