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
- `theme.dart` : `vertOdv` (#4A9D60, accents seulement), `PaletteOdv` (ThemeExtension, `PaletteOdv.de(context)` : menu, pastille de sélection, cartes, champs, séparateurs, vert doux des titres de section ; variantes `sombre` / `clair`) et `construireTheme` (barre de titre discrète couleur du fond, champs remplis sans contour, cartes arrondies sans ombre, bouton « + » large). **Sombre par défaut.** Design « moderne » validé le 12/11/2026 : fond #262827, menu #1E201F, cartes #303331.
- `widgets/page.dart` : `PageOdv` (titre + sous-titre alignés sur la colonne de contenu, largeur max `largeurContenu` = 760 px via `Centre`), `TitreSection`, `CarteGroupe` (réglages en carte), `CarteLigne` (ligne de liste en carte), `IconeCarree`, `BoutonAjout` (garde le libellé comme tooltip), `margesCentrees` (formulaires). Toute nouvelle page passe par `PageOdv`.
- `version.dart` : `kVersionApp`, toujours en phase avec `version:` de `pubspec.yaml` (affichée en bas du menu et dans « À propos »).
- `models/section.dart` : rubriques du menu (Vue d'ensemble, Ma bibliothèque, Ma cave, Mon bazar, Préférences, À propos). Mon bazar est encore une page « Bientôt disponible » (`screens/pages_simples.dart`). Le menu (`widgets/menu_lateral.dart`) est **fixé à gauche par défaut** si l'écran fait ≥ 720 px (`RacineScreen.largeurMenuFixe`) et que la préférence `menuFixe` est active ; sinon c'est un tiroir ouvert par ☰.
- **Emplacements personnalisés** : `models/lieu.dart` (`Lieu` : nom + `parentId`, emboîtables), `state/lieux_controller.dart` (`LieuxController` : `chemin` « Salon › Étagère 1 », `arbre`, `descendantsEtSoi`, suppression = le contenu remonte d'un niveau ; clés séparées `lieuxLivres` / `lieuxCave`), `widgets/lieux.dart` (`editerLieu`, `ChampLieu` avec bouton de création, `FiltreLieu`), `screens/lieux_screen.dart` (gestion, bouton « Emplacements » dans la barre des listes). Un lieu supprimé laisse les livres / bouteilles sans emplacement (référence ignorée).
- `screens/tableau_de_bord_screen.dart` : Vue d'ensemble, tuiles `TuileCompteur` (photo `assets/images/bibliotheque.jpg` / `cave.jpg`, dégradé + icône si absente).
- `state/preferences_controller.dart` + `screens/preferences_screen.dart` : thème (sombre / clair / comme l'appareil) et écran à l'ouverture, enregistrés sous la clé `preferences` du `Depot`.
- `models/` : `livre.dart` (`Livre` + `lieuId`, `StatutLecture`, `Possession` : chez moi / prêté / emprunté), `bouteille.dart` (`Bouteille`, `TypeVin`, `Emplacement` = `lieuId` + rangée + colonne ; `ancienneZone` = texte libre des versions ≤ 0.2, converti en lieu au démarrage par `CaveController.migrerZones`, `Mouvement` = historique des entrées/sorties).
- `data/depot.dart` : `Depot` (listes JSON par clé), `DepotPreferences` (shared_preferences), `DepotMemoire` (tests).
- `state/` : `CollectionController` (base : charger / enregistrer / supprimer, `normaliser` pour la recherche sans accents), `BibliothequeController` et `CaveController` (champ `lieux`, `emplacementDe`, `nombreDans`, filtre `lieuId` qui inclut les sous-emplacements ; cave : ajout / retrait de bouteilles, total).
- `screens/bibliotheque/`, `screens/cave/` : listes (recherche + filtres) et formulaires ; `widgets/communs.dart` (dates, champ de recherche, liste vide, confirmation).

## Pièges connus (tests widget)
- `ListView` paresseuse : `scrollUntilVisible` avant de remplir un champ hors écran.
- Navigation dans les tests : helper `ouvrir` (tape ☰ seulement s'il existe, puis `Key('menu-<section>')`). L'écran de test fait 800 px : le menu y est **fixé** ; `ecranTelephone(tester)` simule 400 px. Formulaires longs : `scrollUntilVisible` + `ensureVisible` avant de toucher une liste déroulante en bas.
- `FloatingActionButton` : garder `heroTag: null` (déjà fait dans `BoutonAjout`). Le sous-titre des listes (« 3 bouteilles ») est un texte séparé du titre.
- `find.text` doit être unique.

## Environnement (Windows)
- Flutter : `C:\Users\benja\Documents\flutter` (les scripts l'ajoutent au PATH si besoin).
- `lancer.bat` : lance l'appli (Chrome sur http://localhost:8081, Windows ou Android). Le port est fixe pour garder les données saisies dans le navigateur.
- `verifier.bat` : analyse + tests → `verification.log`.
- Aperçu dans le navigateur intégré de Claude : `flutter build web` puis `node outils/servir_web.js 8082` (http://localhost:8082). L'outil d'aperçu de l'app lit la config d'ODV : lancer le serveur en tâche de fond et ouvrir l'URL.
- L'appli Windows nécessite le « Mode développeur » de Windows (liens symboliques des plugins) : `start ms-settings:developers`.
