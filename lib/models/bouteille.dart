enum TypeVin {
  rouge('Rouge'),
  blanc('Blanc'),
  rose('Rosé'),
  effervescent('Effervescent'),
  liquoreux('Liquoreux'),
  autre('Autre');

  const TypeVin(this.libelle);
  final String libelle;
}

/// Endroit exact où sont rangées les bouteilles.
class Emplacement {
  const Emplacement({required this.zone, this.rangee, this.colonne});

  /// Cave, casier, armoire… (ex. « Casier du fond »).
  final String zone;

  /// Rangée / étagère (ex. « 3 » ou « B »).
  final String? rangee;

  /// Colonne / position dans la rangée.
  final String? colonne;

  String get libelle {
    final morceaux = [
      zone,
      if (rangee != null && rangee!.isNotEmpty) 'rangée $rangee',
      if (colonne != null && colonne!.isNotEmpty) 'colonne $colonne',
    ];
    return morceaux.join(' · ');
  }

  Map<String, dynamic> toJson() => {
    'zone': zone,
    if (rangee != null) 'rangee': rangee,
    if (colonne != null) 'colonne': colonne,
  };

  factory Emplacement.fromJson(Map<String, dynamic> json) => Emplacement(
    zone: json['zone'] as String? ?? '',
    rangee: json['rangee'] as String?,
    colonne: json['colonne'] as String?,
  );
}

/// Une entrée ou une sortie de bouteilles (historique de la cave).
class Mouvement {
  const Mouvement({
    required this.date,
    required this.quantite,
    this.commentaire,
  });

  final DateTime date;

  /// Positif = ajout, négatif = retrait.
  final int quantite;
  final String? commentaire;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'quantite': quantite,
    if (commentaire != null) 'commentaire': commentaire,
  };

  factory Mouvement.fromJson(Map<String, dynamic> json) => Mouvement(
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2000),
    quantite: (json['quantite'] as num?)?.toInt() ?? 0,
    commentaire: json['commentaire'] as String?,
  );
}

class Bouteille {
  const Bouteille({
    required this.id,
    required this.nom,
    required this.emplacement,
    this.type = TypeVin.rouge,
    this.producteur,
    this.appellation,
    this.region,
    this.millesime,
    this.aBoireAvant,
    this.quantite = 0,
    this.notes = '',
    this.mouvements = const [],
  });

  final String id;

  /// Nom de la cuvée ou du vin.
  final String nom;
  final Emplacement emplacement;
  final TypeVin type;
  final String? producteur;
  final String? appellation;
  final String? region;
  final int? millesime;

  /// Année limite de garde conseillée.
  final int? aBoireAvant;

  /// Nombre de bouteilles en stock.
  final int quantite;
  final String notes;
  final List<Mouvement> mouvements;

  bool get enStock => quantite > 0;

  /// Ajoute [n] bouteilles au stock (et note le mouvement).
  Bouteille ajouter(int n, {String? commentaire, DateTime? le}) {
    if (n <= 0) {
      throw ArgumentError.value(n, 'n', 'doit être positif');
    }
    return _avecMouvement(n, commentaire, le);
  }

  /// Retire [n] bouteilles du stock (bue, offerte…).
  Bouteille retirer(int n, {String? commentaire, DateTime? le}) {
    if (n <= 0) {
      throw ArgumentError.value(n, 'n', 'doit être positif');
    }
    if (n > quantite) {
      throw StateError('Seulement $quantite bouteille(s) en stock');
    }
    return _avecMouvement(-n, commentaire, le);
  }

  Bouteille _avecMouvement(int delta, String? commentaire, DateTime? le) =>
      Bouteille(
        id: id,
        nom: nom,
        emplacement: emplacement,
        type: type,
        producteur: producteur,
        appellation: appellation,
        region: region,
        millesime: millesime,
        aBoireAvant: aBoireAvant,
        quantite: quantite + delta,
        notes: notes,
        mouvements: [
          ...mouvements,
          Mouvement(
            date: le ?? DateTime.now(),
            quantite: delta,
            commentaire: commentaire,
          ),
        ],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'emplacement': emplacement.toJson(),
    'type': type.name,
    if (producteur != null) 'producteur': producteur,
    if (appellation != null) 'appellation': appellation,
    if (region != null) 'region': region,
    if (millesime != null) 'millesime': millesime,
    if (aBoireAvant != null) 'aBoireAvant': aBoireAvant,
    'quantite': quantite,
    'notes': notes,
    'mouvements': mouvements.map((m) => m.toJson()).toList(),
  };

  factory Bouteille.fromJson(Map<String, dynamic> json) => Bouteille(
    id: json['id'] as String,
    nom: json['nom'] as String? ?? '',
    emplacement: Emplacement.fromJson(
      (json['emplacement'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    type: TypeVin.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => TypeVin.autre,
    ),
    producteur: json['producteur'] as String?,
    appellation: json['appellation'] as String?,
    region: json['region'] as String?,
    millesime: (json['millesime'] as num?)?.toInt(),
    aBoireAvant: (json['aBoireAvant'] as num?)?.toInt(),
    quantite: (json['quantite'] as num?)?.toInt() ?? 0,
    notes: json['notes'] as String? ?? '',
    mouvements: [
      for (final m in (json['mouvements'] as List?) ?? const [])
        Mouvement.fromJson((m as Map).cast<String, dynamic>()),
    ],
  );
}
