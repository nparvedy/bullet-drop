extends CharacterBody2D
class_name Enemy

@export var min_hp: float = 100.0
@export var max_hp: float = 200.0
@export var max_health: float = 150.0
@export var current_health: float = 150.0
@export var move_speed: float = 95.0

@export_group("Capacités de Combat")
@export var can_shoot: bool = false
@export var shoot_interval: float = 3.0
@export var bullet_scene: PackedScene
@export var ammo_drop_scene: PackedScene

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

@onready var health_bar_container: Node2D = $HealthBarContainer
@onready var health_bar_bg: ColorRect = $HealthBarContainer/Bg
@onready var health_bar_fill: ColorRect = $HealthBarContainer/Fill
@onready var health_bar_damage_lag: ColorRect = $HealthBarContainer/DamageLag

var displayed_health_pct: float = 1.0
var tween_health: Tween

func _ready() -> void:
	add_to_group("enemies")
	# Collision Layer 3 (Enemies = 4), Mask 1 (World = 1) + 2 (Player = 2) + 4 (Enemies = 4)
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	
	if not bullet_scene:
		bullet_scene = load("res://scenes/weapons/Bullet.tscn")
	if not ammo_drop_scene:
		ammo_drop_scene = load("res://scenes/weapons/AmmoDrop.tscn")

	# Initialisation aléatoire des PV entre 100 et 200 si pas définie manuellement
	if max_health == 150.0:
		max_health = round(randf_range(min_hp, max_hp))
	current_health = max_health
	displayed_health_pct = 1.0

	# Initialisation des timers
	next_dodge_time = randf_range(2.0, 4.0)
	shoot_timer = randf_range(0.5, shoot_interval) # Décalage initial pour ne pas tous tirer au même instant

	if health_bar_container:
		health_bar_container.visible = false

	queue_redraw()

func _physics_process(delta: float) -> void:
	_find_player()
	
	if target_player and is_instance_valid(target_player):
		var to_player = target_player.global_position - global_position
		look_angle = to_player.angle()
		
		# Machine à états de déplacement & esquive
		state_timer += delta
		match current_state:
			State.CHASE:
				if state_timer >= next_dodge_time:
					# Déclenche une esquive latérale
					_start_dodge(to_player)
				else:
					velocity = to_player.normalized() * move_speed
					move_and_slide()
					
			State.DODGE:
				velocity = dodge_direction * (move_speed * 1.35)
				move_and_slide()
				if state_timer >= 0.7: # Fin de l'esquive après 0.7s
					current_state = State.CHASE
					state_timer = 0.0
					next_dodge_time = randf_range(2.5, 4.5)
					
			State.PAUSE:
				velocity = velocity.move_toward(Vector2.ZERO, move_speed * 6.0 * delta)
				move_and_slide()
				if state_timer >= 0.3:
					current_state = State.DODGE
					state_timer = 0.0
		
		# Gestion du tir ennemi (toutes les 3 secondes)
		if can_shoot:
			shoot_timer += delta
			if shoot_timer >= shoot_interval:
				shoot_timer = 0.0
				_shoot_at_player(to_player.normalized())
	else:
		velocity = Vector2.ZERO

func _process(delta: float) -> void:
	# Gestion de la visibilité de la barre de vie (3 secondes après un coup)
	if health_bar_visible_timer > 0.0:
		health_bar_visible_timer -= delta
		if health_bar_visible_timer <= 0.0:
			if health_bar_container:
				health_bar_container.visible = false

	# Flash blanc/jaune de dégâts
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0:
			queue_redraw()

func _start_dodge(to_player: Vector2) -> void:
	current_state = State.PAUSE
	state_timer = 0.0
	
	# Direction perpendiculaire (gauche ou droite aléatoirement)
	var perp = Vector2(-to_player.y, to_player.x).normalized()
	if randf() > 0.5:
		perp = -perp
	dodge_direction = perp

func _shoot_at_player(dir: Vector2) -> void:
	if not bullet_scene:
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.is_enemy_bullet = true
	bullet.damage = 15.0
	bullet.speed = 650.0
	bullet.direction = dir
	bullet.rotation = dir.angle()
	bullet.global_position = global_position + dir * 20.0
	
	var level_root = get_tree().current_scene
	if level_root:
		level_root.add_child(bullet)
	else:
		get_parent().add_child(bullet)

