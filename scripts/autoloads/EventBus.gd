extends Node

# Signaux relatifs au joueur
@warning_ignore("unused_signal")
signal player_health_changed(current_hp: int, max_hp: int, current_shield: int, max_shield: int)
@warning_ignore("unused_signal")
signal player_ammo_changed(current_ammo: int, max_ammo: int)
@warning_ignore("unused_signal")
signal player_dash_started(cooldown_duration: float)
@warning_ignore("unused_signal")
signal player_dash_ready()
@warning_ignore("unused_signal")
signal player_dash_updated(current_charges: int, max_charges: int, cooldown_pct: float)
@warning_ignore("unused_signal")
signal player_died()

# Signaux relatifs aux ennemis et combat
@warning_ignore("unused_signal")
signal enemy_damaged(enemy: Node2D, current_hp: float, max_hp: float)
@warning_ignore("unused_signal")
signal enemy_died(enemy: Node2D, drop_pos: Vector2, points_gained: int)
@warning_ignore("unused_signal")
signal zone_enemies_updated(remaining: int, total: int)
@warning_ignore("unused_signal")
signal room_entered(room_index: int, total_rooms: int, room_name: String)
@warning_ignore("unused_signal")
signal room_cleared(room_index: int)
@warning_ignore("unused_signal")
signal room_enemies_updated(remaining: int, total: int)

# Signaux relatifs au Boss
@warning_ignore("unused_signal")
signal boss_spawned(boss_name: String, max_hp: float)
@warning_ignore("unused_signal")
signal boss_health_changed(current_hp: float, max_hp: float)
@warning_ignore("unused_signal")
signal boss_defeated()
@warning_ignore("unused_signal")
signal zone_cleared()

# Signaux relatifs aux munitions et drops
@warning_ignore("unused_signal")
signal ammo_collected(amount: int)
@warning_ignore("unused_signal")
signal bonus_collected(bonus_type: String, bonus_desc: String, pos: Vector2)
@warning_ignore("unused_signal")
signal emergency_drop_spawned(pos: Vector2)
