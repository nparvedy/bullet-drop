extends Node2D
class_name RoomDoor

@export var is_closed: bool = true
@export var is_permanent_lock: bool = false # Si verrouillée définitivement (porte arrière de non-retour)
@export var width: float = 160.0
@export var orientation: String = "horizontal" # "horizontal" ou "vertical"

@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var visual_rect: ColorRect = $Visual
@onready var lock_trigger: Area2D = $LockTrigger

func _ready() -> void:
	_update_size()
	set_closed(is_closed)
	if lock_trigger:
		lock_trigger.body_entered.connect(_on_trigger_body_entered)

func _update_size() -> void:
	var shape = RectangleShape2D.new()
	var trig_shape = RectangleShape2D.new()
	if orientation == "horizontal":
		shape.size = Vector2(width, 32.0)
		trig_shape.size = Vector2(width, 32.0)
		if visual_rect:
			visual_rect.position = Vector2(-width / 2.0, -16.0)
			visual_rect.size = Vector2(width, 32.0)
		if lock_trigger and lock_trigger.has_node("TriggerShape"):
			var trigger_col = lock_trigger.get_node("TriggerShape") as CollisionShape2D
			trigger_col.position = Vector2(0, 50.0)
			trigger_col.shape = trig_shape
	else:
		shape.size = Vector2(32.0, width)
		trig_shape.size = Vector2(32.0, width)
		if visual_rect:
			visual_rect.position = Vector2(-16.0, -width / 2.0)
			visual_rect.size = Vector2(32.0, width)
		if lock_trigger and lock_trigger.has_node("TriggerShape"):
			var trigger_col = lock_trigger.get_node("TriggerShape") as CollisionShape2D
			trigger_col.position = Vector2(50.0, 0)
			trigger_col.shape = trig_shape
	if collision_shape:
		collision_shape.shape = shape

func set_closed(closed: bool) -> void:
	if is_permanent_lock and not closed:
		return # Ne peut pas être rouverte si verrouillée définitivement
		
	is_closed = closed
	if collision_shape:
		collision_shape.set_deferred("disabled", !closed)
	
	if visual_rect:
		var tween = create_tween()
		if closed:
			visual_rect.color = Color(0.95, 0.2, 0.2, 0.85) # Rouge alerte
			tween.tween_property(visual_rect, "modulate:a", 1.0, 0.25)
		else:
			visual_rect.color = Color(0.2, 0.95, 0.4, 0.35) # Vert ouvert translucide
			tween.tween_property(visual_rect, "modulate:a", 0.3, 0.35)

func lock_permanently() -> void:
	is_permanent_lock = true
	set_closed(true)
	if visual_rect:
		visual_rect.color = Color(0.9, 0.15, 0.15, 0.95)

func close_with_animation(on_closed_callback: Callable = Callable()) -> void:
	is_permanent_lock = true
	is_closed = true
	
	if visual_rect:
		visual_rect.visible = true
		visual_rect.color = Color(0.2, 0.95, 0.4, 0.6)
		visual_rect.modulate.a = 1.0
		
		# Animation de fermeture : effet d'extension de grille énergétique + flash rouge
		var tween = create_tween()
		if tween:
			if orientation == "vertical":
				visual_rect.scale = Vector2(1.0, 0.0)
				visual_rect.pivot_offset = Vector2(16.0, width / 2.0)
				tween.tween_property(visual_rect, "scale:y", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			else:
				visual_rect.scale = Vector2(0.0, 1.0)
				visual_rect.pivot_offset = Vector2(width / 2.0, 16.0)
				tween.tween_property(visual_rect, "scale:x", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				
			tween.tween_property(visual_rect, "color", Color(2.5, 2.5, 2.5), 0.1) # Flash lumineux
			tween.tween_property(visual_rect, "color", Color(0.9, 0.15, 0.15, 0.95), 0.15) # Rouge alerte verrouillé
			
			tween.tween_callback(func():
				if collision_shape:
					collision_shape.set_deferred("disabled", false)
				if on_closed_callback.is_valid():
					on_closed_callback.call()
			)
			return

	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if on_closed_callback.is_valid():
		on_closed_callback.call()

func _on_trigger_body_entered(body: Node2D) -> void:
	# Géré directement par Room.gd lors de l'entrée dans la salle suivante
	pass
