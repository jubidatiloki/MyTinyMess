# My Tiny Mess

Gérer sa **bibliothèque**, sa **cave** et son **frigo**.

- **Bibliothèque** : ajout par **scan du code-barres ISBN** (téléphone, navigateur) ou saisie de l'ISBN, avec titre, auteur et année retrouvés en ligne ; titre, auteur, année, genre, ISBN, état de lecture (à lire / en cours / lu / liste de souhaits), note sur 5, notes libres, et où est le livre (chez moi, prêté à…, emprunté à…, avec la date).
- **Cave** : nom, type (liste paramétrable : rouge, blanc, bière…), producteur, appellation, région, millésime, « à boire avant », nombre de bouteilles avec boutons + / −, historique des entrées et sorties, et **emplacement exact** (lieu, rangée, colonne).
- **Frigo** : aliments avec quantité, contenance, date de péremption (en orange quand il faut les consommer dans les 3 jours, en rouge une fois périmés) et emplacement (frigo, congélateur, placard…).
- **Emplacements personnalisés**, chacun pour les livres, la cave ou le frigo : pièces, meubles, étagères, casiers… rangés les uns dans les autres (« Salon › Grande bibliothèque › Étagère 3 »), gérés dans leur propre écran, avec filtre par emplacement. La vue d'ensemble montre chaque emplacement avec son nombre de livres, de bouteilles ou d'aliments, et signale les aliments à consommer vite.

Recherche sans accents et filtres dans les listes. Les données sont enregistrées dans une base de données locale, sur l'appareil (fichier sur téléphone et PC, IndexedDB dans le navigateur).

## Utilisation
- `lancer.bat` : ouvre directement l'application dans le navigateur (Chrome). Pour les autres versions : `lancer.bat windows` ou `lancer.bat android`.
- `verifier.bat` : vérifie le code et lance les tests (résultat dans `verification.log`).
- `livrer.bat` : construit l'APK Android et la version web autonome dans le dossier `livraison`.

## Installer sans Flutter
Téléchargez la dernière version dans les [releases GitHub](https://github.com/jubidatiloki/MyTinyMess/releases) :
- **Android** : le fichier `.apk` (autoriser l'installation depuis cette source si le téléphone le demande).
- **Ordinateur** (Windows, Mac, Linux) : le fichier `my_tiny_mess_web_….zip`, à décompresser, puis `Ouvrir My Tiny Mess.bat` (Windows) ou `sh ouvrir.sh` (Mac / Linux).
