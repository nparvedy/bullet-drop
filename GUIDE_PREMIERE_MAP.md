# 🎨 Guide Pas à Pas : Créer votre Première Map avec des Tuiles (TileMap) dans Godot 4

Ce guide vous explique pas à pas comment **dessiner votre arène de combat tuile par tuile** (sol, murs avec collisions automatiques, obstacles, décors) en utilisant le système de **TileMap / TileSet** de Godot 4.

> 🎁 **Un jeu de tuiles prêt à l'emploi** a déjà été généré pour vous dans votre projet :  
> `res://assets/sprites/environment/tileset_arena.png` (tuiles de 32×32 px : dalles, murs, piliers, caisses, néons, etc.).

---

## 📋 Table des Matières

1. [Comprendre le fonctionnement des Tuiles dans Godot 4](#1-comprendre-le-fonctionnement-des-tuiles-dans-godot-4)
2. [Étape 1 : Créer la scène `Zone1` et la ressource `TileSet`](#étape-1--créer-la-scène-zone1-et-la-ressource-tileset)
3. [Étape 2 : Configurer les Collisions Physiques dans le TileSet](#étape-2--configurer-les-collisions-physiques-dans-le-tileset)
4. [Étape 3 : Structurer les Calques de Tuiles (`TileMapLayer`)](#étape-3--structurer-les-calques-de-tuiles-tilemaplayer)
5. [Étape 4 : Dessiner votre Arène dans l'Éditeur 2D](#étape-4--dessiner-votre-arène-dans-léditeur-2d)
6. [Étape 5 : Placer les Éléments de Gameplay (Spawn, Ennemis, Portail)](#étape-5--placer-les-éléments-de-gameplay-spawn-ennemis-portail)
7. [Étape 6 : Attacher le Script de Zone (`Zone1.gd`)](#étape-6--attacher-le-script-de-zone-zone1gd)
8. [Étape 7 : Tester la Map avec la touche F6](#étape-7--tester-la-map-avec-la-touche-f6)

---

## 1. Comprendre le fonctionnement des Tuiles dans Godot 4

* **Une Tuile (Tile) :** Un petit carré graphique (ex: $32 \times 32$ pixels).
* **Un `TileSet` :** Votre palette de peinture. C'est ici que l'on découpe l'image et que l'on indique quelles tuiles sont **solides** (murs/obstacles) et quelles tuiles sont **traversables** (le sol).
* **Un `TileMapLayer` :** Le calque sur lequel vous dessinez dans l'éditeur (comme dans Photoshop/GIMP avec des calques superposés).

---

## Étape 1 : Créer la scène `Zone1` et la ressource `TileSet`

### 1.1. Créer la scène
1. Ouvrez **Godot 4**.
2. Menu supérieur : **Scène > Nouvelle scène**.
3. Choisissez **Scène 2D** (crée un nœud `Node2D`).
4. Renommez la racine en **`Zone1`**.
5. Sauvegardez la scène sous : `res://scenes/levels/Zone1.tscn` (`Ctrl + S`).

---

### 1.2. Créer le premier calque de tuiles
1. Sélectionnez `Zone1`, appuyez sur `Ctrl + A`.
2. Recherchez et ajoutez un nœud **`TileMapLayer`** (ou `TileMap`).
3. Renommez ce nœud en **`GroundLayer`** (calque du sol).

---

### 1.3. Créer et configurer le `TileSet`
1. Sélectionnez `GroundLayer`.
2. Dans l'Inspecteur à droite, trouvez la propriété **Tile Set**.
3. Cliquez sur la case vide à côté et choisissez **Nouveau TileSet**.
4. Cliquez sur le **TileSet** qui vient d'apparaître pour déplier ses paramètres :
   * **Tile Size :** Laissez `X = 32`, `Y = 32`.

---

### 1.4. Importer la planche de tuiles dans le TileSet
1. Regardez en bas de votre écran Godot : l'onglet **TileSet** s'est ouvert.
2. Dans le panneau de fichiers en bas à gauche de Godot, trouvez l'image :  
   `res://assets/sprites/environment/tileset_arena.png`.
3. **Glissez-déposez** ce fichier `tileset_arena.png` directement dans la zone grise de l'onglet **TileSet** en bas.
4. Une popup apparaît : *"Voulez-vous créer automatiquement les tuiles dans l'atlas ?"* 👉 Cliquez sur **Oui (Yes)**.
5. Vos tuiles sont maintenant découpées en cases de 32×32 px prêtes à être utilisées !

---

## Étape 2 : Configurer les Collisions Physiques dans le TileSet

Grâce à cette étape, chaque mur que vous dessinerez bloquera automatiquement le joueur et les monstres, sans aucun réglage manuel supplémentaire !

1. Dans l'Inspecteur à droite, cliquez sur la ressource **TileSet** (sur `GroundLayer`).
2. Dépliez la section **Physics Layers** (Calques physiques) :
   * Cliquez sur **Ajouter un élément** (*Add Element*).
   * **Collision Layer :** Cochez le calque **1** (Murs / Monde).
   * **Collision Mask :** Laissez vide.
3. Allez dans l'onglet **TileSet** tout en bas de l'écran :
   * Cliquez sur l'onglet intérieur **Sélectionner** (*Select*).
   * Cliquez sur le sous-onglet **Propriétés de peinture** (*Paint Properties* / icône de pot de peinture ou *Peindre*).
   * Dans le menu déroulant qui s'affiche, choisissez **Physics Layer 0 > Polygone de collision 0** (*Collision Polygon 0*).
   * **Cliquez simplement sur chaque tuile de Mur et d'Obstacle** (la 2ème et 3ème ligne de la planche) : un carré bleu/rouge de collision s'applique automatiquement sur toute la case !
4. Sauvegardez le projet (`Ctrl + S`).

---

## Étape 3 : Structurer les Calques de Tuiles (`TileMapLayer`)

Pour dessiner proprement sans écraser le sol quand vous posez un mur ou un décor, nous créons 3 calques qui partagent le **même TileSet** :

1. Cliquez sur `GroundLayer` dans votre arbre de scène.
2. Dans l'Inspecteur, faites clic droit sur la ressource **TileSet > Copier** (Copy).
3. Ajoutez un deuxième enfant sous `Zone1` (`Ctrl + A`) de type **`TileMapLayer`**, renommez-le **`WallsLayer`** :
   * Dans son Inspecteur, faites clic droit sur `Tile Set` > **Coller** (Paste).
4. Ajoutez un troisième enfant sous `Zone1` de type **`TileMapLayer`**, renommez-le **`DecorLayer`** :
   * Dans son Inspecteur, faites clic droit sur `Tile Set` > **Coller** (Paste).

### Voici l'arborescence complète à obtenir dans `Zone1` :

```text
Zone1 (Node2D)  [Attaché à Zone1.gd]
├── GroundLayer (TileMapLayer)       <-- Pour dessiner le sol
├── WallsLayer (TileMapLayer)        <-- Pour dessiner les murs solides
├── DecorLayer (TileMapLayer)        <-- Pour poser des néons, débris, etc.
├── PlayerSpawn (Marker2D)           <-- Position de départ (ex: x=960, y=540)
├── EnemySpawners (Node2D)           <-- Points de spawn des monstres
│   ├── Spawner1 (Marker2D)
│   ├── Spawner2 (Marker2D)
│   ├── Spawner3 (Marker2D)
│   └── Spawner4 (Marker2D)
├── Entities (Node2D)
│   ├── Enemies (Node2D)
│   └── Drops (Node2D)
├── ExitPortal (Area2D)              <-- Portail de sortie vers Zone 2
│   ├── PortalVisual (ColorRect)
│   └── CollisionShape2D (CircleShape2D)
├── SpawnTimer (Timer)               <-- Cadence d'apparition
└── CanvasLayer_HUD (CanvasLayer)    <-- Affichage du quota
    └── MarginContainer
        └── LabelQuota (Label)
```

---

## Étape 4 : Dessiner votre Arène dans l'Éditeur 2D

En bas de l'écran, cliquez sur l'onglet **TileMapLayer** (ou **TileMap**) pour ouvrir la palette de dessin.

### 4.1. Dessiner le Sol
1. Dans l'arbre de scène, sélectionnez **`GroundLayer`**.
2. En bas dans la palette, cliquez sur l'une des dalles de sol (1ère ligne de `tileset_arena.png`).
3. Dans la barre d'outils au-dessus de la vue 2D :
   * Choisissez l'outil **Rectangle** (icône rectangle ou touche `Shift + R`).
   * Cliquez et glissez dans la vue 2D pour créer une grande surface au sol (ex: de $(0, 0)$ à $(1920, 1080)$, soit environ $60 \times 34$ tuiles).
4. Prenez le **Pinceau** (touche `B`) pour peindre quelques dalles fissurées, grilles ou zones de danger au centre de l'arène pour donner du style !

---

### 4.2. Dessiner les Murs Extérieurs et les Piliers
1. Dans l'arbre de scène, sélectionnez **`WallsLayer`**.
2. En bas dans la palette, choisissez les tuiles de bordure de mur (2ème ligne).
3. Prenez l'outil **Ligne** ou **Pinceau** et dessinez les 4 murs fermés tout autour de votre sol.
4. Au centre de l'arène, placez **4 à 6 piliers ou caisses** (3ème ligne) : ils serviront de boucliers naturels au joueur pour esquiver les tirs ennemis !
*(Toutes ces tuiles ont la collision physique active configurée à l'étape 2).*

---

### 4.3. Ajouter des Décorations
1. Sélectionnez **`DecorLayer`**.
2. Posez des balises lumineuses (néons bleus/oranges), des taches d'huile ou des débris sur le sol.

---

## Étape 5 : Placer les Éléments de Gameplay (Spawn, Ennemis, Portail)

1. **`PlayerSpawn` (`Marker2D`) :**
   * Placez-le au centre de l'arène (ex: `Position = (960, 540)`).

2. **`EnemySpawners` (`Node2D`) :**
   * Ajoutez 4 nœuds `Marker2D` enfants (`Spawner1`, `Spawner2`, etc.).
   * Placez-les aux 4 angles intérieurs de votre arène de tuiles.

3. **`ExitPortal` (`Area2D`) :**
   * Positionnez-le en haut au centre de l'arène.
   * Ajoutez un `CollisionShape2D` (`CircleShape2D` de rayon 32).
   * Ajoutez un visuel (`ColorRect` cyan $64 \times 64$ ou sprite).
   * Dans l'Inspecteur : `Visibility > Visible = false`, `Monitoring = false`.

4. **`SpawnTimer` (`Timer`) :**
   * `Wait Time = 1.5`, `Autostart = true`, `One Shot = false`.

5. **`CanvasLayer_HUD` :**
   * Ajoutez un `Label` (`LabelQuota`) affichant *"Ennemis restants : 20 / 20"*.

---

## Étape 6 : Attacher le Script de Zone (`Zone1.gd`)

Sélectionnez `Zone1`, cliquez sur l'icône de script (`+`) et enregistrez sous `res://scenes/levels/Zone1.gd` :

```gdscript
extends Node2D
class_name CombatZone

@export_group("Configuration de la Zone")
@export var total_enemies_quota: int = 20
@export var enemy_scene: PackedScene
@export var player_scene: PackedScene

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawners: Node2D = $EnemySpawners
@onready var enemies_container: Node2D = $Entities/Enemies
@onready var exit_portal: Area2D = $ExitPortal
@onready var spawn_timer: Timer = $SpawnTimer
@onready var label_quota: Label = $CanvasLayer_HUD/MarginContainer/LabelQuota

var enemies_spawned_count: int = 0
var enemies_alive_count: int = 0
var zone_cleared: bool = false

func _ready() -> void:
	exit_portal.visible = false
	exit_portal.monitoring = false
	exit_portal.body_entered.connect(_on_exit_portal_body_entered)
	
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_update_hud()
	_spawn_player()

func _spawn_player() -> void:
	if player_scene:
		var player_instance = player_scene.instantiate()
		player_instance.global_position = player_spawn.global_position
		add_child(player_instance)
		if not player_instance.is_in_group("player"):
			player_instance.add_to_group("player")

func _on_spawn_timer_timeout() -> void:
	if enemies_spawned_count >= total_enemies_quota:
		spawn_timer.stop()
		return
	_spawn_single_enemy()

func _spawn_single_enemy() -> void:
	if not enemy_scene:
		return
	
	var spawners = enemy_spawners.get_children()
	if spawners.is_empty():
		return
	var chosen_spawner: Marker2D = spawners.pick_random()
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = chosen_spawner.global_position
	enemies_container.add_child(enemy)
	enemy.tree_exited.connect(_on_enemy_defeated)
	
	enemies_spawned_count += 1
	enemies_alive_count += 1
	_update_hud()

func _on_enemy_defeated() -> void:
	enemies_alive_count -= 1
	_update_hud()
	if enemies_spawned_count >= total_enemies_quota and enemies_alive_count <= 0:
		_on_zone_cleared()

func _on_zone_cleared() -> void:
	if zone_cleared:
		return
	zone_cleared = true
	exit_portal.visible = true
	exit_portal.monitoring = true
	if label_quota:
		label_quota.text = "🏆 ZONE 1 NETTOYÉE ! Prenez le portail !"
		label_quota.modulate = Color.GREEN

func _on_exit_portal_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		print("Victoire Zone 1 ! Transition vers Zone 2...")

func _update_hud() -> void:
	if label_quota:
		var remaining = (total_enemies_quota - enemies_spawned_count) + enemies_alive_count
		label_quota.text = "Ennemis restants : %d / %d" % [remaining, total_enemies_quota]
```

---

## Étape 7 : Tester la Map avec la touche F6

1. Dans l'Inspecteur de `Zone1`, assignez votre scène de Joueur et votre scène d'Ennemi.
2. Appuyez sur **`F6`** pour lancer la scène `Zone1.tscn`.
3. **Résultat :**
   * Le joueur se déplace dans votre arène dessinée à la main.
   * Il est physiquement bloqué par les murs et piliers que vous avez peints.
   * Les ennemis apparaissent aux spawners, et le portail s'ouvre à la fin du quota !
