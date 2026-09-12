extends Node2D
class_name Room

signal room_completed(room_index: int)

enum SpawnMode {
	ALL_AT_ONCE,
	WAVES,
	PROGRESSIVE,
	BOSS
}

@export var room_index: int = 1
@export var room_name: String = "Salle 1"
@export var enemy_level: int = 1
@export var spawn_mode: SpawnMode = SpawnMode.ALL_AT_ONCE
@export var total_enemies: int = 4
@export var wave_count: int = 2
@export var progressive_interval: float = 1.4

@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene

@export var entry_door: RoomDoor
@export var exit_door: RoomDoor

var is_active: bool = false
var is_cleared: bool = false
var enemies_spawned: int = 0
var enemies_defeated: int = 0
var current_wave: int = 0
var progressive_timer: float = 0.0
var active_enemies: Array[Node2D] = []

@onready var bounds_area: Area2D = get_node_or_null("Bounds")
@onready var fog_overlay: ColorRect = get_node_or_null("FogOverlay")
@onready var spawners_container: Node2D = get_node_or_null("Spawners")
@onready var enemies_container: Node2D = get_node_or_null("Enemies")

func _ready() -> void:
	if not enemy_scene:
		enemy_scene = load("res://scenes/entities/enemies/Enemy.tscn")
	if not boss_scene:
		boss_scene = load("res://scenes/entities/enemies/BossEnemy.tscn")
		
	if bounds_area:
		bounds_area.body_entered.connect(_on_bounds_body_entered)
		
	# La porte de sortie de la salle commence fermée (verrouillée jusqu'au nettoyage)
	if exit_door:
		exit_door.set_closed(true)
		
	# S'assurer que le brouillard masque la salle initialement si ce n'est pas la première
	if fog_overlay:
		fog_overlay.visible = true
		if room_index == 1:
			fog_overlay.modulate.a = 0.0 # Salle 1 découverte immédiatement

func _on_bounds_body_entered(body: Node2D) -> void:
	if is_active or is_cleared:
		return
	if body.is_in_group("player") or body.name == "Player":
		activate_room()

func activate_room() -> void:
	if is_active or is_cleared:
		return
	is_active = true
	
	# Fermer et verrouiller définitivement la porte d'entrée
	if entry_door:
		entry_door.lock_permanently()
		
	# Dissiper le brouillard de guerre avec un fondu fluide
	if fog_overlay:
		var tween = create_tween()
		tween.tween_property(fog_overlay, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func(): fog_overlay.visible = false)
		
	# Notifier l'interface
	var bus = get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		bus.room_entered.emit(room_index, 5, room_name)
		bus.room_enemies_updated.emit(total_enemies, total_enemies)
		
	# Démarrer le spawn
	_start_spawning()

func _start_spawning() -> void:
	match spawn_mode:
		SpawnMode.ALL_AT_ONCE:
			for i in range(total_enemies):
				_spawn_enemy()
		SpawnMode.WAVES:
			current_wave = 1
			var count_in_wave = total_enemies / wave_count
			for i in range(count_in_wave):
				_spawn_enemy()
		SpawnMode.PROGRESSIVE:
			_spawn_enemy() # Premier monstre immédiat
		SpawnMode.BOSS:
			_spawn_boss()

func _process(delta: float) -> void:
	if not is_active or is_cleared:
		return
		
	if spawn_mode == SpawnMode.PROGRESSIVE:
		if enemies_spawned < total_enemies:
			progressive_timer += delta
			if progressive_timer >= progressive_interval:
				progressive_timer = 0.0
				_spawn_enemy()

func _spawn_enemy() -> void:
	if not enemy_scene:
		enemy_scene = load("res://scenes/entities/enemies/Enemy.tscn")
	if not enemy_scene:
		return
		
	var spawners = []
	if spawners_container:
		spawners = spawners_container.get_children()
	
	var spawn_pos = global_position
	if not spawners.is_empty():
		spawn_pos = spawners.pick_random().global_position
	else:
		spawn_pos += Vector2(randf_range(-100, 100), randf_range(-100, 100))
		
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	
	# Chance d'être tireur augmente avec les salles (R1: 30%, R2: 50%, R3: 65%, R4: 80%)
	var shooter_chance = 0.2 + (room_index * 0.15)
	enemy.can_shoot = (randf() <= shooter_chance)
	
	if enemies_container:
		enemies_container.add_child(enemy)
	else:
		add_child(enemy)
		
	enemy.set_enemy_level(enemy_level, 1)
	active_enemies.append(enemy)
	enemies_spawned += 1
	
	if enemy.has_signal("died"):
		enemy.died.connect(func(_e): _on_enemy_died(enemy))
	else:
		enemy.tree_exited.connect(func(): _on_enemy_died(enemy))

func _spawn_boss() -> void:
	if not boss_scene:
		boss_scene = load("res://scenes/entities/enemies/BossEnemy.tscn")
	if not boss_scene:
		return
	var spawners = []
	if spawners_container:
		spawners = spawners_container.get_children()
	var spawn_pos = spawners[0].global_position if not spawners.is_empty() else global_position
	
	var boss: BossEnemy = boss_scene.instantiate()
	boss.global_position = spawn_pos
	boss.level = 5
	boss.zone_number = 1
	
	if enemies_container:
		enemies_container.add_child(boss)
	else:
		add_child(boss)
		
	active_enemies.append(boss)
	enemies_spawned += 1
	if boss.has_signal("died"):
		boss.died.connect(func(_b): _on_enemy_died(boss))
	else:
		boss.tree_exited.connect(func(): _on_enemy_died(boss))

func _on_enemy_died(enemy: Node2D) -> void:
	if not active_enemies.has(enemy):
		return # Évite le double comptage
	active_enemies.erase(enemy)
	enemies_defeated += 1
	
	var remaining = total_enemies - enemies_defeated
	var bus = get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		bus.room_enemies_updated.emit(max(0, remaining), total_enemies)
		
	# Vérification du passage à la vague suivante pour le mode WAVES
	if spawn_mode == SpawnMode.WAVES and current_wave < wave_count:
		var wave_size = total_enemies / wave_count
		if active_enemies.size() == 0 and enemies_spawned < total_enemies:
			current_wave += 1
			for i in range(wave_size):
				if enemies_spawned < total_enemies:
					_spawn_enemy()
					
	# Vérification de la complétion de la salle
	if enemies_defeated >= total_enemies:
		_complete_room()

func _complete_room() -> void:
	if is_cleared:
		return
	is_cleared = true
	is_active = false
	
	# Ouvrir la porte de sortie
	if exit_door:
		exit_door.set_closed(false)
		
	room_completed.emit(room_index)
	
	var bus = get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		bus.room_cleared.emit(room_index)
