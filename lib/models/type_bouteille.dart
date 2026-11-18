import 'package:flutter/painting.dart';

/// Type de bouteille, paramétrable par l'utilisateur (rouge, blanc, bière,
/// spiritueux…). Les bouteilles y font référence par [id].
class TypeBouteille {
  const TypeBouteille({
    required this.id,
    required this.nom,
    this.couleur = 0xFF9E9E9E,
  });

  final String id;
  final String nom;

  /// Couleur de l'icône (ARGB), choisie dans [palette].
  final int couleur;

  Color get color => Color(couleur);

  /// Couleurs proposées pour un type.
  static const palette = [
    0xFF7B1E3A, // bordeaux
    0xFFE3C565, // or
    0xFFF2A0A8, // rose
    0xFFD9CF9A, // paille
    0xFFC98A2B, // ambre
    0xFF8D5524, // brun
    0xFF4A9D60, // vert
    0xFF4A7FC1, // bleu
    0xFF8E6BBF, // violet
    0xFF9E9E9E, // gris
  ];

  /// Types créés au premier lancement. Les identifiants sont ceux des
  /// versions ≤ 0.7 (où le type était fixe) : les bouteilles déjà saisies
  /// retrouvent leur type.
  static const parDefaut = [
    TypeBouteille(id: 'rouge', nom: 'Rouge', couleur: 0xFF7B1E3A),
    TypeBouteille(id: 'blanc', nom: 'Blanc', couleur: 0xFFE3C565),
    TypeBouteille(id: 'rose', nom: 'Rosé', couleur: 0xFFF2A0A8),
    TypeBouteille(id: 'effervescent', nom: 'Effervescent', couleur: 0xFFD9CF9A),
    TypeBouteille(id: 'liquoreux', nom: 'Liquoreux', couleur: 0xFFC98A2B),
    TypeBouteille(id: 'autre', nom: 'Autre', couleur: 0xFF9E9E9E),
  ];

  Map<String, dynamic> toJson() => {'id': id, 'nom': nom, 'couleur': couleur};

  factory TypeBouteille.fromJson(Map<String, dynamic> json) => TypeBouteille(
    id: json['id'] as String,
    nom: json['nom'] as String? ?? '',
    couleur: (json['couleur'] as num?)?.toInt() ?? 0xFF9E9E9E,
  );
}
