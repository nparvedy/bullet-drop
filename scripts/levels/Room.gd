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
var is_starting_sequence: bool = false
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
		
	# La porte de sortie commence fermée
	if exit_door:
		exit_door.set_closed(true)
		
	# Brouillard initial
	if fog_overlay:
		fog_overlay.visible = true
		if room_index == 1:
			fog_overlay.modulate.a = 0.0

func _process(delta: float) -> void:
	# Si la salle n'est pas encore activée et qu'un joueur est présent, vérifier s'il est bien entré
	if not is_active and not is_cleared and not is_starting_sequence and room_index > 1:
		_check_player_entry()
		return
		
	if not is_active or is_cleared:
		return
		
	if spawn_mode == SpawnMode.PROGRESSIVE:
		if enemies_spawned < total_enemies:
			progressive_timer += delta
			if progressive_timer >= progressive_interval:
				progressive_timer = 0.0
				_spawn_enemy.call_deferred(true)

func _on_bounds_body_entered(body: Node2D) -> void:
	if is_active or is_cleared or is_starting_sequence:
		return
	if body.is_in_group("player") or body.name == "Player":
		_check_player_entry()

func _find_player_node() -> Node2D:
	if is_inside_tree() and get_tree():
		var p = get_tree().get_first_node_in_group("player")
		if p and is_instance_valid(p):
			return p
	var cur = get_parent()
	while cur:
		if cur.has_node("Player"):
			return cur.get_node("Player")
		cur = cur.get_parent()
	return null

func _check_player_entry() -> void:
	if is_active or is_cleared or is_starting_sequence:
		return
		
	var player = _find_player_node()
	if not player or not is_instance_valid(player):
		return
		
	# Pour les salles 2+, s'assurer que le joueur a bien franchi la porte d'entrée (+80px à l'intérieur)
	if entry_door:
		var entry_threshold_x = entry_door.global_position.x + 80.0
		if player.global_position.x < entry_threshold_x:
			return # Le joueur n'est pas encore assez avancé dans la salle suivante
			
	activate_room()

