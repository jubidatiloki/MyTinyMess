/// Ce qu'on range dans un emplacement : des livres OU des bouteilles,
/// jamais les deux.
enum TypeLieu {
  livres('Bibliothèque', 'livres'),
  cave('Cave', 'bouteilles');

  const TypeLieu(this.libelle, this.contenu);

  /// « Bibliothèque » / « Cave ».
  final String libelle;

  /// « livres » / « bouteilles ».
  final String contenu;
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