func _find_player() -> void:
	if not target_player or not is_instance_valid(target_player):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target_player = players[0]

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	hit_flash_timer = 0.12
	health_bar_visible_timer = 3.0 # Reste visible 3 secondes
	
	if health_bar_container:
		health_bar_container.visible = true
	
	_animate_health_bar()
	
	if has_node("/root/EventBus"):
		EventBus.enemy_damaged.emit(self, current_health, max_health)
		
	if current_health <= 0.0:
		_die()
		
	queue_redraw()

func _animate_health_bar() -> void:
	var target_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_width = 36.0 # Largeur totale de la barre
	
	# Mise à jour immédiate de la barre verte/rouge de premier plan
	if health_bar_fill:
		health_bar_fill.size.x = bar_width * target_pct
		# Couleur dynamique
		if target_pct > 0.5:
			health_bar_fill.color = Color(0.2, 0.85, 0.3)
		elif target_pct > 0.25:
			health_bar_fill.color = Color(0.95, 0.7, 0.15)
		else:
			health_bar_fill.color = Color(0.9, 0.2, 0.2)

	# Animation fluide de descente de la barre de lag (blanc/orange)
	if health_bar_damage_lag:
		if tween_health and tween_health.is_valid():
			tween_health.kill()
		tween_health = create_tween()
		tween_health.tween_property(health_bar_damage_lag, "size:x", bar_width * target_pct, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _die() -> void:
	# Spawn du drop de 5 balles
	_spawn_ammo_drop()
	
	if has_node("/root/EventBus"):
		EventBus.enemy_died.emit(self, global_position)
		
	set_physics_process(false)
	set_process(false)
	
	# Animation d'explosion/disparition
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)

func _spawn_ammo_drop() -> void:
	if not ammo_drop_scene:
		return
	var drop = ammo_drop_scene.instantiate()
	drop.global_position = global_position
	drop.ammo_amount = 5
	
	var level_root = get_tree().current_scene
	if level_root:
		level_root.call_deferred("add_child", drop)
	else:
		get_parent().call_deferred("add_child", drop)

func _draw() -> void:
	# Ombre portée
	draw_circle(Vector2(0, 4), 16.0, Color(0, 0, 0, 0.3))

	var body_color = Color(0.85, 0.18, 0.18) # Rouge vif
	var border_color = Color(0.45, 0.06, 0.06) # Rouge très sombre
	
	if hit_flash_timer > 0.0:
		body_color = Color(1.0, 0.9, 0.9) # Flash blanc/impact

	# Corps circulaire du monstre
	draw_circle(Vector2.ZERO, 16.0, body_color)
	draw_arc(Vector2.ZERO, 16.0, 0, TAU, 32, border_color, 2.5)

	# Yeux menaçants orientés vers le joueur
	var look_dir = Vector2.RIGHT.rotated(look_angle)
	var eye_offset = look_dir * 5.0
	var eye_perp = Vector2(-look_dir.y, look_dir.x) * 4.5
	
	var left_eye = eye_offset + eye_perp
	var right_eye = eye_offset - eye_perp
	
	# Yeux jaunes/rouges menaçants
	draw_circle(left_eye, 3.2, Color(1.0, 0.9, 0.3))
	draw_circle(right_eye, 3.2, Color(1.0, 0.9, 0.3))
	
	# Pupilles sombres fendues
	draw_circle(left_eye + look_dir * 1.0, 1.6, Color(0.3, 0.0, 0.0))
	draw_circle(right_eye + look_dir * 1.0, 1.6, Color(0.3, 0.0, 0.0))

	# Si c'est un tireur, on dessine une arme sur le côté
	if can_shoot:
		var gun_pos = look_dir * 14.0
		var gun_angle = look_angle
		# Petit canon d'arme
		draw_line(gun_pos, gun_pos + look_dir * 8.0, Color(0.2, 0.2, 0.25), 4.0)
		draw_circle(gun_pos + look_dir * 8.0, 2.5, Color(0.1, 0.1, 0.15))
