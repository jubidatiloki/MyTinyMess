/// Unités proposées pour les quantités d'aliments (au singulier). D'autres
/// peuvent être saisies librement.
const unitesProposees = [
  'bocal',
  'boîte',
  'bouteille',
  'brique',
  'conserve',
  'filet',
  'morceau',
  'paquet',
  'part',
  'pièce',
  'plaque',
  'pot',
  'sachet',
  'tranche',
];

/// Mesures, qui ne prennent jamais de « s ».
const _mesures = {'g', 'kg', 'mg', 'l', 'cl', 'dl', 'ml'};

/// « tranche » → « tranches » s'il y en a plusieurs. Seul le premier mot
/// s'accorde (« pots de yaourt »).
String accorderUnite(String unite, int n) {
  if (n < 2) {
    return unite;
  }
  final i = unite.indexOf(' ');
  final mot = i < 0 ? unite : unite.substring(0, i);
  final suite = i < 0 ? '' : unite.substring(i);
  final m = mot.toLowerCase();
  final String pluriel;
  if (_mesures.contains(m) || RegExp(r'[sxz.]$').hasMatch(m)) {
    pluriel = mot;
  } else if (m.endsWith('eau')) {
    pluriel = '${mot}x';
  } else if (m == 'bocal') {
    pluriel = '${mot.substring(0, mot.length - 2)}aux';
  } else {
    pluriel = '${mot}s';
  }
  return '$pluriel$suite';
}

/// Unité saisie → singulier si c'est le pluriel d'une unité proposée
/// (« Tranches » → « tranche »), sinon telle quelle ; null si vide.
String? lireUnite(String texte) {
  final t = texte.trim();
  if (t.isEmpty) {
    return null;
  }
  for (final u in unitesProposees) {
    if (t.toLowerCase() == u || t.toLowerCase() == accorderUnite(u, 2)) {
      return u;
    }
  }
  return t;
}
