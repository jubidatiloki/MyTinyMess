/// Moment d'un repas prévu.
enum MomentRepas {
  midi('Midi'),
  soir('Soir');

  const MomentRepas(this.libelle);
  final String libelle;
}

DateTime jourDe(DateTime d) => DateTime(d.year, d.month, d.day);

/// Événement de l'agenda : rendez-vous, invités, anniversaire…
class Evenement {
  const Evenement({
    required this.id,
    required this.titre,
    required this.date,
    this.heure,
    this.notes = '',
  });

  final String id;
  final String titre;

  /// Jour de l'événement (l'heure éventuelle est dans [heure]).
  final DateTime date;

  /// « 14:30 », ou null pour toute la journée.
  final String? heure;
  final String notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'titre': titre,
    'date': jourDe(date).toIso8601String(),
    'heure': ?heure,
    'notes': notes,
  };

  factory Evenement.fromJson(Map<String, dynamic> json) => Evenement(
    id: json['id'] as String,
    titre: json['titre'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2000),
    heure: json['heure'] as String?,
    notes: json['notes'] as String? ?? '',
  );
}

/// Repas prévu dans l'agenda : une recette du carnet, ou un texte libre
/// (« restaurant », « reste de la veille »…).
class RepasPrevu {
  const RepasPrevu({
    required this.id,
    required this.date,
    required this.moment,
    this.recetteId,
    this.libelle,
  });

  final String id;
  final DateTime date;
  final MomentRepas moment;
  final String? recetteId;

  /// Texte libre, ou nom de la recette au moment où elle a été choisie
  /// (affiché si la recette a été supprimée depuis).
  final String? libelle;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': jourDe(date).toIso8601String(),
    'moment': moment.name,
    'recetteId': ?recetteId,
    'libelle': ?libelle,
  };

  factory RepasPrevu.fromJson(Map<String, dynamic> json) => RepasPrevu(
    id: json['id'] as String,
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2000),
    moment: MomentRepas.values.firstWhere(
      (m) => m.name == json['moment'],
      orElse: () => MomentRepas.soir,
    ),
    recetteId: json['recetteId'] as String?,
    libelle: json['libelle'] as String?,
  );
}

/// Article de la liste de courses.
class ArticleCourses {
  const ArticleCourses({
    required this.id,
    required this.nom,
    this.quantite,
    this.coche = false,
    this.origine,
  });

  final String id;
  final String nom;
  final String? quantite;

  /// Acheté (coché dans la liste).
  final bool coche;

  /// D'où vient l'article : « Frigo », « Recette : Quiche lorraine »…
  final String? origine;

  ArticleCourses avecCoche(bool c) => ArticleCourses(
    id: id,
    nom: nom,
    quantite: quantite,
    coche: c,
    origine: origine,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'quantite': ?quantite,
    'coche': coche,
    'origine': ?origine,
  };

  factory ArticleCourses.fromJson(Map<String, dynamic> json) => ArticleCourses(
    id: json['id'] as String,
    nom: json['nom'] as String? ?? '',
    quantite: json['quantite'] as String?,
    coche: json['coche'] as bool? ?? false,
    origine: json['origine'] as String?,
  );
}
