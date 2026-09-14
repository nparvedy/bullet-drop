extends Control
class_name UpgradeShop

@onready var points_label: Label = $Panel/Margin/VBox/Header/PointsLabel
@onready var run_summary_label: Label = $Panel/Margin/VBox/RunSummary
@onready var tab_offensive: Button = $Panel/Margin/VBox/CategoryTabs/BtnOffensive
@onready var tab_defensive: Button = $Panel/Margin/VBox/CategoryTabs/BtnDefensive
@onready var tab_tactical: Button = $Panel/Margin/VBox/CategoryTabs/BtnTactical
@onready var tab_utility: Button = $Panel/Margin/VBox/CategoryTabs/BtnUtility
@onready var items_container: VBoxContainer = $Panel/Margin/VBox/Scroll/ItemsList
@onready var btn_restart: Button = $Panel/Margin/VBox/Footer/BtnRestart

var current_tab: String = "offensive"

func _ready() -> void:
	if tab_offensive:
		tab_offensive.pressed.connect(func(): _switch_tab("offensive"))
	if tab_defensive:
		tab_defensive.pressed.connect(func(): _switch_tab("defensive"))
	if tab_tactical:
		tab_tactical.pressed.connect(func(): _switch_tab("tactical"))
	if tab_utility:
		tab_utility.pressed.connect(func(): _switch_tab("utility"))
	if btn_restart:
		btn_restart.pressed.connect(_on_restart_pressed)
		
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.points_changed.connect(func(_p): _refresh_ui())
		sm.upgrades_updated.connect(_refresh_ui)

func open_shop(title_text: String = "💀 VOUS ÊTES MORT !") -> void:
	visible = true
	var title_node = get_node_or_null("Panel/Margin/VBox/Header/TitleLabel")
	if title_node:
		title_node.text = title_text
		if "VICTOIRE" in title_text:
			title_node.modulate = Color(0.2, 1.0, 0.4)
		else:
			title_node.modulate = Color(1.0, 0.25, 0.25)
			
	var sm = get_node_or_null("/root/SaveManager") if is_inside_tree() else null
	if sm:
		if run_summary_label:
			run_summary_label.text = "Points récoltés cette partie : +%d pts" % sm.current_run_points
	_refresh_ui()

func _switch_tab(tab_name: String) -> void:
	current_tab = tab_name
	_refresh_ui()

func _refresh_ui() -> void:
	if not is_inside_tree() or not visible:
		return
		
	var save_mgr = get_node_or_null("/root/SaveManager") if is_inside_tree() else null
	if not save_mgr:
		return
		
	if points_label:
		points_label.text = "💎 Points Disponibles : %d" % save_mgr.total_points
	
	# Mise en surbrillance des boutons d'onglet
	_highlight_tab(tab_offensive, current_tab == "offensive")
	_highlight_tab(tab_defensive, current_tab == "defensive")
	_highlight_tab(tab_tactical, current_tab == "tactical")
	_highlight_tab(tab_utility, current_tab == "utility")
	
	# Nettoyage et reconstruction de la liste d'items
	for child in items_container.get_children():
		child.queue_free()
		
	for up_id in save_mgr.UPGRADE_CONFIG.keys():
		var cfg = save_mgr.UPGRADE_CONFIG[up_id]
		if cfg["branch"] == current_tab:
			_create_item_row(up_id, cfg)

func _highlight_tab(btn: Button, active: bool) -> void:
	if not btn:
		return
	if active:
		btn.modulate = Color(1.2, 1.2, 0.6)
	else:
		btn.modulate = Color(0.8, 0.8, 0.8)

func _create_item_row(upgrade_id: String, cfg: Dictionary) -> void:
	var save_mgr = get_node_or_null("/root/SaveManager") if is_inside_tree() else null
	if not save_mgr:
		return
	var cur_lvl = save_mgr.upgrades.get(upgrade_id, 0)
	var max_lvl = cfg["max_level"]
	var cost = save_mgr.get_upgrade_cost(upgrade_id)
	var can_afford = (cost != -1 and save_mgr.total_points >= cost)
	
	var row = PanelContainer.new()
	var row_style = StyleBoxFlat.new()
	row_style.bg_color = Color(0.12, 0.15, 0.22, 0.9)
	row_style.corner_radius_top_left = 6
	row_style.corner_radius_top_right = 6
	row_style.corner_radius_bottom_left = 6
	row_style.corner_radius_bottom_right = 6
	row_style.content_margin_left = 12
	row_style.content_margin_right = 12
	row_style.content_margin_top = 8
	row_style.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", row_style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	row.add_child(hbox)
	
	var vbox_info = VBoxContainer.new()
	vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox_info)
	
	var lbl_name = Label.new()
	lbl_name.text = "%s  (Niveau %d / %d)" % [cfg["name"], cur_lvl, max_lvl]
	lbl_name.add_theme_font_size_override("font_size", 16)
	lbl_name.modulate = Color(1.0, 0.9, 0.5)
	vbox_info.add_child(lbl_name)
	
	var lbl_desc = Label.new()
	lbl_desc.text = cfg["desc"]
	lbl_desc.add_theme_font_size_override("font_size", 13)
	lbl_desc.modulate = Color(0.75, 0.75, 0.8)
	vbox_info.add_child(lbl_desc)
	
	# Barre de niveau visuelle
	var progress = ProgressBar.new()
	progress.custom_minimum_size = Vector2(100, 8)
	progress.max_value = max_lvl
	progress.value = cur_lvl
	progress.show_percentage = false
	vbox_info.add_child(progress)
	
	var btn_buy = Button.new()
	btn_buy.custom_minimum_size = Vector2(140, 38)
	if cur_lvl >= max_lvl:
		btn_buy.text = "MAX"
		btn_buy.disabled = true
	else:
		btn_buy.text = "%d pts" % cost
		btn_buy.disabled = !can_afford
		btn_buy.pressed.connect(func():
			if save_mgr.buy_upgrade(upgrade_id):
				_refresh_ui()
		)
	hbox.add_child(btn_buy)
	
	items_container.add_child(row)

func _on_restart_pressed() -> void:
	var sm = get_node_or_null("/root/SaveManager") if is_inside_tree() else null
	if sm:
		sm.reset_run_points()
	if is_inside_tree() and get_tree():
		get_tree().reload_current_scene()
