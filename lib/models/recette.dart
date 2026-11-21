/// Style de repas, pour filtrer les propositions.
enum StyleRecette {
  gourmand('Gourmand'),
  light('Light'),
  rapide('Rapide'),
  vegetarien('Végétarien'),
  economique('Économique');

  const StyleRecette(this.libelle);
  final String libelle;
}

/// D'où vient une recette.
enum SourceRecette {
  /// Carnet fourni avec l'application (non modifiable).
  integree,

  /// Saisie par l'utilisateur.
  perso,

  /// Trouvée en ligne (pas encore ajoutée au carnet).
  enLigne,
}

/// Un ingrédient : « 200 g » de « farine ».
class Ingredient {
  const Ingredient({required this.nom, this.quantite, this.placard = false});

  final String nom;
  final String? quantite;

  /// Produit de base qu'on a presque toujours (sel, poivre, huile…) : jamais
  /// signalé comme manquant.
  final bool placard;

  String get libelle => quantite == null ? nom : '$quantite $nom';

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'quantite': ?quantite,
    if (placard) 'placard': true,
  };

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    nom: json['nom'] as String? ?? '',
    quantite: json['quantite'] as String?,
    placard: json['placard'] as bool? ?? false,
  );

  static final _unites = RegExp(
    r'^(\d+[.,]?\d*|\d+/\d+|une?|quelques)\s*'
    r'(g|kg|mg|ml|cl|dl|l|c\.\s*à\s*[sc]\.?|cuill[eè]res?\s*à\s*(soupe|café)|'
    r'pincées?|tranches?|gousses?|brins?|bottes?|sachets?|pots?|boîtes?|'
    r'verres?|tasses?)?\s*(de\s+|d[\x27’]\s*)?',
    caseSensitive: false,
  );

  /// Ligne saisie par l'utilisateur : « 200 g de farine » → quantité
  /// « 200 g », nom « farine ». Sans quantité, toute la ligne est le nom.
  factory Ingredient.depuisLigne(String ligne) {
    final texte = ligne.trim();
    final m = _unites.firstMatch(texte);
    if (m == null || m.end == 0 || m.end >= texte.length) {
      return Ingredient(nom: texte);
    }
    final quantite = [
      m.group(1),
      m.group(2),
    ].whereType<String>().join(' ').trim();
    return Ingredient(
      nom: texte.substring(m.end).trim(),
      quantite: quantite.isEmpty ? null : quantite,
    );
  }
}

class Recette {
  const Recette({
    required this.id,
    required this.nom,
    this.styles = const {},
    this.ingredients = const [],
    this.etapes = '',
    this.minutes,
    this.personnes,
    this.source = SourceRecette.perso,
    this.image,
  });

  final String id;
  final String nom;
  final Set<StyleRecette> styles;
  final List<Ingredient> ingredients;

  /// Préparation, une étape par ligne.
  final String etapes;
  final int? minutes;
  final int? personnes;
  final SourceRecette source;

  /// Adresse d'une photo (recettes en ligne).
  final String? image;

  bool get modifiable => source == SourceRecette.perso;

  Recette copie({String? id, SourceRecette? source}) => Recette(
    id: id ?? this.id,
    nom: nom,
    styles: styles,
    ingredients: ingredients,
    etapes: etapes,
    minutes: minutes,
    personnes: personnes,
    source: source ?? this.source,
    image: image,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'styles': [for (final s in styles) s.name],
    'ingredients': [for (final i in ingredients) i.toJson()],
    'etapes': etapes,
    'minutes': ?minutes,
    'personnes': ?personnes,
    'source': source.name,
    'image': ?image,
  };

  factory Recette.fromJson(
    Map<String, dynamic> json, {
    SourceRecette? source,
  }) => Recette(
    id: json['id'] as String,
    nom: json['nom'] as String? ?? '',
    styles: {
      for (final s in (json['styles'] as List?) ?? const [])
        ...StyleRecette.values.where((v) => v.name == s),
    },
    ingredients: [
      for (final i in (json['ingredients'] as List?) ?? const [])
        Ingredient.fromJson((i as Map).cast<String, dynamic>()),
    ],
    etapes: json['etapes'] as String? ?? '',
    minutes: (json['minutes'] as num?)?.toInt(),
    personnes: (json['personnes'] as num?)?.toInt(),
    source:
        source ??
        SourceRecette.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => SourceRecette.perso,
        ),
    image: json['image'] as String?,
  );
}
