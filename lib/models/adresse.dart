/// Sorte de bonne adresse.
enum TypeAdresse {
  personne('Personne', 'Personnes'),
  commerce('Commerçant', 'Commerçants'),
  restaurant('Restaurant, bar', 'Restaurants et bars'),
  artisan('Artisan, service', 'Artisans et services'),
  sante('Santé, bien-être', 'Santé et bien-être'),
  site('Site internet', 'Sites internet'),
  festival('Festival, événement', 'Festivals et événements'),
  sortie('Lieu, sortie', 'Lieux et sorties'),
  autre('Autre', 'Autres');

  const TypeAdresse(this.libelle, this.pluriel);
  final String libelle;
  final String pluriel;
}

/// Une bonne adresse de l'annuaire : seul le nom est obligatoire.
class Adresse {
  const Adresse({
    required this.id,
    required this.nom,
    this.type = TypeAdresse.autre,
    this.description,
    this.telephone,
    this.email,
    this.site,
    this.lieu,
    this.quand,
    this.recommandePar,
    this.avis = '',
    this.etiquettes = const [],
    this.favori = false,
  });

  final String id;
  final String nom;
  final TypeAdresse type;

  /// En quelques mots : « Boulanger », « Plombier », « Festival de jazz »…
  final String? description;
  final String? telephone;
  final String? email;
  final String? site;

  /// Adresse postale ou ville.
  final String? lieu;

  /// Horaires ou dates, en texte libre.
  final String? quand;

  /// Qui a donné cette adresse.
  final String? recommandePar;

  /// Pourquoi c'est une bonne adresse.
  final String avis;

  /// Mots libres pour regrouper (« Lyon », « cadeaux », « enfants »…).
  final List<String> etiquettes;
  final bool favori;

  Uri? get lienSite => lienWeb(site);

  Uri? get lienTelephone {
    final t = (telephone ?? '').replaceAll(RegExp(r'[^0-9+*#]'), '');
    return t.isEmpty ? null : Uri(scheme: 'tel', path: t);
  }

  Uri? get lienEmail {
    final e = (email ?? '').trim();
    return e.contains('@') ? Uri(scheme: 'mailto', path: e) : null;
  }

  Uri? get lienCarte {
    final l = (lieu ?? '').trim();
    return l.isEmpty
        ? null
        : Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': l,
          });
  }

  /// Adresse web valable (http ou https), « https:// » ajouté si besoin.
  static Uri? lienWeb(String? texte) {
    final t = (texte ?? '').trim();
    if (t.isEmpty || t.contains(RegExp(r'\s'))) {
      return null;
    }
    final u = Uri.tryParse(t.contains('://') ? t : 'https://$t');
    if (u == null ||
        (u.scheme != 'http' && u.scheme != 'https') ||
        !u.host.contains('.') ||
        u.userInfo.isNotEmpty) {
      return null;
    }
    return u;
  }

  /// Mots séparés par des virgules → liste sans vide ni doublon.
  static List<String> lireEtiquettes(String texte) {
    final vues = <String>{};
    return [
      for (final e in texte.split(',').map((e) => e.trim()))
        if (e.isNotEmpty && vues.add(e.toLowerCase())) e,
    ];
  }

  /// Fiche en texte simple, à coller dans un message. Sans le nom de la
  /// personne qui a recommandé l'adresse (privé).
  String get enTexte => [
    nom,
    [type.libelle, ?description].join(' · '),
    if (lieu != null) 'Adresse : $lieu',
    if (quand != null) 'Quand : $quand',
    if (telephone != null) 'Téléphone : $telephone',
    if (email != null) 'E-mail : $email',
    if (site != null) 'Site : ${lienSite ?? site}',
    if (avis.isNotEmpty) avis,
  ].join('\n');

  Adresse avecFavori(bool f) => Adresse(
    id: id,
    nom: nom,
    type: type,
    description: description,
    telephone: telephone,
    email: email,
    site: site,
    lieu: lieu,
    quand: quand,
    recommandePar: recommandePar,
    avis: avis,
    etiquettes: etiquettes,
    favori: f,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'type': type.name,
    'description': ?description,
    'telephone': ?telephone,
    'email': ?email,
    'site': ?site,
    'lieu': ?lieu,
    'quand': ?quand,
    'recommandePar': ?recommandePar,
    'avis': avis,
    'etiquettes': etiquettes,
    'favori': favori,
  };

  factory Adresse.fromJson(Map<String, dynamic> json) => Adresse(
    id: json['id'] as String,
    nom: json['nom'] as String? ?? '',
    type: TypeAdresse.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => TypeAdresse.autre,
    ),
    description: json['description'] as String?,
    telephone: json['telephone'] as String?,
    email: json['email'] as String?,
    site: json['site'] as String?,
    lieu: json['lieu'] as String?,
    quand: json['quand'] as String?,
    recommandePar: json['recommandePar'] as String?,
    avis: json['avis'] as String? ?? '',
    etiquettes: [...?(json['etiquettes'] as List?)?.cast<String>()],
    favori: json['favori'] as bool? ?? false,
  );
}
