extends Node

signal points_changed(total_points: int)
signal upgrades_updated()

const SAVE_PATH = "user://save_data.json"

var total_points: int = 0
var current_run_points: int = 0

# Arbres d'améliorations persistantes
var upgrades = {
	# Branche Offensive
	"damage_boost": 0,      # +10% dégâts par niveau (max 5)
	"crit_chance": 0,       # +5% chance de critique par niveau (max 5)
	"crit_damage": 0,       # +25% dégâts critique par niveau (max 5)
	"fire_rate_boost": 0,   # +10% cadence de tir par niveau (max 5)
	
	# Branche Défensive
	"max_hp_boost": 0,      # +20 PV max par niveau (max 5)
	"starting_shield": 0,   # +20 Bouclier de départ par niveau (max 5)
	"armor": 0,             # +5 Armure (réduction dégâts) par niveau (max 5)
	"hp_regen_boost": 0,    # +1.5 PV/s régénération par niveau (max 5)
	
	# Branche Tactique
	"extra_dash": 0,        # +1 charge d'esquive (max 2)
	"dash_cooldown": 0,     # -15% temps de recharge de l'esquive (max 5)
	"move_speed": 0,        # +8% vitesse de déplacement par niveau (max 5)
	
	# Branche Utilitaire
	"magnet_radius": 0,     # +35% rayon d'aimantation des drops (max 5)
	"starting_ammo": 0,     # +25 munitions max & de départ (max 5)
	"bonus_drop_rate": 0    # +5% chance de drop bonus supplémentaires (max 5)
}

# Configuration des coûts de base et max_levels pour chaque amélioration
const UPGRADE_CONFIG = {
	"damage_boost": {"name": "Dégâts d'Arme", "desc": "+10% dégâts par niveau", "base_cost": 5, "max_level": 5, "branch": "offensive"},
	"crit_chance": {"name": "Coup Critique %", "desc": "+5% chance de coup critique", "base_cost": 8, "max_level": 5, "branch": "offensive"},
	"crit_damage": {"name": "Dégâts Critique", "desc": "+25% dégâts sur les coups critiques", "base_cost": 6, "max_level": 5, "branch": "offensive"},
	"fire_rate_boost": {"name": "Cadence de Tir", "desc": "+10% vitesse de tir", "base_cost": 7, "max_level": 5, "branch": "offensive"},
	
	"max_hp_boost": {"name": "Points de Vie Max", "desc": "+20 PV maximum au départ", "base_cost": 5, "max_level": 5, "branch": "defensive"},
	"starting_shield": {"name": "Bouclier Tactique", "desc": "+20 Bouclier initial absorbant les dégâts", "base_cost": 8, "max_level": 5, "branch": "defensive"},
	"armor": {"name": "Armure Renforcée", "desc": "+5 Armure (réduit les dégâts subis)", "base_cost": 6, "max_level": 5, "branch": "defensive"},
	"hp_regen_boost": {"name": "Régénération de Santé", "desc": "+1.5 PV/sec régénération passive", "base_cost": 10, "max_level": 5, "branch": "defensive"},
	
	"extra_dash": {"name": "Charge d'Esquive", "desc": "+1 esquive consécutive supplémentaire", "base_cost": 15, "max_level": 2, "branch": "tactical"},
	"dash_cooldown": {"name": "Récupération d'Esquive", "desc": "-15% temps de recharge d'esquive", "base_cost": 6, "max_level": 5, "branch": "tactical"},
	"move_speed": {"name": "Vitesse de Déplacement", "desc": "+8% vitesse de course", "base_cost": 5, "max_level": 5, "branch": "tactical"},
	
	"magnet_radius": {"name": "Aimant à Butin", "desc": "+35% portée d'attraction des drops", "base_cost": 4, "max_level": 5, "branch": "utility"},
	"starting_ammo": {"name": "Réserve de Munitions", "desc": "+25 munitions maximales et de départ", "base_cost": 4, "max_level": 5, "branch": "utility"},
	"bonus_drop_rate": {"name": "Chance de Butin", "desc": "+5% chance d'obtenir des bonus sur les monstres", "base_cost": 8, "max_level": 5, "branch": "utility"}
}

func _ready() -> void:
	load_data()

func get_upgrade_cost(upgrade_id: String) -> int:
	if not UPGRADE_CONFIG.has(upgrade_id):
		return 999999
	var current_lvl = upgrades.get(upgrade_id, 0)
	var cfg = UPGRADE_CONFIG[upgrade_id]
	if current_lvl >= cfg["max_level"]:
		return -1 # Maxed out
	# Coût croissant : base_cost * (1 + current_lvl * 1.25)
	return int(round(cfg["base_cost"] * (1.0 + current_lvl * 1.25)))

func buy_upgrade(upgrade_id: String) -> bool:
	var cost = get_upgrade_cost(upgrade_id)
	if cost == -1 or total_points < cost:
		return false
	
	total_points -= cost
	upgrades[upgrade_id] = upgrades.get(upgrade_id, 0) + 1
	save_data()
	points_changed.emit(total_points)
	upgrades_updated.emit()
	return true

func add_run_points(amount: int) -> void:
	current_run_points += amount
	total_points += amount
	points_changed.emit(total_points)

func reset_run_points() -> void:
	current_run_points = 0

func save_data() -> void:
	var data = {
		"total_points": total_points,
		"upgrades": upgrades
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(data, "\t")
		file.store_string(json_str)
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_str)
		if parsed is Dictionary:
			total_points = parsed.get("total_points", 0)
			var saved_upgrades = parsed.get("upgrades", {})
			for k in saved_upgrades.keys():
				if upgrades.has(k):
					upgrades[k] = saved_upgrades[k]
