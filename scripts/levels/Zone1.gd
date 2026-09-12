extends Node2D
class_name Zone1

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var ammo_drop_scene: PackedScene

var player_ref: Player = null
var is_zone_cleared: bool = false

@onready var rooms_container: Node2D = $Rooms
@onready var room1: Room = $Rooms/Room1
@onready var room2: Room = $Rooms/Room2
@onready var room3: Room = $Rooms/Room3
@onready var room4: Room = $Rooms/Room4
@onready var room5_boss: Room = $Rooms/Room5_Boss

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var exit_portal: Area2D = $ExitPortal
@onready var player_node: Node2D = get_node_or_null("Player")

func _ready() -> void:
	if not player_scene:
		player_scene = load("res://scenes/entities/player/Player.tscn")
		
	if player_node and player_spawn:
		player_node.global_position = player_spawn.global_position
		
	if exit_portal:
		exit_portal.visible = false
		exit_portal.monitoring = false
		if not exit_portal.body_entered.is_connected(_on_exit_portal_body_entered):
			exit_portal.body_entered.connect(_on_exit_portal_body_entered)
		
	var bus = get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		if not bus.boss_defeated.is_connected(_on_boss_defeated):
			bus.boss_defeated.connect(_on_boss_defeated)
		if not bus.zone_cleared.is_connected(_on_zone_cleared):
			bus.zone_cleared.connect(_on_zone_cleared)
		bus.room_cleared.connect(func(idx):
			if idx == 5:
				_on_boss_defeated()
		)
		
	if room5_boss:
		room5_boss.room_completed.connect(func(_idx): _on_boss_defeated())
	
	# Réinitialisation des points de la run courante
	var sm = get_node_or_null("/root/SaveManager") if is_inside_tree() else null
	if sm:
		sm.reset_run_points()
		
	# Démarrage immédiat de la première salle
	call_deferred("_start_first_room")

func _start_first_room() -> void:
	if room1 and not room1.is_active:
		room1.activate_room()

func _on_boss_defeated() -> void:
	if is_zone_cleared:
		return
	is_zone_cleared = true
	if exit_portal:
		exit_portal.visible = true
		exit_portal.monitoring = true
		exit_portal.scale = Vector2.ONE
		var tween = create_tween()
		if tween:
			exit_portal.scale = Vector2.ZERO
			tween.tween_property(exit_portal, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_zone_cleared() -> void:
	_on_boss_defeated()

func _on_exit_portal_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		var hud = get_node_or_null("HUD")
		if hud and hud.has_node("Control/UpgradeShop"):
			hud.get_node("Control/UpgradeShop").open_shop("🏆 VICTOIRE DE LA ZONE 1 !")
