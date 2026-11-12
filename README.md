# My Tiny Mess

Gérer sa **bibliothèque** et sa **cave à vin**.

- **Bibliothèque** : titre, auteur, année, genre, ISBN, état de lecture (à lire / en cours / lu / liste de souhaits), note sur 5, notes libres, et où est le livre (chez moi, prêté à…, emprunté à…, avec la date).
- **Cave** : nom, type, producteur, appellation, région, millésime, « à boire avant », nombre de bouteilles avec boutons + / −, historique des entrées et sorties, et **emplacement exact** (lieu, rangée, colonne).
- **Emplacements personnalisés**, chacun soit pour les livres, soit pour la cave : pièces, meubles, étagères, casiers… rangés les uns dans les autres (« Salon › Grande bibliothèque › Étagère 3 »), gérés dans leur propre écran, avec filtre par emplacement. La vue d'ensemble montre chaque emplacement avec son nombre de livres ou de bouteilles.

Recherche sans accents et filtres dans les deux listes. Les données sont enregistrées dans une base de données locale, sur l'appareil (fichier sur téléphone et PC, IndexedDB dans le navigateur).

## Utilisation
- `lancer.bat` : lance l'application (navigateur, Windows ou téléphone Android).
- `verifier.bat` : vérifie le code et lance les tests (résultat dans `verification.log`).
