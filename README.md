# My Tiny Mess

Gérer sa **bibliothèque**, sa **cave**, son **frigo**, ses **repas**, son **agenda**, sa **liste de courses** et son **annuaire** de bonnes adresses.

- **Bibliothèque** : ajout par **scan du code-barres ISBN** (téléphone, navigateur) ou saisie de l'ISBN, avec titre, auteur et année retrouvés en ligne ; titre, auteur, année, genre, ISBN, état de lecture (à lire / en cours / lu / liste de souhaits), note sur 5, notes libres, et où est le livre (chez moi, prêté à…, emprunté à…, avec la date).
- **Cave** : nom, type (liste paramétrable : rouge, blanc, bière…), producteur, appellation, région, millésime, « à boire avant », nombre de bouteilles avec boutons + / −, historique des entrées et sorties, et **emplacement exact** (lieu, rangée, colonne).
- **Frigo** : aliments avec quantité et unité (4 tranches, 2 conserves…) modifiables depuis la liste, contenance, date de péremption (en orange quand il faut les consommer dans les 3 jours, en rouge une fois périmés) et emplacement (frigo, congélateur, placard…). Catégories d'aliments à définir dans les préférences, avec filtre. Les aliments épuisés peuvent être cachés ou supprimés ; un curseur indique ce qu'il reste d'un aliment entamé (« reste environ 50 % »). Variante d'un aliment (« pommes de terre · grenailles ») et icône selon la catégorie.
- **Nouveautés** : les évolutions de chaque version, dans le menu.
- **Repas & recettes** : propositions selon le contenu du frigo, par style (gourmand, light, rapide, végétarien, économique), avec les ingrédients manquants ; apéritifs et boissons ; carnet de 72 recettes avec conseils, vos propres recettes, et recherche de recettes en ligne (en anglais).
- **Agenda** : vue semaine ou calendrier du mois, avec événements (rendez-vous, invités…) et repas du midi et du soir ; les ingrédients manquants de la semaine partent dans la liste de courses.
- **Liste de courses** : articles ajoutés à la main, depuis le frigo ou depuis une recette ; une fois achetés, ils se rangent dans le frigo en un geste.
- **Annuaire** : vos bonnes adresses (personnes, commerçants, artisans, sites, festivals…) avec coordonnées, avis, qui les a recommandées, favoris et étiquettes pour les regrouper ; un geste pour appeler, écrire, ouvrir le site ou la carte, et « Partager » : la personne qui reçoit le lien ajoute l'adresse dans son application.
- **Emplacements personnalisés**, chacun pour les livres, la cave ou le frigo : pièces, meubles, étagères, casiers… rangés les uns dans les autres (« Salon › Grande bibliothèque › Étagère 3 »), gérés dans leur propre écran, avec filtre par emplacement. La vue d'ensemble montre chaque emplacement avec son nombre de livres, de bouteilles ou d'aliments, permet de les regrouper (replier) par type ou par meuble, et signale les aliments à consommer vite.

Recherche sans accents et filtres dans les listes. Les données sont enregistrées dans une base de données locale, sur l'appareil (fichier sur téléphone et PC, IndexedDB dans le navigateur).

## Utilisation
- `lancer.bat` : ouvre directement l'application dans le navigateur (Chrome). Pour les autres versions : `lancer.bat windows` ou `lancer.bat android`.
- `verifier.bat` : vérifie le code et lance les tests (résultat dans `verification.log`).
- `livrer.bat` : construit l'APK Android et la version web autonome dans le dossier `livraison`.

## Installer sans Flutter
Téléchargez la dernière version dans les [releases GitHub](https://github.com/jubidatiloki/MyTinyMess/releases) :
- **Android** : le fichier `.apk` (autoriser l'installation depuis cette source si le téléphone le demande).
- **Ordinateur** (Windows, Mac, Linux) : le fichier `my_tiny_mess_web_….zip`, à décompresser, puis `Ouvrir My Tiny Mess.bat` (Windows) ou `sh ouvrir.sh` (Mac / Linux).
