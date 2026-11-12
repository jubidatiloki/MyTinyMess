# My Tiny Mess — instructions pour Claude

Application Flutter (Android + web + Windows) pour gérer **sa bibliothèque** (livres, notes, lecture, prêts / emprunts) et **sa cave à vin** (bouteilles, entrées / sorties, emplacement exact). Utilisateur francophone, non développeur : **toujours répondre en français**, simplement, sans jargon inutile.

## Règles de travail
- Après chaque changement : `flutter analyze` puis `flutter test` (sans erreur, tous verts). Un hook Claude Code (`.claude/settings.json` → `outils/verifier_hook.sh`) les relance automatiquement à la fin de chaque tour si du code Dart a changé, et bloque en cas d'échec.
- Ajouter ou adapter un test pour chaque fonctionnalité (modèles dans `test/models_test.dart`, logique dans `test/controllers_test.dart`, écrans dans `test/ecrans_test.dart`).
- Formater seulement les fichiers modifiés (`dart format <fichiers>`).
- Code, noms et textes de l'interface en français.
- Git : un garde-fou (`outils/pre-commit`, activé par `git config core.hooksPath outils`) refuse un commit si l'analyse ou les tests échouent. Committer seulement quand l'utilisateur le demande.

## Architecture (`lib/`)
- `main.dart` (stockage sur l'appareil, préférences chargées avant l'affichage) → `app.dart` (`MyTinyMessApp`, thème selon les préférences, français) → `screens/racine_screen.dart` (affiche la rubrique choisie dans le menu latéral `widgets/menu_lateral.dart`).
- `theme.dart` : palette `Couleurs` (vert `#4A9D60` des barres et du menu, fond `#454545` en sombre, `#F2F2F2` en clair) et `construireTheme`. **Sombre par défaut.**
- `version.dart` : `kVersionApp`, toujours en phase avec `version:` de `pubspec.yaml` (affichée en bas du menu et dans « À propos »).
- `models/section.dart` : rubriques du menu (Vue d'ensemble, Ma bibliothèque, Ma cave, Mon bazar, Contact, Préférences, À propos). Mon bazar et Contact sont encore des pages « Bientôt disponible » (`screens/pages_simples.dart`).
- `screens/tableau_de_bord_screen.dart` : Vue d'ensemble, tuiles `TuileCompteur` (photo `assets/images/bibliotheque.jpg` / `cave.jpg`, dégradé + icône si absente).
- `state/preferences_controller.dart` + `screens/preferences_screen.dart` : thème (sombre / clair / comme l'appareil) et écran à l'ouverture, enregistrés sous la clé `preferences` du `Depot`.
- `models/` : `livre.dart` (`Livre`, `StatutLecture`, `Possession` : chez moi / prêté / emprunté), `bouteille.dart` (`Bouteille`, `TypeVin`, `Emplacement` zone + rangée + colonne, `Mouvement` = historique des entrées/sorties).
- `data/depot.dart` : `Depot` (listes JSON par clé), `DepotPreferences` (shared_preferences), `DepotMemoire` (tests).
- `state/` : `CollectionController` (base : charger / enregistrer / supprimer, `normaliser` pour la recherche sans accents), `BibliothequeController` (+ `FiltreLivres`), `CaveController` (ajout / retrait de bouteilles, total).
- `screens/bibliotheque/`, `screens/cave/` : listes (recherche + filtres) et formulaires ; `widgets/communs.dart` (dates, champ de recherche, liste vide, confirmation).

## Pièges connus (tests widget)
- `ListView` paresseuse : `scrollUntilVisible` avant de remplir un champ hors écran.
- Navigation dans les tests : `find.byIcon(Icons.menu)` puis `find.byKey(Key('menu-<section>'))` (le libellé du menu peut aussi être le titre de l'écran).
- `FloatingActionButton` : garder `heroTag: null`.
- `find.text` doit être unique.

## Environnement (Windows)
- Flutter : `C:\Users\benja\Documents\flutter` (les scripts l'ajoutent au PATH si besoin).
- `lancer.bat` : lance l'appli (Chrome sur http://localhost:8081, Windows ou Android). Le port est fixe pour garder les données saisies dans le navigateur.
- `verifier.bat` : analyse + tests → `verification.log`.
- Aperçu dans le navigateur intégré de Claude : `flutter build web` puis `node outils/servir_web.js 8082` (http://localhost:8082). L'outil d'aperçu de l'app lit la config d'ODV : lancer le serveur en tâche de fond et ouvrir l'URL.
- L'appli Windows nécessite le « Mode développeur » de Windows (liens symboliques des plugins) : `start ms-settings:developers`.
