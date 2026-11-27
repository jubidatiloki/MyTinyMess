import 'unite.dart';

/// Où en est un aliment par rapport à sa date de péremption.
enum EtatPeremption {
  /// Pas de date renseignée.
  sansDate,
  ok,

  /// À consommer dans les jours qui viennent.
  bientot,
  perime,
}

/// Aliment du frigo (ou du congélateur, du placard…).
class Aliment {
  const Aliment({
    required this.id,
    required this.nom,
    this.categorie,
    this.quantite = 1,
    this.unite,
    this.niveau,
    this.contenance,
    this.datePeremption,
    this.dateAjout,
    this.lieuId,
    this.notes = '',
    this.variante,
  });

  /// Nombre de jours avant la péremption à partir duquel on alerte.
  static const joursAlerte = 3;

  final String id;
  final String nom;

  /// Libre : laitage, viande, légumes…
  final String? categorie;

  /// Nombre d'unités (pots, paquets, pièces…). 0 = épuisé.
  final int quantite;

  /// Unité de la quantité, au singulier : « tranche », « paquet »…
  final String? unite;

  /// Ce qu'il reste de l'unité entamée, en % (null = pleine).
  final int? niveau;

  /// Libre : « 500 g », « 1 L », « 4 pots »…
  final String? contenance;
  final DateTime? datePeremption;
  final DateTime? dateAjout;

  /// Emplacement (de type frigo : frigo, congélateur, placard…).
  final String? lieuId;
  final String notes;

  /// Variante : « grenailles » pour des pommes de terre, « demi-sel »…
  final String? variante;

  /// « Pommes de terre · grenailles ».
  String get nomComplet => [nom, ?variante].join(' · ');

  /// « 3 tranches », ou « 3 » sans unité.
  String get quantiteLisible => [
    '$quantite',
    if (unite != null) accorderUnite(unite!, quantite),
  ].join(' ');

  bool get enStock => quantite > 0;

  static DateTime _jour(DateTime d) =>
      // En UTC : une journée y dure toujours 24 heures (changements d'heure).
      DateTime.utc(d.year, d.month, d.day);

  /// Jours restants avant la péremption (négatif si dépassée), ou null.
  int? joursRestants(DateTime aujourdhui) {
    final d = datePeremption;
    if (d == null) {
      return null;
    }
    return _jour(d).difference(_jour(aujourdhui)).inDays;
  }

  EtatPeremption etat(DateTime aujourdhui) {
    final j = joursRestants(aujourdhui);
    if (j == null) {
      return EtatPeremption.sansDate;
    }
    if (j < 0) {
      return EtatPeremption.perime;
    }
    return j <= joursAlerte ? EtatPeremption.bientot : EtatPeremption.ok;
  }

  /// Nouvelle quantité ; le niveau est gardé, sauf s'il est donné.
  Aliment avecQuantite(int q, {int? niveau, bool changerNiveau = false}) {
    final n = q < 0 ? 0 : q;
    final v = changerNiveau ? niveau : this.niveau;
    return Aliment(
      id: id,
      nom: nom,
      categorie: categorie,
      quantite: n,
      unite: unite,
      niveau: n == 0 || v == null || v >= 100 ? null : (v < 0 ? 0 : v),
      contenance: contenance,
      datePeremption: datePeremption,
      dateAjout: dateAjout,
      lieuId: lieuId,
      notes: notes,
      variante: variante,
    );
  }

  Aliment avecCategorie(String c) => _copie(categorie: c);

  Aliment _copie({int? quantite, String? categorie}) => Aliment(
    id: id,
    nom: nom,
    categorie: categorie ?? this.categorie,
    quantite: quantite ?? this.quantite,
    unite: unite,
    niveau: niveau,
    contenance: contenance,
    datePeremption: datePeremption,
    dateAjout: dateAjout,
    lieuId: lieuId,
    notes: notes,
    variante: variante,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'categorie': ?categorie,
    'quantite': quantite,
    'unite': ?unite,
    'niveau': ?niveau,
    'contenance': ?contenance,
    if (datePeremption != null)
      'datePeremption': datePeremption!.toIso8601String(),
    if (dateAjout != null) 'dateAjout': dateAjout!.toIso8601String(),
    'lieuId': ?lieuId,
    'notes': notes,
    'variante': ?variante,
  };

  factory Aliment.fromJson(Map<String, dynamic> json) => Aliment(
    id: json['id'] as String,
    nom: json['nom'] as String? ?? '',
    categorie: json['categorie'] as String?,
    quantite: (json['quantite'] as num?)?.toInt() ?? 1,
    unite: json['unite'] as String?,
    niveau: (json['niveau'] as num?)?.toInt(),
    contenance: json['contenance'] as String?,
    datePeremption: DateTime.tryParse(json['datePeremption'] as String? ?? ''),
    dateAjout: DateTime.tryParse(json['dateAjout'] as String? ?? ''),
    lieuId: json['lieuId'] as String?,
    notes: json['notes'] as String? ?? '',
    variante: json['variante'] as String?,
  );
}