func activate_room() -> void:
	if is_active or is_cleared:
		return
	is_starting_sequence = true
	is_active = true
	
	var player = _find_player_node()
	if player and is_instance_valid(player):
		if player.has_method("set_frozen"):
			player.set_frozen(true)
		# Nudge de sécurité vers l'intérieur si nécessaire
		if entry_door and player.global_position.x < entry_door.global_position.x + 120.0:
			var pt = player.create_tween()
			if pt:
				pt.tween_property(player, "global_position:x", entry_door.global_position.x + 140.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				
	# Dissipation du brouillard
	if fog_overlay:
		var tween = create_tween()
		if tween:
			tween.tween_property(fog_overlay, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func(): fog_overlay.visible = false)
		else:
			fog_overlay.visible = false
			
	# Interface
	var bus = get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		bus.room_entered.emit(room_index, 5, room_name)
		bus.room_enemies_updated.emit(total_enemies, total_enemies)
		
	# Fermeture animée de la porte d'entrée
	if entry_door:
		entry_door.close_with_animation(func():
			if player and is_instance_valid(player) and player.has_method("set_frozen"):
				player.set_frozen(false)
			is_starting_sequence = false
			_start_spawning()
		)
	else:
		# Salle 1 : déblocage immédiat et spawn
		if player and is_instance_valid(player) and player.has_method("set_frozen"):
			player.set_frozen(false)
		is_starting_sequence = false
		var t = get_tree().create_timer(0.3) if is_inside_tree() else null
		if t:
			t.timeout.connect(_start_spawning)
		else:
			_start_spawning()

func _start_spawning() -> void:
	match spawn_mode:
		SpawnMode.ALL_AT_ONCE:
			for i in range(total_enemies):
				var delay = i * 0.22
				if delay > 0.0 and is_inside_tree():
					var t = get_tree().create_timer(delay)
					t.timeout.connect(func():
						if is_active and not is_cleared:
							_spawn_enemy(true)
					)
				else:
					_spawn_enemy(true)
		SpawnMode.WAVES:
			current_wave = 1
			var count_in_wave = total_enemies / wave_count
			for i in range(count_in_wave):
				var delay = i * 0.22
				if delay > 0.0 and is_inside_tree():
					var t = get_tree().create_timer(delay)
					t.timeout.connect(func():
						if is_active and not is_cleared:
							_spawn_enemy(true)
					)
				else:
					_spawn_enemy(true)
		SpawnMode.PROGRESSIVE:
			_spawn_enemy(true) # Premier monstre
		SpawnMode.BOSS:
			_spawn_boss(true)

func _spawn_enemy(with_anim: bool = true) -> void:
	if not enemy_scene:
		enemy_scene = load("res://scenes/entities/enemies/Enemy.tscn")
	if not enemy_scene:
		return
		
	var spawners = []
	if spawners_container:
		spawners = spawners_container.get_children()
	
	var spawn_pos = global_position
	if not spawners.is_empty():
		var idx = enemies_spawned % spawners.size()
		spawn_pos = spawners[idx].global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	else:
		spawn_pos += Vector2(randf_range(-100, 100), randf_range(-100, 100))
		
	var enemy: Enemy = enemy_scene.instantiate()
	
	if enemies_container:
		enemies_container.add_child(enemy)
	else:
		add_child(enemy)
		
	enemy.global_position = spawn_pos
	
	if with_anim:
		enemy.scale = Vector2.ZERO
		enemy.modulate = Color(2.5, 2.5, 2.5)
		var st = enemy.create_tween()
		if st:
			st.set_parallel(true)
			st.tween_property(enemy, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			st.tween_property(enemy, "modulate", Color.WHITE, 0.35)
		else:
			enemy.scale = Vector2.ONE
			enemy.modulate = Color.WHITE
			
	# Chance d'être tireur augmente avec les salles (R1: 30%, R2: 50%, R3: 65%, R4: 80%)
	var shooter_chance = 0.2 + (room_index * 0.15)
	enemy.can_shoot = (randf() <= shooter_chance)
	
	enemy.set_enemy_level(enemy_level, 1)
	active_enemies.append(enemy)
	enemies_spawned += 1
	
	if enemy.has_signal("died"):
		enemy.died.connect(func(_e): _on_enemy_died(enemy))
	else:
		enemy.tree_exited.connect(func(): _on_enemy_died(enemy))

func _spawn_boss(with_anim: bool = true) -> void:
	if not boss_scene:
		boss_scene = load("res://scenes/entities/enemies/BossEnemy.tscn")
	if not boss_scene:
		return
	var spawners = []
	if spawners_container:
		spawners = spawners_container.get_children()
	var spawn_pos = spawners[0].global_position if not spawners.is_empty() else global_position
	
	var boss: BossEnemy = boss_scene.instantiate()
	
	if enemies_container:
		enemies_container.add_child(boss)
	else:
		add_child(boss)
		
	boss.global_position = spawn_pos
	boss.level = 5
	boss.zone_number = 1
	
	if with_anim:
		boss.scale = Vector2.ZERO
		boss.modulate = Color(2.5, 2.5, 2.5)
		var bt = boss.create_tween()
		if bt:
			bt.set_parallel(true)
			bt.tween_property(boss, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			bt.tween_property(boss, "modulate", Color.WHITE, 0.5)
		else:
			boss.scale = Vector2.ONE
			boss.modulate = Color.WHITE
			
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
				var delay = i * 0.22
				if delay > 0.0 and is_inside_tree():
					var t = get_tree().create_timer(delay)
					t.timeout.connect(func():
						if is_active and not is_cleared and enemies_spawned < total_enemies:
							_spawn_enemy(true)
					)
				else:
					if enemies_spawned < total_enemies:
						_spawn_enemy.call_deferred(true)
					
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
