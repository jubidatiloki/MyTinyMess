/// Ce qu'on range dans un emplacement : des livres, des bouteilles OU des
/// aliments, jamais un mélange.
enum TypeLieu {
  livres(
    'Bibliothèque',
    'livres',
    'livre',
    'Une pièce, une bibliothèque, une étagère…',
  ),
  cave('Cave', 'bouteilles', 'bouteille', 'Une cave, un casier, une armoire…'),
  frigo(
    'Frigo',
    'aliments',
    'aliment',
    'Le frigo, le congélateur, un placard…',
  );

  const TypeLieu(this.libelle, this.contenu, this.unite, this.exemples);

  /// « Bibliothèque » / « Cave ».
  final String libelle;

  /// « livres » / « bouteilles » / « aliments ».
  final String contenu;

  /// Au singulier : « livre », « bouteille », « aliment ».
  final String unite;

  /// Exemples d'emplacements de ce type.
  final String exemples;
}

/// Emplacement personnalisé où l'on range des livres ou des bouteilles :
/// une pièce, un meuble, une étagère, un casier, un carton…
/// Les lieux s'emboîtent : « Salon › Grande bibliothèque › Étagère 3 ».
/// Un sous-emplacement a toujours le même type que son parent.
class Lieu {
  const Lieu({
    required this.id,
    required this.nom,
    this.parentId,
    this.type = TypeLieu.livres,
  });

  final String id;
  final String nom;

  /// Lieu qui contient celui-ci (null = lieu de premier niveau).
  final String? parentId;
  final TypeLieu type;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'parentId': ?parentId,
    'type': type.name,
  };

  factory Lieu.fromJson(Map<String, dynamic> json) => Lieu(
    id: json['id'] as String,
    nom: json['nom'] as String? ?? '',
    parentId: json['parentId'] as String?,
    type: TypeLieu.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => TypeLieu.livres,
    ),
  );
}
