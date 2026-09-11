extends Node

# Signaux relatifs au joueur
signal player_health_changed(current_hp: int, max_hp: int)
signal player_ammo_changed(current_ammo: int, max_ammo: int)
signal player_dash_started(cooldown_duration: float)
signal player_dash_ready()
signal player_died()

# Signaux relatifs aux ennemis et combat
signal enemy_damaged(enemy: Node2D, current_hp: float, max_hp: float)
signal enemy_died(enemy: Node2D, drop_pos: Vector2)
signal zone_enemies_updated(remaining: int, total: int)

# Signaux relatifs aux munitions et drops
signal ammo_collected(amount: int)
signal emergency_drop_spawned(pos: Vector2)
