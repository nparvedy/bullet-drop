# 🗺️ Guide Pas à Pas : Créer votre Première Map de Combat (Zone 1)

Ce guide détaille **chaque action concrète** à effectuer dans **Godot 4** pour concevoir, structurer et tester votre première arène de combat pour *Bullet Drop*.

---

## 📋 Table des Matières

1. [Concept & Architecture de l'Arène](#1-concept--architecture-de-larène)
2. [Étape 1 : Création du fichier de scène](#étape-1--création-du-fichier-de-scène)
3. [Étape 2 : Construction de l'arborescence des Nœuds](#étape-2--construction-de-larborescence-des-nœuds)
4. [Étape 3 : Configuration pas à pas dans l'Inspecteur](#étape-3--configuration-pas-à-pas-dans-linspecteur)
5. [Étape 4 : Configuration des Calques de Collision (Collision Layers)](#étape-4--configuration-des-calques-de-collision-collision-layers)
6. [Étape 5 : Script de gestion de la Zone (`Zone1.gd`)](#étape-5--script-de-gestion-de-la-zone-zone1gd)
7. [Étape 6 : Prototypes rapides (Joueur & Ennemi de test)](#étape-6--prototypes-rapides-joueur--ennemi-de-test)
8. [Étape 7 : Test et Validation (Touche F6)](#étape-7--test-et-validation-touche-f6)
9. [Évolution : Transformer en `BaseZone` réutilisable](#évolution--transformer-en-basezone-réutilisable)

---

## 1. Concept & Architecture de l'Arène

Pour respecter le Game Design de *Bullet Drop* (*Top-down arena shooter* avec quota fixe d'ennemis) :
* **Type de zone :** Arène fermée rectangulaire (ex: `1920 × 1080` pixels).
* **Quota :** 20 ennemis par run sur la Zone 1.
* **Condition de fin :** Une fois les 20 ennemis éliminés, un **Portail de Sortie** s'ouvre pour passer à la zone suivante.

---

## Étape 1 : Création du fichier de scène

1. Ouvrez votre projet dans **Godot 4**.
2. Dans le menu supérieur, cliquez sur **Scène > Nouvelle scène**.
3. Dans le panneau de gauche *Créer un nœud racine*, cliquez sur **Scène 2D** (cela crée un nœud `Node2D`).
4. Renommez ce nœud racine : clic droit sur `Node2D` > **Renommer** (ou touche `F2`) > tapez `Zone1`.
5. Enregistrez la scène :
   * Appuyez sur `Ctrl + S`.
   * Naviguez dans le dossier `res://scenes/levels/`.
   * Nommez le fichier `Zone1.tscn` et cliquez sur **Enregistrer**.

---

## Étape 2 : Construction de l'arborescence des Nœuds

Vous allez ajouter les enfants sous `Zone1`. Voici la structure exacte à obtenir :

```text
Zone1 (Node2D)  <-- Scène racine [Attaché à Zone1.gd]
├── Background (ColorRect ou Sprite2D)
├── ArenaBounds (StaticBody2D)
│   ├── TopWall (CollisionShape2D)
│   ├── BottomWall (CollisionShape2D)
│   ├── LeftWall (CollisionShape2D)
│   └── RightWall (CollisionShape2D)
├── Obstacles (Node2D)
├── PlayerSpawn (Marker2D)
├── EnemySpawners (Node2D)
│   ├── Spawner1 (Marker2D)
│   ├── Spawner2 (Marker2D)
│   ├── Spawner3 (Marker2D)
│   └── Spawner4 (Marker2D)
├── Entities (Node2D)
│   ├── Enemies (Node2D)
│   └── Drops (Node2D)
├── ExitPortal (Area2D)
│   ├── PortalVisual (ColorRect ou Sprite2D)
│   └── CollisionShape2D (CollisionShape2D)
├── SpawnTimer (Timer)
└── CanvasLayer_HUD (CanvasLayer)
    └── MarginContainer (MarginContainer)
        └── LabelQuota (Label)
```

### Comment ajouter chaque nœud :
* Sélectionnez `Zone1`, appuyez sur `Ctrl + A` (ou clic droit > *Ajouter un nœud enfant*), cherchez le type de nœud voulu, puis validez.
* Pour placer un nœud sous un parent spécifique (ex: les murs sous `ArenaBounds`), sélectionnez `ArenaBounds` avant de faire `Ctrl + A`.

---

## Étape 3 : Configuration pas à pas dans l'Inspecteur

### 3.1. Le Fond d'arène (`Background`)
1. Sélectionnez le nœud `Background` (ajoutez un `ColorRect`).
2. Dans l'Inspecteur à droite :
   * **Layout > Transform > Size** : `X = 1920`, `Y = 1080` (ou la taille souhaitée pour votre arène).
   * **Color** : Choisissez une couleur sombre (ex: `#1a1a24`) pour que les projectiles et personnages ressortent bien.

---

### 3.2. Les Murs invisibles (`ArenaBounds`)
Le nœud `ArenaBounds` (`StaticBody2D`) empêche le joueur et les ennemis de sortir de l'écran.

1. Sélectionnez `ArenaBounds`.
2. Pour chacun des 4 enfants `CollisionShape2D` :
   * **TopWall :**
     * Dans l'inspecteur : `Shape` > Nouveau `RectangleShape2D`.
     * Cliquez sur le rectangle bleu créé pour éditer sa taille : `Size = (1920, 40)`.
     * `Transform > Position` : `(960, -20)`.
   * **BottomWall :**
     * `Shape` > Nouveau `RectangleShape2D` > `Size = (1920, 40)`.
     * `Transform > Position` : `(960, 1100)`.
   * **LeftWall :**
     * `Shape` > Nouveau `RectangleShape2D` > `Size = (40, 1080)`.
     * `Transform > Position` : `(-20, 540)`.
   * **RightWall :**
     * `Shape` > Nouveau `RectangleShape2D` > `Size = (40, 1080)`.
     * `Transform > Position` : `(1940, 540)`.

---

### 3.3. Le Point de départ du Joueur (`PlayerSpawn`)
1. Sélectionnez `PlayerSpawn` (`Marker2D`).
2. Dans l'Inspecteur : `Transform > Position` = `(960, 540)` (plein centre de la carte).
3. Activez `Gizmos > Display Folded` ou vérifiez dans la vue 2D que la croix rouge du marker est bien au centre.

---

### 3.4. Les Points d'apparition des Ennemis (`EnemySpawners`)
1. Placez les 4 `Marker2D` autour de la zone pour varier les points d'arrivée :
   * `Spawner1` : `Transform > Position` = `(150, 150)` (Haut Gauche)
   * `Spawner2` : `Transform > Position` = `(1770, 150)` (Haut Droite)
   * `Spawner3` : `Transform > Position` = `(150, 930)` (Bas Gauche)
   * `Spawner4` : `Transform > Position` = `(1770, 930)` (Bas Droite)

---

### 3.5. Le Portail de Sortie (`ExitPortal`)
1. Sous `ExitPortal` (`Area2D`) :
   * Positionnez `ExitPortal` : `Transform > Position` = `(960, 120)` (Haut centre).
   * **PortalVisual** (`ColorRect`) : `Size = (64, 64)`, `Position = (-32, -32)`, `Color = Cyan` ou `#00ffff`.
   * **CollisionShape2D** : `Shape` > Nouveau `CircleShape2D` avec `Radius = 32`.
2. Par défaut, masquez-le car il ne s'active qu'à la fin :
   * `Visibility > Visible` = `false`.
   * `Monitoring` = `false`.
   * `Monitorable` = `false`.

---

### 3.6. Le Timer de Vagues (`SpawnTimer`)
1. Sélectionnez `SpawnTimer` (`Timer`).
2. Dans l'Inspecteur :
   * `Wait Time` : `1.5` (Un ennemi apparaitra toutes les 1.5 secondes).
   * `Autostart` : `true`.
   * `One Shot` : `false`.

---

### 3.7. Le HUD du Quota (`CanvasLayer_HUD`)
1. Sous `CanvasLayer_HUD` > `MarginContainer` > `LabelQuota` (`Label`) :
   * `MarginContainer` : Layout > Ancrage > **Haut Centre** (Top Wide ou Top Center).
   * `LabelQuota` :
     * Texte : `Ennemis restants : 20 / 20`
     * `Theme Overrides > Font Sizes > Font Size` : `24`.

---

## Étape 4 : Configuration des Calques de Collision (Collision Layers)

Pour un jeu propre et sans bugs de collision, configurez vos calques dans Godot :

1. Allez dans le menu : **Projet > Paramètres du projet > Onglet Général**.
2. Dans le menu de gauche, descendez jusqu'à **Layer Names > 2D Physics**.
3. Nommez vos calques ainsi :
   * **Layer 1 :** `World` (Murs, obstacles)
   * **Layer 2 :** `Player` (Le joueur)
   * **Layer 3 :** `Enemies` (Les monstres)
   * **Layer 4 :** `PlayerProjectiles` (Balles tirées par le joueur)
   * **Layer 5 :** `EnemyProjectiles` (Tirs des ennemis)
   * **Layer 6 :** `Drops` (Bonus et points au sol)
   * **Layer 7 :** `Portals` (Portail de fin)

4. Appliquez sur `ArenaBounds` (`StaticBody2D`) :
   * `Collision > Layer` : Cochez **World (1)** uniquement.
   * `Collision > Mask` : Laissez vide.
5. Appliquez sur `ExitPortal` (`Area2D`) :
   * `Collision > Layer` : Cochez **Portals (7)**.
   * `Collision > Mask` : Cochez **Player (2)** (pour détecter quand le joueur entre dedans).

---

## Étape 5 : Script de gestion de la Zone (`Zone1.gd`)

1. Sélectionnez le nœud racine `Zone1`.
2. Cliquez sur l'icône de script (parchemin avec un `+`) au-dessus de l'arbre de scène.
3. Choisissez le chemin : `res://scenes/levels/Zone1.gd` (ou `res://scripts/levels/Zone1.gd`).
4. Collez le code suivant :

```gdscript
extends Node2D
class_name CombatZone

# --- EXPORTS & CONFIGURATION ---
@export_group("Configuration de la Zone")
@export var zone_name: String = "Zone 1 - L'Arène des Ombres"
@export var total_enemies_quota: int = 20
@export var enemy_scene: PackedScene # Glissez votre scène d'ennemi ici dans l'Inspecteur
@export var player_scene: PackedScene # Glissez votre scène Player ici si instancié par script

# --- RÉFÉRENCES AUX NŒUDS ---
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawners: Node2D = $EnemySpawners
@onready var enemies_container: Node2D = $Entities/Enemies
@onready var exit_portal: Area2D = $ExitPortal
@onready var spawn_timer: Timer = $SpawnTimer
@onready var label_quota: Label = $CanvasLayer_HUD/MarginContainer/LabelQuota

# --- VARIABLES D'ÉTAT ---
var enemies_spawned_count: int = 0
var enemies_alive_count: int = 0
var zone_cleared: bool = false

func _ready() -> void:
	# 1. Initialiser le portail (désactivé)
	exit_portal.visible = false
	exit_portal.monitoring = false
	exit_portal.body_entered.connect(_on_exit_portal_body_entered)
	
	# 2. Connecter le timer de spawn
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# 3. Mettre à jour l'affichage
	_update_hud()
	
	# 4. Spawner le joueur si une scène est assignée
	_spawn_player()
	
	print("[Zone1] Initialisée avec un quota de %d ennemis." % total_enemies_quota)

func _spawn_player() -> void:
	if player_scene:
		var player_instance = player_scene.instantiate()
		player_instance.global_position = player_spawn.global_position
		add_child(player_instance)
		# Assigner le joueur au groupe "player"
		if not player_instance.is_in_group("player"):
			player_instance.add_to_group("player")

func _on_spawn_timer_timeout() -> void:
	# Arrêter de spawner si le quota total est atteint
	if enemies_spawned_count >= total_enemies_quota:
		spawn_timer.stop()
		return
	
	_spawn_single_enemy()

func _spawn_single_enemy() -> void:
	if not enemy_scene:
		push_warning("[Zone1] Aucune scène d'ennemi (enemy_scene) assignée dans l'Inspecteur !")
		return
	
	# Sélectionner un spawner aléatoire
	var spawners = enemy_spawners.get_children()
	if spawners.is_empty():
		return
	var chosen_spawner: Marker2D = spawners.pick_random()
	
	# Instancier l'ennemi
	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.global_position = chosen_spawner.global_position
	enemies_container.add_child(enemy_instance)
	
	# Suivre la mort de l'ennemi via son signal tree_exiting ou signal personnalisé
	enemy_instance.tree_exited.connect(_on_enemy_defeated)
	
	enemies_spawned_count += 1
	enemies_alive_count += 1
	_update_hud()

func _on_enemy_defeated() -> void:
	enemies_alive_count -= 1
	_update_hud()
	
	# Vérifier si la zone est nettoyée (quota total atteint ET plus aucun monstre vivant)
	if enemies_spawned_count >= total_enemies_quota and enemies_alive_count <= 0:
		_on_zone_cleared()

func _on_zone_cleared() -> void:
	if zone_cleared:
		return
	zone_cleared = true
	print("[Zone1] 🎉 Zone nettoyée ! Ouverture du portail !")
	
	# Activer et afficher le portail
	exit_portal.visible = true
	exit_portal.monitoring = true
	
	# Effet visuel optionnel (ex: Animation / Flash)
	if label_quota:
		label_quota.text = "🏆 ZONE NETTOYÉE ! Prenez le portail !"
		label_quota.modulate = Color.GREEN

func _on_exit_portal_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		print("[Zone1] Le joueur entre dans le portail ! Passage à la Zone 2...")
		# Ici : transition vers la zone suivante
		# get_tree().change_scene_to_file("res://scenes/levels/Zone2.tscn")

func _update_hud() -> void:
	if label_quota:
		var remaining = (total_enemies_quota - enemies_spawned_count) + enemies_alive_count
		label_quota.text = "Ennemis restants : %d / %d" % [remaining, total_enemies_quota]
```

---

## Étape 6 : Prototypes rapides (Joueur & Ennemi de test)

Si vos scènes finales de joueur et d'ennemis ne sont pas encore prêtes, créez ces 2 scènes de test légères en 2 minutes pour valider immédiatement votre map.

### 6.1. Joueur Temporaire (`res://scenes/entities/player/TestPlayer.tscn`)
1. Créez une nouvelle scène avec un `CharacterBody2D`, renommé `TestPlayer`.
2. Ajoutez un enfant `ColorRect` (`Size: 32x32`, `Position: -16, -16`, `Color: Bleu`).
3. Ajoutez un enfant `CollisionShape2D` (`RectangleShape2D: 32x32`).
4. Dans `Collision > Layer` = Cochez `Player (2)`, `Mask` = Cochez `World (1)`.
5. Ajoutez le script `TestPlayer.gd` :

```gdscript
extends CharacterBody2D

@export var speed: float = 300.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()
```

6. Sauvegardez dans `res://scenes/entities/player/TestPlayer.tscn`.

---

### 6.2. Ennemi Temporaire (`res://scenes/entities/enemies/TestEnemy.tscn`)
1. Créez une nouvelle scène avec un `CharacterBody2D`, renommé `TestEnemy`.
2. Ajoutez un enfant `ColorRect` (`Size: 28x28`, `Position: -14, -14`, `Color: Rouge`).
3. Ajoutez un enfant `CollisionShape2D` (`CircleShape2D: radius 14`).
4. Dans `Collision > Layer` = Cochez `Enemies (3)`, `Mask` = Cochez `World (1)` et `Player (2)`.
5. Ajoutez un enfant `Timer` nommé `LifeTimer` (`Wait Time: 4.0`, `Autostart: true`, `One Shot: true`).
6. Ajoutez le script `TestEnemy.gd` :

```gdscript
extends CharacterBody2D

@export var speed: float = 100.0
var player_target: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	# Trouver le joueur
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player_target = players[0]
	
	# Détruire l'ennemi automatiquement au bout de 4s (simule une mort pour le test)
	$LifeTimer.timeout.connect(queue_free)

func _physics_process(_delta: float) -> void:
	if player_target:
		var dir = (player_target.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
```

7. Sauvegardez dans `res://scenes/entities/enemies/TestEnemy.tscn`.

---

## Étape 7 : Test et Validation (Touche F6)

1. Ouvrez votre scène `res://scenes/levels/Zone1.tscn`.
2. Dans l'Inspecteur de la racine `Zone1` :
   * Glissez `TestPlayer.tscn` dans le champ `Player Scene`.
   * Glissez `TestEnemy.tscn` dans le champ `Enemy Scene`.
3. Appuyez sur la touche **`F6`** (Exécuter la scène courante).

### Checklist de bon fonctionnement :
- [ ] Le carré bleu (Joueur) bouge avec les flèches / ZQSD et bute contre les 4 murs.
- [ ] Les carrés rouges (Ennemis) apparaissent aux 4 coins et convergent vers le joueur.
- [ ] Le compteur en haut diminue au fur et à mesure que les ennemis disparaissent.
- [ ] Une fois les 20 ennemis éliminés, le portail Cyan apparaît en haut de l'écran.
- [ ] Quand le joueur touche le portail, la console affiche la validation de victoire de zone.

---

## Évolution : Transformer en `BaseZone` réutilisable

Quand votre Zone 1 fonctionne :
1. Renommez `Zone1.tscn` en `BaseZone.tscn` (ou dupliquez-la).
2. Pour créer la **Zone 2**, faites clic droit sur `BaseZone.tscn` > **Nouvelle scène héritée**.
3. Vous n'aurez plus qu'à changer :
   * La texture du sol / couleur d'ambiance.
   * La disposition des obstacles.
   * Les types d'ennemis dans le quota.
