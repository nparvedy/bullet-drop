extends Area2D
class_name BonusDrop

enum BonusType {
	DAMAGE,
	MAX_HP,
	FIRE_RATE,
	SHIELD,
	REGEN,
	EXTRA_DASH
}

@export var bonus_type: BonusType = BonusType.DAMAGE

var bonus_data = {
	BonusType.DAMAGE: {"name": "+20% DÉGÂTS", "desc": "Augmente les dégâts de vos tirs", "color": Color(1.0, 0.2, 0.2)},
	BonusType.MAX_HP: {"name": "+50% PV MAX", "desc": "Augmente et régénère vos points de vie", "color": Color(0.2, 1.0, 0.3)},
	BonusType.FIRE_RATE: {"name": "+1 TIR / SEC", "desc": "Augmente votre cadence de tir", "color": Color(1.0, 0.85, 0.1)},
	BonusType.SHIELD: {"name": "+20% BOUCLIER", "desc": "Renforce votre bouclier protecteur", "color": Color(0.2, 0.7, 1.0)},
	BonusType.REGEN: {"name": "+50% RÉGÉNÉRATION", "desc": "Accélère la régénération de santé", "color": Color(0.3, 1.0, 0.8)},
	BonusType.EXTRA_DASH: {"name": "+1 ESQUIVE", "desc": "Octroie une charge d'esquive supplémentaire", "color": Color(0.9, 0.4, 1.0)}
}

var bob_time: float = 0.0
var base_y: float = 0.0
var is_collected: bool = false

@onready var icon_label: Label = $Visual/IconLabel
@onready var glow_sprite: ColorRect = $Visual/Glow
@onready var background_rect: ColorRect = $Visual/Background

func _ready() -> void:
	base_y = position.y
	# Choix aléatoire du type si non forcé
	if bonus_type == BonusType.DAMAGE and randf() < 0.85: # Default initialization
		var types = [
			BonusType.DAMAGE,
			BonusType.MAX_HP,
			BonusType.FIRE_RATE,
			BonusType.SHIELD,
			BonusType.REGEN,
			BonusType.EXTRA_DASH
		]
		bonus_type = types.pick_random()
	
	_update_visuals()
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Effet d'apparition (pop up)
	scale = Vector2.ZERO
	var pop_tween = create_tween()
	pop_tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_visuals() -> void:
	var info = bonus_data[bonus_type]
	var col: Color = info["color"]
	if glow_sprite:
		glow_sprite.color = Color(col.r, col.g, col.b, 0.35)
	if background_rect:
		background_rect.color = Color(col.r * 0.4, col.g * 0.4, col.b * 0.4, 0.9)
	if icon_label:
		match bonus_type:
			BonusType.DAMAGE: icon_label.text = "⚔️"
			BonusType.MAX_HP: icon_label.text = "❤️"
			BonusType.FIRE_RATE: icon_label.text = "⚡"
			BonusType.SHIELD: icon_label.text = "🛡️"
			BonusType.REGEN: icon_label.text = "💖"
			BonusType.EXTRA_DASH: icon_label.text = "💨"

func _process(delta: float) -> void:
	if is_collected:
		return
	bob_time += delta * 4.0
	var offset = sin(bob_time) * 4.0
	$Visual.position.y = offset
	
	# Magnétisme vers le joueur si proche
	_check_magnet(delta)

func _check_magnet(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var magnet_radius = 120.0
		if player.has_method("get_magnet_radius"):
			magnet_radius = player.get_magnet_radius()
		var dist = global_position.distance_to(player.global_position)
		if dist <= magnet_radius:
			var dir = (player.global_position - global_position).normalized()
			var pull_speed = (1.0 - (dist / magnet_radius)) * 400.0 + 100.0
			global_position += dir * pull_speed * delta

func _on_body_entered(body: Node2D) -> void:
	_collect(body)

func _on_area_entered(area: Area2D) -> void:
	if area.owner and area.owner.is_in_group("player"):
		_collect(area.owner)

func _collect(target: Node2D) -> void:
	if is_collected:
		return
	if target.is_in_group("player") or target.name == "Player":
		is_collected = true
		if target.has_method("apply_bonus"):
			target.apply_bonus(bonus_type)
		
		var info = bonus_data[bonus_type]
		var bus = get_node_or_null("/root/EventBus") if is_inside_tree() else null
		if bus:
			bus.bonus_collected.emit(info["name"], info["desc"], global_position)
			
		_spawn_floating_text(info["name"], info["color"])
		
		# Disparition avec tween
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)

func _spawn_floating_text(text: String, col: Color) -> void:
	var label = Label.new()
	label.text = text
	label.modulate = col
	label.theme = load("res://scenes/ui/HUD.tscn").get_node("Control/BottomLeftHUD/Margin/VBox/HealthContainer/HealthText").theme if ResourceLoader.exists("res://scenes/ui/HUD.tscn") else null
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_outline_size", 2)
	label.global_position = global_position + Vector2(-30, -25)
	label.z_index = 50
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(label)
		var t = label.create_tween()
		t.set_parallel(true)
		t.tween_property(label, "global_position:y", label.global_position.y - 45.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
		t.finished.connect(label.queue_free)
