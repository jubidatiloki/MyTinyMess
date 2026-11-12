/// Rubriques du menu latéral, dans l'ordre d'affichage.
enum Section {
  accueil('Vue d\'ensemble'),
  bibliotheque('Ma bibliothèque'),
  cave('Ma cave'),
  emplacements('Emplacements'),
  bazar('Mon bazar'),
  preferences('Préférences'),
  aPropos('À propos');

  const Section(this.libelle);
  final String libelle;

  /// Rubriques proposées comme écran d'ouverture de l'application.
  static const demarrages = [accueil, bibliotheque, cave];

  /// Rubriques « collections » (le reste est séparé par un trait).
  static const collections = [accueil, bibliotheque, cave, emplacements, bazar];
}
