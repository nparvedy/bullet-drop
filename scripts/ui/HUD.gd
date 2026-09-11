extends CanvasLayer
class_name HUD

@onready var health_bar: ProgressBar = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/HealthContainer/HealthBar")
@onready var health_text: Label = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/HealthContainer/HealthText")
@onready var ammo_text: Label = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/AmmoContainer/AmmoText")
@onready var dash_status: Label = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/DashContainer/DashStatus")
@onready var dash_bar: ProgressBar = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/DashContainer/DashBar")
@onready var quota_label: Label = get_node_or_null("Control/TopCenterHUD/Margin/QuotaLabel")
@onready var death_panel: PanelContainer = get_node_or_null("Control/DeathPanel")
@onready var victory_panel: PanelContainer = get_node_or_null("Control/VictoryPanel")

var dash_tween: Tween
var health_tween: Tween

func _ready() -> void:
	if death_panel:
		death_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
		
	if has_node("/root/EventBus"):
		EventBus.player_health_changed.connect(_on_player_health_changed)
		EventBus.player_ammo_changed.connect(_on_player_ammo_changed)
		EventBus.player_dash_started.connect(_on_player_dash_started)
		EventBus.player_dash_ready.connect(_on_player_dash_ready)
		EventBus.zone_enemies_updated.connect(_on_zone_enemies_updated)
		EventBus.player_died.connect(_on_player_died)

func _process(_delta: float) -> void:
	if death_panel and death_panel.visible:
		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()

func _on_player_health_changed(current: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		if health_tween and health_tween.is_valid():
			health_tween.kill()
		health_tween = create_tween()
		health_tween.tween_property(health_bar, "value", float(current), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if health_text:
		health_text.text = "PV : %d / %d" % [current, max_hp]
		if current <= 30:
			health_text.modulate = Color(1.0, 0.2, 0.2)
		else:
			health_text.modulate = Color(1.0, 1.0, 1.0)

func _on_player_ammo_changed(current: int, _max_ammo: int) -> void:
	if ammo_text:
		if current <= 0:
			ammo_text.text = "⚠️ MUNITIONS : 0 (Chargeurs de secours en cours...)"
			ammo_text.modulate = Color(1.0, 0.2, 0.2)
		else:
			ammo_text.text = "⚡ MUNITIONS : %d" % current
			ammo_text.modulate = Color(1.0, 0.85, 0.2)

func _on_player_dash_started(cooldown_duration: float) -> void:
	if dash_status:
		dash_status.text = "ESQUIVE [MAJ] : Recharge..."
		dash_status.modulate = Color(0.7, 0.7, 0.7)
	if dash_bar:
		dash_bar.max_value = cooldown_duration
		dash_bar.value = 0.0
		if dash_tween and dash_tween.is_valid():
			dash_tween.kill()
		dash_tween = create_tween()
		dash_tween.tween_property(dash_bar, "value", cooldown_duration, cooldown_duration)

func _on_player_dash_ready() -> void:
	if dash_status:
		dash_status.text = "ESQUIVE [MAJ] : PRÊTE"
		dash_status.modulate = Color(0.3, 0.95, 0.4)
	if dash_bar:
		dash_bar.value = dash_bar.max_value

func _on_zone_enemies_updated(remaining: int, total_kills: int) -> void:
	if quota_label:
		quota_label.text = "🎯 ENTRAÎNEMENT | Actifs : %d | Éliminations : %d" % [remaining, total_kills]
		quota_label.modulate = Color(1.0, 0.9, 0.4)

func _on_player_died() -> void:
	if death_panel:
		death_panel.visible = true
