# 🎯 Objectifs de Résolution — Erreurs & Avertissements du Débogueur

Ce document est la feuille de route pas-à-pas pour éliminer un par un les 21 messages du débogueur Godot.
Conformément à la règle de progression, nous résolvons **une seule étape à la fois**.

---

## 📋 TODO List des Résolutions

### 📡 Groupe A : Signaux Déclarés non émis localement (`unused_signal` dans `EventBus.gd`)
> **Diagnostic :** Godot signale que ces signaux sont déclarés mais jamais émis par `EventBus.gd` lui-même (ce qui est normal pour un EventBus / Bus d'événements, mais le linter statique demande confirmation explicite).

- [x] **Étape 1 :** Neutraliser le warning `unused_signal` sur les signaux du joueur dans `EventBus.gd`
  - `player_health_changed`
  - `player_ammo_changed`
  - `player_dash_started`
  - `player_dash_ready`
  - `player_dash_updated`
  - `player_died`
- [x] **Étape 2 :** Neutraliser le warning `unused_signal` sur les signaux d'ennemis et combat dans `EventBus.gd`
  - `enemy_damaged`
  - `enemy_died`
  - `zone_enemies_updated`
  - `room_entered`
  - `room_cleared`
  - `room_enemies_updated`
- [x] **Étape 3 :** Neutraliser le warning `unused_signal` sur les signaux de Boss et progression dans `EventBus.gd`
  - `boss_spawned`
  - `boss_health_changed`
  - `boss_defeated`
  - `zone_cleared`
- [x] **Étape 4 :** Neutraliser le warning `unused_signal` sur les signaux de drops / munitions dans `EventBus.gd`
  - `ammo_collected`
  - `bonus_collected`
  - `emergency_drop_spawned`

---

### ➗ Groupe B : Divisions Entières Troncantes (`integer_division` dans `Room.gd`)
> **Diagnostic :** Godot prévient que diviser deux nombres entiers (`int / int`) tronque la virgule sans arrondi, risquant de masquer des erreurs de calcul.

- [ ] **Étape 5 :** Sécuriser la division entière du calcul de vague initiale dans `Room.gd` (Ligne 170 : `var count_in_wave = total_enemies / wave_count`)
- [ ] **Étape 6 :** Sécuriser la division entière du calcul de vague suivante dans `Room.gd` (Ligne 290 : `var wave_size = total_enemies / wave_count`)

---

## 📍 Statut Actuel
- **Terminé :** Étapes 1 à 4 (Les 19 avertissements `unused_signal` d'EventBus.gd sont résolus)
- **En cours :** Étape 5 (Division entière vague initiale dans `Room.gd:170`)
- **Prochaine étape :** Étape 6 (Division entière vague suivante dans `Room.gd:290`)

