extends Area2D
class_name AmmoDrop

@export var ammo_amount: int = 5

var float_offset: float = 0.0
var time_passed: float = 0.0
var initial_pos_y: float = 0.0

func _ready() -> void:
	# Layer 6 (Drops = 32), Mask 2 (Player = 2)
	collision_layer = 32
	collision_mask = 2
	initial_pos_y = position.y
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _process(delta: float) -> void:
	time_passed += delta * 4.0
	float_offset = sin(time_passed) * 3.5
	$Visual.position.y = float_offset
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("add_ammo"):
			body.add_ammo(ammo_amount)
		elif body.has_node("Weapon"):
			body.get_node("Weapon").add_ammo(ammo_amount)
		
		# Feedback textuel flottant
		_spawn_pickup_text()
		
		# Emission de signal
		if has_node("/root/EventBus"):
			EventBus.ammo_collected.emit(ammo_amount)
		
		queue_free()

func _spawn_pickup_text() -> void:
	var label = Label.new()
	label.text = "+%d Balles" % ammo_amount
	label.modulate = Color(1.0, 0.9, 0.1, 1.0)
	label.z_index = 100
	label.global_position = global_position - Vector2(25, 20)
	label.scale = Vector2(0.8, 0.8)
	get_parent().add_child(label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 25.0, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

func _draw() -> void:
	# Anneau de lumière au sol
	draw_arc(Vector2.ZERO, 14.0 + sin(time_passed) * 2.0, 0, TAU, 24, Color(1.0, 0.8, 0.2, 0.35), 2.0)
