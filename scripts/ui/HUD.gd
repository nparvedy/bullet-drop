extends CanvasLayer
class_name HUD

@onready var health_bar: ProgressBar = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/HealthContainer/HealthBar")
@onready var health_text: Label = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/HealthContainer/HealthText")
@onready var shield_bar: ProgressBar = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/ShieldContainer/ShieldBar")
@onready var shield_text: Label = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/ShieldContainer/ShieldText")
@onready var shield_container: VBoxContainer = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/ShieldContainer")
@onready var ammo_text: Label = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/AmmoContainer/AmmoText")
@onready var dash_status: Label = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/DashContainer/DashStatus")
@onready var dash_bar: ProgressBar = get_node_or_null("Control/BottomLeftHUD/Margin/VBox/DashContainer/DashBar")

@onready var top_center_hud: PanelContainer = get_node_or_null("Control/TopCenterHUD")
@onready var quota_label: Label = get_node_or_null("Control/TopCenterHUD/Margin/QuotaLabel")

@onready var boss_bar_container: PanelContainer = get_node_or_null("Control/BossBarContainer")
@onready var boss_name_label: Label = get_node_or_null("Control/BossBarContainer/VBox/BossNameLabel")
@onready var boss_health_bar: ProgressBar = get_node_or_null("Control/BossBarContainer/VBox/BossHealthBar")
@onready var boss_health_text: Label = get_node_or_null("Control/BossBarContainer/VBox/BossHealthText")

@onready var bonus_banner: Label = get_node_or_null("Control/BonusBanner")
@onready var upgrade_shop: UpgradeShop = get_node_or_null("Control/UpgradeShop")

var current_room_idx: int = 1
var total_rooms_count: int = 5
var current_room_title: String = "Salle 1"

func _ready() -> void:
	if boss_bar_container:
		boss_bar_container.visible = false
	if bonus_banner:
		bonus_banner.visible = false
	if upgrade_shop:
		upgrade_shop.visible = false
		
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		bus.player_health_changed.connect(_on_player_health_changed)
		bus.player_ammo_changed.connect(_on_player_ammo_changed)
		bus.player_dash_updated.connect(_on_player_dash_updated)
		bus.player_died.connect(_on_player_died)
		
		bus.room_entered.connect(_on_room_entered)
		bus.room_enemies_updated.connect(_on_room_enemies_updated)
		bus.room_cleared.connect(_on_room_cleared)
		
		bus.boss_spawned.connect(_on_boss_spawned)
		bus.boss_health_changed.connect(_on_boss_health_changed)
		bus.boss_defeated.connect(_on_boss_defeated)
		
		bus.bonus_collected.connect(_on_bonus_collected)

func _on_player_health_changed(current: int, max_hp: int, current_shield: int = 0, max_shield: int = 0) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current
		
	if health_text:
		health_text.text = "❤️ PV : %d / %d" % [current, max_hp]
		if current <= (max_hp * 0.3):
			health_text.modulate = Color(1.0, 0.25, 0.25)
		else:
			health_text.modulate = Color(1.0, 1.0, 1.0)
			
	if shield_container and shield_bar and shield_text:
		if max_shield > 0:
			shield_container.visible = true
			shield_bar.max_value = max_shield
			shield_bar.value = current_shield
			shield_text.text = "🛡️ BOUCLIER : %d / %d" % [current_shield, max_shield]
		else:
			shield_container.visible = false

func _on_player_ammo_changed(current: int, _max_ammo: int) -> void:
	if ammo_text:
		if current <= 0:
			ammo_text.text = "⚠️ MUNITIONS : 0 (En attente de drop)"
			ammo_text.modulate = Color(1.0, 0.2, 0.2)
		else:
			ammo_text.text = "⚡ MUNITIONS : %d" % current
			ammo_text.modulate = Color(1.0, 0.85, 0.2)

func _on_player_dash_updated(current_charges: int, max_charges: int, cooldown_pct: float) -> void:
	if dash_status:
		if current_charges > 0:
			dash_status.text = "💨 ESQUIVE [MAJ] : %d / %d" % [current_charges, max_charges]
			dash_status.modulate = Color(0.3, 0.95, 0.4)
		else:
			dash_status.text = "💨 ESQUIVE : Recharge... (0 / %d)" % max_charges
			dash_status.modulate = Color(0.7, 0.7, 0.7)
	if dash_bar:
		dash_bar.max_value = 1.0
		dash_bar.value = 1.0 if current_charges == max_charges else cooldown_pct

func _on_room_entered(room_idx: int, total_rooms: int, room_name: String) -> void:
	current_room_idx = room_idx
	total_rooms_count = total_rooms
	current_room_title = room_name
	if quota_label:
		quota_label.text = "🚩 Zone 1 — %s (%d/%d)" % [room_name, room_idx, total_rooms]
		quota_label.modulate = Color(1.0, 0.9, 0.4)

func _on_room_enemies_updated(remaining: int, total: int) -> void:
	if quota_label:
		if remaining == 0:
			quota_label.text = "✨ %s NETTOYÉE ! Porte ouverte !" % current_room_title
			quota_label.modulate = Color(0.2, 1.0, 0.4)
		else:
			quota_label.text = "🚩 Zone 1 — %s (%d/%d) | Ennemis : %d / %d" % [current_room_title, current_room_idx, total_rooms_count, remaining, total]
			quota_label.modulate = Color(1.0, 0.9, 0.4)

func _on_room_cleared(room_idx: int) -> void:
	if quota_label:
		quota_label.text = "✨ SALLE %d NETTOYÉE ! Continuez d'avancer !" % room_idx
		quota_label.modulate = Color(0.2, 1.0, 0.4)

func _on_boss_spawned(b_name: String, max_hp: float) -> void:
	if boss_bar_container:
		boss_bar_container.visible = true
	if boss_name_label:
		boss_name_label.text = "👑 " + b_name
	if boss_health_bar:
		boss_health_bar.max_value = max_hp
		boss_health_bar.value = max_hp
	if boss_health_text:
		boss_health_text.text = "%d / %d" % [int(max_hp), int(max_hp)]

func _on_boss_health_changed(current_hp: float, max_hp: float) -> void:
	if boss_health_bar:
		boss_health_bar.value = current_hp
	if boss_health_text:
		boss_health_text.text = "%d / %d" % [int(max(0, current_hp)), int(max_hp)]

func _on_boss_defeated() -> void:
	if boss_bar_container:
		boss_bar_container.visible = false
	if quota_label:
		quota_label.text = "🏆 BOSS VAINCU ! VICTOIRE DE LA ZONE 1 !"
		quota_label.modulate = Color(0.2, 1.0, 0.4)
	
	# Afficher l'écran de victoire après 2.5 secondes
	get_tree().create_timer(2.0).timeout.connect(func():
		if upgrade_shop:
			upgrade_shop.open_shop("🏆 VICTOIRE DE LA ZONE 1 !")
	)

func _on_bonus_collected(b_name: String, b_desc: String, _pos: Vector2) -> void:
	if bonus_banner:
		bonus_banner.text = "BONUS OBTENU : %s (%s)" % [b_name, b_desc]
		bonus_banner.visible = true
		bonus_banner.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_property(bonus_banner, "modulate:a", 0.0, 2.5).set_delay(1.0)
		tween.tween_callback(func(): bonus_banner.visible = false)

func _on_player_died() -> void:
	if upgrade_shop:
		upgrade_shop.open_shop("💀 VOUS ÊTES MORT !")
