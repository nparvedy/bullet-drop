# 📚 JOURNAL D'APPRENTISSAGE — CONCEPTS & NOTIONS GODOT ACQUIS

> Ce document sert de mémoire continue à l'assistant IA et au développeur.
> **Règle :** Ce fichier est lu avant chaque explication pour ajuster le niveau de détail.
> - Si un concept est listé ici : l'assistant fait un rappel rapide sans réexpliquer les bases.
> - Si un concept n'y figure pas : explication complète "de A à Z" avec pédagogie pas-à-pas et analogies dev web.

---

## 🗂️ Liste Chronologique des Notions Enseignées

| Date | Concept / Notion | Domaine | Résumé Clé & Analogie Web |
| :--- | :--- | :--- | :--- |
| **2026-09-13** | **SceneTree & Nœuds (Nodes)** | Architecture Godot | Un jeu Godot est un arbre hiérarchique de nœuds (analogie avec le DOM HTML). Chaque scène (`.tscn`) est un composant réutilisable (comme un composant React/Vue). |
| **2026-09-13** | **`_process(delta)` vs `_physics_process(delta)`** | Cycle de vie / Loop | `_process` tourne à chaque image affichée (variable selon les FPS, idéal pour le visuel/UI/visée). `_physics_process` tourne à cadence fixe (ex: 60Hz, idéal pour les déplacements, collisions et calculs physiques). |
| **2026-09-13** | **Signal Up, Call Down** | Communication & POO | Règle d'or de découplage : un nœud parent appelle directement les méthodes de ses enfants (`Call Down`), mais un enfant communique avec son parent ou l'extérieur via des **Signaux / Events** (`Signal Up`), sans jamais faire de `get_parent().get_parent()`. |
| **2026-09-13** | **Collision Layers vs Collision Masks** | Physique 2D | Le *Layer* est "qui je suis" (mon calque d'appartenance). Le *Mask* est "ce avec quoi je veux entrer en collision / ce que je regarde". Indispensable pour éviter les collisions parasites (ex: balle qui touche son propre tireur). |
| **2026-09-13** | **Autoloads (Singletons)** | Architecture Globale | Scripts ou scènes chargés automatiquement à la racine de la scène (`/root/`). Analogie : Stores globaux (Pinia/Redux) ou services partagés. Doit être réservé à l'EventBus global et aux données persistantes (SaveManager). |

---

## 📝 Notes & Vocabulaire Technique Clé

* **`delta` :** Temps écoulé en secondes depuis la dernière frame. Multiplier une vitesse par `delta` rend le déplacement indépendant du nombre de FPS (analogie : `requestAnimationFrame(timestamp)`).
* **`PackedScene` :** Patron/Template de scène préchargé en mémoire (`.instantiate()` = instanciation d'un nouvel objet dans le monde).
* **`queue_free()` :** Destruction propre et asynchrone d'un nœud à la fin de la frame courante (analogie : `unmountComponent()`).
