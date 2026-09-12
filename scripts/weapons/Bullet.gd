extends Area2D
class_name Projectile

@export var speed: float = 900.0
@export var damage: float = 120.0
@export var is_enemy_bullet: bool = false
@export var lifetime: float = 2.5

var direction: Vector2 = Vector2.RIGHT
var current_lifetime: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	top_level = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_setup_collision_layers()
	
	if sprite:
		if is_enemy_bullet:
			sprite.texture = preload("res://assets/sprites/weapons/bullet_enemy.png")
		else:
			sprite.texture = preload("res://assets/sprites/weapons/bullet_player.png")

func _setup_collision_layers() -> void:
	if is_enemy_bullet:
		# Layer 5 (EnemyBullets = 16), Mask 1 (World = 1) + Mask 2 (Player = 2)
		collision_layer = 16
		collision_mask = 1 | 2
	else:
		# Layer 4 (PlayerBullets = 8), Mask 1 (World = 1) + Mask 3 (Enemies = 4)
		collision_layer = 8
		collision_mask = 1 | 4

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	current_lifetime += delta
	if current_lifetime >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_enemy_bullet:
		if body.has_method("take_damage") and (body.is_in_group("player") or body.name == "Player"):
			body.take_damage(damage)
			_destroy()
		elif body is TileMapLayer or body is StaticBody2D:
			_destroy()
	else:
		if body.has_method("take_damage") and (body.is_in_group("enemies") or body.has_node("HealthBar") or "Enemy" in body.name):
			body.take_damage(damage)
			_destroy()
		elif body is TileMapLayer or body is StaticBody2D:
			_destroy()

func _on_area_entered(area: Area2D) -> void:
	if is_enemy_bullet and area.owner and area.owner.is_in_group("player") and area.owner.has_method("take_damage"):
		area.owner.take_damage(damage)
		_destroy()
	elif not is_enemy_bullet and area.owner and area.owner.is_in_group("enemies") and area.owner.has_method("take_damage"):
		area.owner.take_damage(damage)
		_destroy()

func _destroy() -> void:
	queue_free()
