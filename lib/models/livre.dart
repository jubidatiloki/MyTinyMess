/// Où en est la lecture du livre.
enum StatutLecture {
  aLire('À lire'),
  enCours('En cours'),
  lu('Lu');

  const StatutLecture(this.libelle);
  final String libelle;
}

/// Qui a le livre en main.
enum Possession {
  /// Le livre est à moi et dans ma bibliothèque.
  possede('Chez moi'),

  /// Le livre est à moi mais je l'ai prêté à quelqu'un.
  prete('Prêté'),

  /// Le livre n'est pas à moi : on me l'a prêté.
  emprunte('Emprunté');

  const Possession(this.libelle);
  final String libelle;
}

T _enumParNom<T extends Enum>(List<T> valeurs, Object? nom, T parDefaut) {
  for (final v in valeurs) {
    if (v.name == nom) {
      return v;
    }
  }
  return parDefaut;
}

class Livre {
  const Livre({
    required this.id,
    required this.titre,
    this.auteur = '',
    this.isbn,
    this.annee,
    this.genre,
    this.statut = StatutLecture.aLire,
    this.note,
    this.notes = '',
    this.possession = Possession.possede,
    this.personne,
    this.datePret,
    this.lieuId,
  });

  final String id;
  final String titre;
  final String auteur;
  final String? isbn;
  final int? annee;
  final String? genre;
  final StatutLecture statut;

  /// Note personnelle de 1 à 5 (null = pas noté).
  final int? note;

  /// Notes libres (avis, citations, résumé…).
  final String notes;
  final Possession possession;

  /// Personne à qui le livre est prêté, ou qui me l'a prêté.
  final String? personne;
  final DateTime? datePret;

  /// Emplacement personnalisé où le livre est rangé (voir `Lieu`).
  final String? lieuId;

  bool get estChezMoi => possession == Possession.possede;

  /// Le livre est prêté à [a] (ou emprunté si [emprunte] est vrai).
  Livre preter(String a, {DateTime? le, bool emprunte = false}) => _copie(
    possession: emprunte ? Possession.emprunte : Possession.prete,
    personne: a,
    datePret: le ?? DateTime.now(),
  );

  /// Le livre revient : il est de nouveau chez moi, sans prêt en cours.
  Livre rendre() =>
      _copie(possession: Possession.possede, personne: null, datePret: null);

  Livre avecStatut(StatutLecture s) => _copie(
    statut: s,
    possession: possession,
    personne: personne,
    datePret: datePret,
  );

  Livre _copie({
    StatutLecture? statut,
    required Possession possession,
    required String? personne,
    required DateTime? datePret,
  }) => Livre(
    id: id,
    titre: titre,
    auteur: auteur,
    isbn: isbn,
    annee: annee,
    genre: genre,
    statut: statut ?? this.statut,
    note: note,
    notes: notes,
    possession: possession,
    personne: personne,
    datePret: datePret,
    lieuId: lieuId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titre': titre,
    'auteur': auteur,
    if (isbn != null) 'isbn': isbn,
    if (annee != null) 'annee': annee,
    if (genre != null) 'genre': genre,
    'statut': statut.name,
    if (note != null) 'note': note,
    'notes': notes,
    'possession': possession.name,
    if (personne != null) 'personne': personne,
    if (datePret != null) 'datePret': datePret!.toIso8601String(),
    if (lieuId != null) 'lieuId': lieuId,
  };

  factory Livre.fromJson(Map<String, dynamic> json) => Livre(
    id: json['id'] as String,
    titre: json['titre'] as String? ?? '',
    auteur: json['auteur'] as String? ?? '',
    isbn: json['isbn'] as String?,
    annee: (json['annee'] as num?)?.toInt(),
    genre: json['genre'] as String?,
    statut: _enumParNom(
      StatutLecture.values,
      json['statut'],
      StatutLecture.aLire,
    ),
    note: (json['note'] as num?)?.toInt(),
    notes: json['notes'] as String? ?? '',
    possession: _enumParNom(
      Possession.values,
      json['possession'],
      Possession.possede,
    ),
    personne: json['personne'] as String?,
    datePret: DateTime.tryParse(json['datePret'] as String? ?? ''),
    lieuId: json['lieuId'] as String?,
  );
}
