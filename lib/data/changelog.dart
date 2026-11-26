/// Historique des versions, affiché dans l'écran « Nouveautés ».
/// À chaque version : un nouveau bloc **en tête** (un test vérifie que le
/// premier bloc correspond à `kVersionApp`).
library;

enum TypeNouveaute {
  ajout('Ajout'),
  amelioration('Amélioration'),
  correction('Correction');

  const TypeNouveaute(this.libelle);
  final String libelle;
}

class Nouveaute {
  const Nouveaute(this.type, this.texte);

  final TypeNouveaute type;
  final String texte;
}

class VersionApp {
  const VersionApp(this.version, this.date, this.nouveautes);

  final String version;

  /// Date de sortie (jj/mm/aaaa).
  final String date;
  final List<Nouveaute> nouveautes;
}

const _a = TypeNouveaute.ajout;
const _m = TypeNouveaute.amelioration;
const _c = TypeNouveaute.correction;

/// La plus récente en premier.
const historiqueVersions = [
  VersionApp('0.16.0', '26/11/2026', [
    Nouveaute(_a, 'Écran « Nouveautés » : les évolutions de chaque version.'),
    Nouveaute(
      _a,
      'Frigo : curseur « reste environ … % » pour un aliment entamé '
      '(brique de jus, pot de confiture…), dans la fiche et en touchant '
      'la quantité.',
    ),
    Nouveaute(_a, 'Frigo : nouvelle catégorie d\'aliments « Fromages ».'),
    Nouveaute(_a, 'Annuaire : nouveau type d\'adresse « Application ».'),
    Nouveaute(
      _m,
      'Formulaires : s\'il n\'existe qu\'une catégorie ou qu\'un '
      'emplacement, il est choisi d\'office.',
    ),
  ]),
  VersionApp('0.15.0', '25/11/2026', [
    Nouveaute(
      _a,
      'Frigo : unité de quantité (tranche, paquet, conserve, morceau… ou la '
      'vôtre), avec le pluriel (« 3 tranches »).',
    ),
    Nouveaute(
      _a,
      'Frigo : toucher la quantité d\'un aliment permet de la saisir.',
    ),
    Nouveaute(
      _a,
      'Frigo : bouton pour afficher ou cacher les aliments épuisés, '
      'corbeille pour les supprimer définitivement.',
    ),
  ]),
  VersionApp('0.14.0', '24/11/2026', [
    Nouveaute(
      _a,
      'Annuaire : bouton « Partager » avec le menu de partage du téléphone.',
    ),
    Nouveaute(
      _a,
      'Annuaire : la personne qui reçoit le lien ajoute l\'adresse dans son '
      'application d\'un geste ; sans l\'application, une page web '
      'l\'affiche.',
    ),
  ]),
  VersionApp('0.13.0', '24/11/2026', [
    Nouveaute(
      _a,
      'Annuaire : vos bonnes adresses (personnes, commerçants, artisans, '
      'sites, festivals…) avec coordonnées, avis, favoris et étiquettes.',
    ),
    Nouveaute(
      _a,
      'Annuaire : appeler, écrire, ouvrir le site ou la carte d\'un toucher ; '
      '« Copier la fiche ».',
    ),
  ]),
  VersionApp('0.12.1', '24/11/2026', [
    Nouveaute(
      _c,
      'Listes : les textes longs s\'affichent en entier ; sur téléphone, les '
      'boutons passent sous le texte.',
    ),
    Nouveaute(_c, 'Titres et listes déroulantes : plus de texte coupé.'),
  ]),
  VersionApp('0.12.0', '23/11/2026', [
    Nouveaute(
      _a,
      'Vue d\'ensemble : emplacements regroupés par type et repliables.',
    ),
    Nouveaute(_a, 'Recettes : 30 nouvelles recettes, 64 au total.'),
    Nouveaute(
      _a,
      'Frigo : catégories d\'aliments à définir dans les préférences, filtre '
      'par catégorie.',
    ),
    Nouveaute(_a, 'Agenda : vue calendrier du mois.'),
    Nouveaute(_c, 'Calculs de dates aux changements d\'heure.'),
  ]),
  VersionApp('0.11.0', '21/11/2026', [
    Nouveaute(
      _a,
      'Repas & recettes : idées de repas selon le frigo, carnet de recettes, '
      'vos recettes et recherche en ligne.',
    ),
    Nouveaute(_a, 'Agenda : événements et repas du midi et du soir.'),
    Nouveaute(
      _a,
      'Liste de courses : depuis le frigo ou une recette ; les achats se '
      'rangent dans le frigo en un geste.',
    ),
    Nouveaute(_a, 'Vue d\'ensemble : carte « Aujourd\'hui ».'),
  ]),
  VersionApp('0.10.0', '21/11/2026', [
    Nouveaute(
      _a,
      'Bibliothèque : ajouter un livre en scannant son code-barres ISBN '
      '(titre, auteur et année retrouvés en ligne).',
    ),
    Nouveaute(
      _a,
      'Bibliothèque : signale un ISBN mal recopié, un livre introuvable et un '
      'livre déjà présent.',
    ),
  ]),
  VersionApp('0.9.0', '18/11/2026', [
    Nouveaute(_a, 'Nouvelle icône « l\'étagère ».'),
  ]),
  VersionApp('0.8.0', '18/11/2026', [
    Nouveaute(
      _a,
      'Frigo : aliments avec quantité, date de péremption (alerte à 3 jours) '
      'et emplacement.',
    ),
    Nouveaute(_a, 'Cave : types de bouteille paramétrables (bière, cidre…).'),
    Nouveaute(_m, 'Grand bouton « Enregistrer » en bas des formulaires.'),
    Nouveaute(
      _m,
      'Le bouton précédent ramène à la vue d\'ensemble au lieu de quitter.',
    ),
  ]),
  VersionApp('0.7.1', '13/11/2026', [
    Nouveaute(_a, 'Première livraison : APK Android et version web.'),
    Nouveaute(
      _c,
      'L\'application s\'appelle « My Tiny Mess » sur Android et dans le '
      'navigateur.',
    ),
  ]),
  VersionApp('0.7.0', '13/11/2026', [
    Nouveaute(
      _m,
      'Emplacements : chacun est soit pour les livres, soit pour la cave.',
    ),
  ]),
  VersionApp('0.6.0', '12/11/2026', [
    Nouveaute(_a, 'Écran des emplacements, résumé sur la vue d\'ensemble.'),
    Nouveaute(_a, 'Bibliothèque : liste de souhaits.'),
  ]),
  VersionApp('0.5.0', '12/11/2026', [
    Nouveaute(_a, 'Les données sont gardées dans une base locale.'),
  ]),
  VersionApp('0.4.0', '12/11/2026', [
    Nouveaute(
      _a,
      'Emplacements personnalisés, rangés les uns dans les autres.',
    ),
    Nouveaute(_m, 'Menu latéral fixe et design modernisé.'),
  ]),
  VersionApp('0.2.0', '12/11/2026', [
    Nouveaute(
      _a,
      'Bibliothèque et cave, menu latéral, vue d\'ensemble et préférences.',
    ),
  ]),
];
