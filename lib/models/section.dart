/// Rubriques du menu latéral, dans l'ordre d'affichage.
enum Section {
  accueil('Vue d\'ensemble'),
  bibliotheque('Ma bibliothèque'),
  cave('Ma cave'),
  bazar('Mon bazar'),
  contact('Contact'),
  preferences('Préférences'),
  aPropos('À propos');

  const Section(this.libelle);
  final String libelle;

  /// Rubriques proposées comme écran d'ouverture de l'application.
  static const demarrages = [accueil, bibliotheque, cave];
}
