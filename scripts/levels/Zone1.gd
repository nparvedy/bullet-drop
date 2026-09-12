extends Node2D
class_name Zone1

@export var respawn_delay: float = 5.0
@export var enemy_scene: PackedScene
@export var ammo_drop_scene: PackedScene

var enemies_alive: int = 7
var total_kills: int = 0
var emergency_drop_timer: float = 0.0
var next_emergency_drop_delay: float = 0.0
var player_has_zero_ammo: bool = false
var player_ref: Player = null

# Points d'apparition stratégiques répartis dans toutes les salles
var spawn_points: Array[Vector2] = [
	Vector2(450, 750),   # Salle Ouest (Entrepôt)
	Vector2(2350, 750),  # Salle Est (Labo)
	Vector2(1200, 650),  # Grand Hall Ouest
	Vector2(1600, 650),  # Grand Hall Est
	Vector2(1400, 200),  # Salle Nord (Haut-Centre)
	Vector2(900, 300),   # Salle Nord (Haut-Gauche)
	Vector2(1900, 300)   # Salle Nord (Haut-Droite)
]

@onready var enemies_container: Node2D = $Entities/Enemies
@onready var drops_container: Node2D = $Entities/Drops
@onready var player_spawn: Marker2D = $PlayerSpawn

func _ready() -> void:
	if not enemy_scene:
		enemy_scene = load("res://scenes/entities/enemies/Enemy.tscn")
	if not ammo_drop_scene:
		ammo_drop_scene = load("res://scenes/weapons/AmmoDrop.tscn")
		
	if has_node("/root/EventBus"):
		EventBus.player_ammo_changed.connect(_on_player_ammo_changed)
		EventBus.enemy_died.connect(_on_enemy_died)

	# Initialisation du décompte des monstres
	call_deferred("_setup_enemies")
	
	# Recherche du joueur
	player_ref = get_tree().get_first_node_in_group("player") as Player

func _setup_enemies() -> void:
	var existing_enemies = get_tree().get_nodes_in_group("enemies")
	enemies_alive = existing_enemies.size()
	
	if has_node("/root/EventBus"):
		EventBus.zone_enemies_updated.emit(enemies_alive, total_kills)

func _process(delta: float) -> void:
	# Système de drop de secours (entre 5s et 10s uniquement quand le joueur a 0 munition)
	if player_has_zero_ammo:
		emergency_drop_timer += delta
		if emergency_drop_timer >= next_emergency_drop_delay:
			_spawn_emergency_ammo_drop()
			emergency_drop_timer = 0.0
			next_emergency_drop_delay = randf_range(5.0, 10.0)

func _on_player_ammo_changed(current: int, _max_ammo: int) -> void:
	if current <= 0:
		if not player_has_zero_ammo:
			player_has_zero_ammo = true
			emergency_drop_timer = 0.0
			next_emergency_drop_delay = randf_range(5.0, 10.0)
	else:
		player_has_zero_ammo = false
		emergency_drop_timer = 0.0

func _spawn_emergency_ammo_drop() -> void:
	if not ammo_drop_scene:
		return
		
	var drop = ammo_drop_scene.instantiate()
	drop.ammo_amount = 5
	
	# Position aléatoire dans l'une des salles explorables
	var drop_rooms = [
		Vector2(randf_range(300, 750), randf_range(650, 1050)),    # Salle Ouest
		Vector2(randf_range(1100, 1700), randf_range(650, 1050)),  # Grand Hall
		Vector2(randf_range(2050, 2550), randf_range(650, 1050)),  # Salle Est
		Vector2(randf_range(600, 2200), randf_range(250, 420)),    # Salle Nord
		Vector2(randf_range(1200, 1600), randf_range(1300, 1550))  # Salle Sud
	]
	drop.global_position = drop_rooms.pick_random()
	
	if drops_container:
		drops_container.add_child(drop)
	else:
		add_child(drop)
		
	if has_node("/root/EventBus"):
		EventBus.emergency_drop_spawned.emit(drop.global_position)

func _on_enemy_died(_enemy: Node2D, _pos: Vector2) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	total_kills += 1
	
	if has_node("/root/EventBus"):
		EventBus.zone_enemies_updated.emit(enemies_alive, total_kills)
		
	# Respawn du monstre après 5 secondes
	get_tree().create_timer(respawn_delay).timeout.connect(_respawn_single_enemy)

func _respawn_single_enemy() -> void:
	if not enemy_scene or not is_inside_tree():
		return
		
	var new_enemy = enemy_scene.instantiate()
	
	# Choix d'un point d'apparition parmi les salles
	var spawn_pos = spawn_points.pick_random()
	new_enemy.global_position = spawn_pos
	
	# Configuration aléatoire du monstre (100 à 200 HP, 60% tireur / 40% chasseur)
	var hp = round(randf_range(100.0, 200.0))
	new_enemy.max_health = hp
	new_enemy.current_health = hp
	new_enemy.can_shoot = (randf() > 0.4)
	
	if enemies_container:
		enemies_container.add_child(new_enemy)
	else:
		add_child(new_enemy)
		
	enemies_alive += 1
	if has_node("/root/EventBus"):
		EventBus.zone_enemies_updated.emit(enemies_alive, total_kills)
