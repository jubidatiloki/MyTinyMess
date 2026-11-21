/// Outils pour les numéros ISBN (10 ou 13 chiffres, au dos des livres).
library;

/// Garde les chiffres (et un X final pour l'ISBN-10), sans tirets ni
/// espaces. Renvoie null si ce n'est pas un ISBN valide (clé de contrôle).
String? normaliserIsbn(String texte) {
  final brut = texte.toUpperCase().replaceAll(RegExp(r'[^0-9X]'), '');
  if (brut.length == 13 && RegExp(r'^\d{13}$').hasMatch(brut)) {
    return _cle13Valide(brut) ? brut : null;
  }
  if (brut.length == 10 && RegExp(r'^\d{9}[\dX]$').hasMatch(brut)) {
    return _cle10Valide(brut) ? brut : null;
  }
  return null;
}

/// Un code-barres EAN-13 de livre commence par 978 ou 979.
bool estCodeBarresLivre(String code) {
  final isbn = normaliserIsbn(code);
  return isbn != null &&
      isbn.length == 13 &&
      (isbn.startsWith('978') || isbn.startsWith('979'));
}

/// ISBN-10 → ISBN-13 (préfixe 978) ; un ISBN-13 est renvoyé tel quel.
String versIsbn13(String isbn) {
  if (isbn.length == 13) {
    return isbn;
  }
  final base = '978${isbn.substring(0, 9)}';
  var somme = 0;
  for (var i = 0; i < 12; i++) {
    somme += int.parse(base[i]) * (i.isEven ? 1 : 3);
  }
  return '$base${(10 - somme % 10) % 10}';
}

bool _cle13Valide(String isbn) {
  var somme = 0;
  for (var i = 0; i < 13; i++) {
    somme += int.parse(isbn[i]) * (i.isEven ? 1 : 3);
  }
  return somme % 10 == 0;
}

bool _cle10Valide(String isbn) {
  var somme = 0;
  for (var i = 0; i < 10; i++) {
    final c = isbn[i];
    final valeur = c == 'X' ? 10 : int.parse(c);
    somme += valeur * (10 - i);
  }
  return somme % 11 == 0;
}
