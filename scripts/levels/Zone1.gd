extends Node2D
class_name Zone1

@export var total_monsters: int = 5
@export var ammo_drop_scene: PackedScene

var enemies_alive: int = 5
var emergency_drop_timer: float = 0.0
var next_emergency_drop_delay: float = 0.0
var player_has_zero_ammo: bool = false
var player_ref: Player = null

@onready var enemies_container: Node2D = $Entities/Enemies
@onready var drops_container: Node2D = $Entities/Drops
@onready var player_spawn: Marker2D = $PlayerSpawn

func _ready() -> void:
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
	total_monsters = enemies_alive
	
	if has_node("/root/EventBus"):
		EventBus.zone_enemies_updated.emit(enemies_alive, total_monsters)

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
	
	# Position aléatoire dans l'arène (autour de la zone jouable)
	var rand_x = randf_range(400.0, 1500.0)
	var rand_y = randf_range(250.0, 850.0)
	drop.global_position = Vector2(rand_x, rand_y)
	
	if drops_container:
		drops_container.add_child(drop)
	else:
		add_child(drop)
		
	if has_node("/root/EventBus"):
		EventBus.emergency_drop_spawned.emit(drop.global_position)

func _on_enemy_died(_enemy: Node2D, _pos: Vector2) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	if has_node("/root/EventBus"):
		EventBus.zone_enemies_updated.emit(enemies_alive, total_monsters)
		
	if enemies_alive <= 0:
		_on_zone_completed()

func _on_zone_completed() -> void:
	print("Zone 1 nettoyée ! Tous les monstres ont été éliminés.")
