/// Rubriques du menu latéral, dans l'ordre d'affichage.
enum Section {
  accueil('Vue d\'ensemble'),
  bibliotheque('Ma bibliothèque'),
  cave('Ma cave'),
  frigo('Mon frigo'),
  recettes('Repas & recettes'),
  courses('Liste de courses'),
  agenda('Agenda'),
  emplacements('Emplacements'),
  bazar('Mon bazar'),
  preferences('Préférences'),
  aPropos('À propos');

  const Section(this.libelle);
  final String libelle;

  /// Rubriques proposées comme écran d'ouverture de l'application.
  static const demarrages = [accueil, bibliotheque, cave, frigo, agenda];

  /// Rubriques « collections » (le reste est séparé par un trait).
  static const collections = [
    accueil,
    bibliotheque,
    cave,
    frigo,
    recettes,
    courses,
    agenda,
    emplacements,
    bazar,
  ];
}
