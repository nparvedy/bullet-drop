extends Node

# Signaux relatifs au joueur
signal player_health_changed(current_hp: int, max_hp: int, current_shield: int, max_shield: int)
signal player_ammo_changed(current_ammo: int, max_ammo: int)
signal player_dash_started(cooldown_duration: float)
signal player_dash_ready()
signal player_dash_updated(current_charges: int, max_charges: int, cooldown_pct: float)
signal player_died()

# Signaux relatifs aux ennemis et combat
signal enemy_damaged(enemy: Node2D, current_hp: float, max_hp: float)
signal enemy_died(enemy: Node2D, drop_pos: Vector2, points_gained: int)
signal zone_enemies_updated(remaining: int, total: int)
signal room_entered(room_index: int, total_rooms: int, room_name: String)
signal room_cleared(room_index: int)
signal room_enemies_updated(remaining: int, total: int)

# Signaux relatifs au Boss
signal boss_spawned(boss_name: String, max_hp: float)
signal boss_health_changed(current_hp: float, max_hp: float)
signal boss_defeated()
signal zone_cleared()

# Signaux relatifs aux munitions et drops
signal ammo_collected(amount: int)
signal bonus_collected(bonus_type: String, bonus_desc: String, pos: Vector2)
signal emergency_drop_spawned(pos: Vector2)
