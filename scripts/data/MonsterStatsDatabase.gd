extends Node

const STATS_FILE_PATH = "res://data/monster_stats.json"

var stats_data: Dictionary = {}

func _ready() -> void:
	load_stats()

func load_stats() -> void:
	if not FileAccess.file_exists(STATS_FILE_PATH):
		_create_fallback_data()
		return
		
	var file = FileAccess.open(STATS_FILE_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_str)
		if parsed is Dictionary:
			stats_data = parsed
		else:
			_create_fallback_data()
	else:
		_create_fallback_data()

func _create_fallback_data() -> void:
	stats_data = {
		"zone_multiplier": 3,
		"default_bonus_drop_rate": 0.20,
		"monster_levels": {
			"1": {"level": 1, "max_health": 200, "damage": 30, "crit_chance": 0.0, "crit_damage": 0.0, "fire_rate": 1.0, "move_speed": 95.0, "shield": 0, "health_regen": 0, "armor": 0, "base_points": 1},
			"2": {"level": 2, "max_health": 250, "damage": 36, "crit_chance": 0.0, "crit_damage": 0.0, "fire_rate": 0.95, "move_speed": 100.0, "shield": 0, "health_regen": 0, "armor": 0, "base_points": 2},
			"3": {"level": 3, "max_health": 300, "damage": 42, "crit_chance": 0.02, "crit_damage": 1.25, "fire_rate": 0.90, "move_speed": 105.0, "shield": 0, "health_regen": 0, "armor": 0, "base_points": 3},
			"4": {"level": 4, "max_health": 350, "damage": 48, "crit_chance": 0.05, "crit_damage": 1.35, "fire_rate": 0.85, "move_speed": 110.0, "shield": 0, "health_regen": 0, "armor": 0, "base_points": 4},
			"5": {"level": 5, "max_health": 400, "damage": 55, "crit_chance": 0.08, "crit_damage": 1.5, "fire_rate": 0.80, "move_speed": 115.0, "shield": 0, "health_regen": 0, "armor": 0, "base_points": 5}
		},
		"boss_stats": {
			"level": 5, "max_health": 3000, "bullet_damage": 100, "aoe_damage": 100, "fire_rate": 0.5, "move_speed": 75.0, "crit_chance": 0.0, "crit_damage": 0.0, "shield": 0, "health_regen": 0, "armor": 10, "base_points": 25
		}
	}

func get_monster_stats(level: int) -> Dictionary:
	var lvl_str = str(level)
	var levels_dict = stats_data.get("monster_levels", {})
	if levels_dict.has(lvl_str):
		return levels_dict[lvl_str].duplicate()
	
	# Scaling dynamique pour les niveaux > 5
	return {
		"level": level,
		"max_health": 200 + (level - 1) * 50,
		"damage": 30 + (level - 1) * 6,
		"crit_chance": clamp(0.02 * (level - 2), 0.0, 0.25),
		"crit_damage": 1.2 + 0.1 * level,
		"fire_rate": max(0.4, 1.0 - (level - 1) * 0.05),
		"move_speed": 95.0 + (level - 1) * 5.0,
		"shield": 0,
		"health_regen": 0,
		"armor": max(0, (level - 1) * 2),
		"base_points": level
	}

func get_boss_stats() -> Dictionary:
	return stats_data.get("boss_stats", {
		"level": 5,
		"max_health": 3000,
		"bullet_damage": 100,
		"aoe_damage": 100,
		"fire_rate": 0.5,
		"move_speed": 75.0,
		"crit_chance": 0.0,
		"crit_damage": 0.0,
		"shield": 0,
		"health_regen": 0,
		"armor": 10,
		"base_points": 25
	}).duplicate()

func calculate_kill_points(monster_level: int, zone_level: int) -> int:
	# Règle utilisateur:
	# Zone 1 : 1 niveau = 1 point (Niveau 1 -> 1 point, Niveau 5 -> 5 points)
	# Zone N (N > 1) : points = niveau_du_monstre * (3 * zone_level)
	if zone_level <= 1:
		return monster_level
	else:
		return monster_level * 3 * zone_level
