# 🎯 OBJECTIFS : DÉTECTION D'ENTRÉE DES SALLES DIRECTION-AGNOSTIQUE (AREA2D & SIGNAUX)

---

## 📌 1. Contexte & Justification de la Mise à Jour

### ❓ Quelle est la problématique actuelle ?
Dans le code actuel de [`Room.gd`](file:///c:/game/bullet-drop/scripts/levels/Room.gd) :
1. **Sondage constant chaque frame (Polling CPU dans `_process`) :**
   Toutes les salles non encore activées exécutent la méthode `_check_player_entry()` 60 à 144 fois par seconde pour vérifier manuellement si le joueur s'approche de la porte.
2. **Coordonnées codées en dur sur l'axe X :**
   La détection est basée sur la formule `player.global_position.x < entry_door.global_position.x + 80.0`.
3. **Poussée de sécurité (Nudge Tween) bloquée sur l'axe X :**
   Lors du verrouillage de la porte, le joueur est poussé vers la droite avec `tween_property(player, "global_position:x", entry_door.global_position.x + 140.0, 0.25)`.

### 💥 Pourquoi est-ce une problématique majeure d'architecture ?
* **Incompatibilité multi-directionnelle :** Si tu conçois une salle verticale (progression vers le haut ou le bas) ou une salle vers la gauche (-X), la condition `x < seuil` échouera systématiquement : soit la salle se déclenchera prématurément, soit elle ne se déclenchera jamais (bloquant le joueur indéfiniment). De plus, le *nudge* poussera le joueur sur le côté contre un mur au lieu de le faire avancer dans la salle.
* **Anti-pattern en Game Development :** Sonder manuellement des coordonnées dans `_process` est l'équivalent web de faire un `setInterval(16ms)` ou d'écouter `window.onscroll` pour calculer manuellement la position d'un élément au lieu d'utiliser un `IntersectionObserver`.
* **Couplage fort et duplication :** `Door.tscn` possède déjà un nœud `LockTrigger` (`Area2D`), mais celui-ci était laissé vide (`pass`), pendant que `Room.gd` recalculait des distances avec des *magic numbers* (`80.0`, `120.0`, `140.0`).

### 💡 Comment la résoudre proprement selon les standards Godot ?
* **Architecture événementielle (Signal-driven) :**
  1. `Door.gd` gère sa propre zone de détection `LockTrigger` (`Area2D`) et émet un signal typé `player_entered(door: RoomDoor, player: Node2D)` dès que le joueur franchit le seuil.
  2. `Door.gd` expose son vecteur d'orientation normé `get_forward_direction() -> Vector2` (Droite, Gauche, Bas, Haut).
  3. `Room.gd` écoute ce signal à l'initialisation (`_ready()`). Dès que le signal est reçu, la salle s'active instantanément.
  4. La poussée de sécurité (nudge) utilise le vecteur de direction de la porte : `player.global_position + (push_dir * 80.0)`, garantissant un fonctionnement parfait dans n'importe quel angle ou direction de donjon.
  5. Suppression totale du polling dans `_process()` et suppression du code mort `_check_player_entry()`.

---

## 🌿 Nom de la Branche Git
```bash
git checkout -b refactor/room-entry-area2d
```

---

## ⚠️ Avertissement d'Interdépendance des Étapes
> [!IMPORTANT]
> **Les étapes 1 et 2 sont strictement liées.**
> L'étape 1 ajoute les signaux et méthodes directionnelles dans `Door.gd`, et l'étape 2 connecte ces signaux et supprime le polling dans `Room.gd`.
> Tu dois réaliser l'étape 1 puis l'étape 2 à la suite avant de tester le jeu dans Godot, afin de maintenir la cohérence de compilation de ton projet.

---

## 📋 Tâches Détaillées par Étape & Commit

---

### 🚪 ÉTAPE 1 : Refonte de la Porte (`scripts/levels/Door.gd`)

* **Fichier ciblé :** [`scripts/levels/Door.gd`](file:///c:/game/bullet-drop/scripts/levels/Door.gd)
* **Titre du commit :** `feat(door): add direction-agnostic player entry detection with Area2D and signals`
* **Explication du commit :**
  Ajout du signal de franchissement `player_entered`, gestion de l'énumération de direction (`RIGHT`, `LEFT`, `DOWN`, `UP`), calcul dynamique de la position du trigger de collision `Area2D`, et émission de l'événement lors de l'entrée du joueur.

#### 🛠️ Tâches logiques à réaliser pas-à-pas dans `Door.gd` :

1. **Déclarer l'énumération de direction et le signal :**
   * En haut du script, définir un `enum Direction { RIGHT, LEFT, DOWN, UP }`.
   * Déclarer le signal typé : `signal player_entered(door: RoomDoor, player: Node2D)`.
   * *Pourquoi :* L'énumération permet de sélectionner la direction de passage dans l'Inspecteur Godot. Le signal découple la porte de la salle : la porte informe le monde extérieur sans savoir qui l'écoute.

2. **Ajouter les propriétés exportées de configuration :**
   * `@export var entry_direction: Direction = Direction.RIGHT` (par défaut vers la droite pour la Zone 1).
   * `@export var trigger_distance: float = 50.0` (distance en pixels à laquelle la zone de détection est décalée vers l'intérieur de la salle suivante).

3. **Créer la méthode d'obtention du vecteur unitaire :**
   * Définir une fonction `func get_forward_direction() -> Vector2`.
   * Utiliser une structure `match entry_direction` qui retourne respectivement `Vector2.RIGHT`, `Vector2.LEFT`, `Vector2.DOWN` ou `Vector2.UP`.
   * *Pourquoi :* Fournir un vecteur mathématique normé permet à la salle de calculer des déplacements ou des décalages relatifs sans jamais avoir à coder un axe en dur (`x` ou `y`).

4. **Adapter la méthode `_update_size()` pour positionner le Trigger :**
   * Lors du calcul des dimensions des rectangles de collision, récupérer le nœud `TriggerShape` (CollisionShape2D de `LockTrigger`).
   * Définir sa forme rectangulaire adaptée à l'orientation (`horizontal` ou `vertical`).
   * Positionner la forme avec : `trigger_col.position = get_forward_direction() * trigger_distance`.
   * *Pourquoi :* La zone de détection se place automatiquement du côté intérieur de la salle de destination, quel que soit le sens de franchissement.

5. **Compléter la méthode événementielle `_on_trigger_body_entered(body: Node2D)` :**
   * Vérifier que le corps `body` est valide et qu'il appartient au groupe `"player"` (ou `body.name == "Player"`).
   * Vérifier que la porte n'est pas déjà verrouillée définitivement (`is_permanent_lock`).
   * Émettre le signal : `player_entered.emit(self, body)`.
   * *Pourquoi :* C'est le déclencheur passif géré par le moteur physique qui remplace la boucle de surveillance active.

---

### 🏰 ÉTAPE 2 : Refonte de la Salle (`scripts/levels/Room.gd`)

* **Fichier ciblé :** [`scripts/levels/Room.gd`](file:///c:/game/bullet-drop/scripts/levels/Room.gd)
* **Titre du commit :** `refactor(room): switch room activation to signal-driven event flow with vector nudge`
* **Explication du commit :**
  Suppression du polling dans `_process()`, connexion au signal `player_entered` de la porte d'entrée dans `_ready()`, et remplacement du Tween de sécurité X par une poussée vectorielle direction-agnostique.

#### 🛠️ Tâches logiques à réaliser pas-à-pas dans `Room.gd` :

1. **Connecter le signal de la porte d'entrée dans `_ready()` :**
   * Dans `_ready()`, ajouter la condition : si `entry_door` existe, connecter son signal `entry_door.player_entered` à une méthode callback locale (par exemple `_on_entry_door_player_entered`).
   * *Pourquoi :* La salle s'abonne aux événements de sa propre porte d'entrée dès son initialisation.

2. **Créer la méthode de rappel `_on_entry_door_player_entered` :**
   * Déclarer `func _on_entry_door_player_entered(_door: RoomDoor, _player: Node2D) -> void`.
   * Vérifier si la salle n'est pas déjà active, terminée ou en cours de séquence de démarrage (`is_active`, `is_cleared`, `is_starting_sequence`).
   * Si les conditions sont réunies, appeler `activate_room()`.

3. **Nettoyer `_process(delta: float)` :**
   * Supprimer le bloc conditionnel au début de `_process` qui appelait `_check_player_entry()` à chaque frame pour `room_index > 1`.
   * Conserver uniquement la logique du mode progressif (`SpawnMode.PROGRESSIVE`).
   * *Pourquoi :* Élimine 100% de la charge CPU de surveillance active.

4. **Supprimer la fonction obsolète `_check_player_entry()` :**
   * Supprimer complètement la méthode `_check_player_entry()` qui contenait la condition rigide `player.global_position.x < entry_door.global_position.x + 80.0`.
   * *Pourquoi :* Cette méthode devient du code mort inutile.

5. **Adapter `_on_bounds_body_entered(body: Node2D)` :**
   * Modifier la condition pour que l'activation par la zone de délimitation (`Bounds`) ne se déclenche que si la salle **n'a pas** de porte d'entrée (`and not entry_door`), comme pour la Salle 1 (Zone de départ).

6. **Rendre la poussée de sécurité (nudge) vectorielle dans `activate_room()` :**
   * Dans `activate_room()`, repérer la section où le joueur reçoit un *Tween* de repositionnement.
   * Remplacer le calcul sur l'axe X fixe par :
     - Récupérer la direction de la porte : `var push_dir: Vector2 = entry_door.get_forward_direction()`.
     - Calculer la cible : `var target_pos: Vector2 = player.global_position + (push_dir * 80.0)`.
     - Animer la propriété globale : `pt.tween_property(player, "global_position", target_pos, 0.25)`.
   * *Pourquoi :* Le joueur sera désormais poussé vers l'avant dans la salle quelle que soit la direction (Droite, Gauche, Haut, Bas) sans risque d'être écrasé par la fermeture de la porte.

---

## 🧪 3. Protocole de Test & Validation

1. **Test en jeu standard (F5) :**
   - Vaincre les ennemis de la Salle 1.
   - Constater l'ouverture de la porte vers la Salle 2.
   - Franchir la porte : vérifier que le passage déclenche immédiatement la fermeture animée de la porte, le léger décalage du joueur vers l'intérieur, la dissipation du brouillard et l'apparition des ennemis de la Salle 2.
2. **Visualisation des formes de collision (Debug) :**
   - Dans Godot, aller dans `Déboguer` -> `Formes de collision visibles`.
   - Lancer le jeu et observer la boîte bleue de déclenchement (`LockTrigger`) positionnée juste après la porte dans la salle suivante.
3. **Contrôle console / débogueur :**
   - S'assurer de n'avoir aucun avertissement ni erreur dans l'onglet `Débogueur` de Godot.

---

## 📦 4. Clôture de l'Objectif
Une fois les étapes 1 et 2 implémentées, testées et validées :
- Déplacer ce fichier dans `archives-objectifs/objectifs-detection-entree-salles.md`.
