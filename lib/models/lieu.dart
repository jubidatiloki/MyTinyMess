/// Emplacement personnalisé où l'on range des livres ou des bouteilles :
/// une pièce, un meuble, une étagère, un casier, un carton…
/// Les lieux s'emboîtent : « Salon › Grande bibliothèque › Étagère 3 ».
class Lieu {
  const Lieu({required this.id, required this.nom, this.parentId});

  final String id;
  final String nom;

  /// Lieu qui contient celui-ci (null = lieu de premier niveau).
  final String? parentId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    if (parentId != null) 'parentId': parentId,
  };

  factory Lieu.fromJson(Map<String, dynamic> json) => Lieu(
    id: json['id'] as String,
    nom: json['nom'] as String? ?? '',
    parentId: json['parentId'] as String?,
  );
}
