import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/isbn.dart';

/// Ce que l'on retrouve d'un livre à partir de son ISBN.
class InfosLivre {
  const InfosLivre({
    required this.isbn,
    required this.titre,
    this.auteur = '',
    this.annee,
    this.genre,
  });

  final String isbn;
  final String titre;
  final String auteur;
  final int? annee;
  final String? genre;
}

/// Retrouve titre, auteur… d'un livre à partir de son ISBN.
abstract class RechercheIsbn {
  /// null si l'ISBN est invalide ou le livre introuvable.
  /// Lève une exception si le service ne répond pas (pas d'Internet…).
  Future<InfosLivre?> chercher(String isbn);
}

/// Recherche en ligne : Google Books d'abord (bonne couverture des livres
/// français), puis Open Library. Seul l'ISBN est envoyé.
class RechercheIsbnEnLigne implements RechercheIsbn {
  RechercheIsbnEnLigne({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const _delai = Duration(seconds: 10);

  @override
  Future<InfosLivre?> chercher(String isbn) async {
    final propre = normaliserIsbn(isbn);
    if (propre == null) {
      return null;
    }
    Object? erreur;
    for (final source in [_googleBooks, _openLibrary]) {
      try {
        final infos = await source(propre);
        if (infos != null) {
          return infos;
        }
      } catch (e) {
        erreur = e; // on essaie la source suivante
      }
    }
    if (erreur != null) {
      throw erreur;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _json(Uri adresse) async {
    final reponse = await _client.get(adresse).timeout(_delai);
    if (reponse.statusCode == 404) {
      return null;
    }
    if (reponse.statusCode != 200) {
      throw http.ClientException('Réponse ${reponse.statusCode}', adresse);
    }
    return jsonDecode(utf8.decode(reponse.bodyBytes)) as Map<String, dynamic>;
  }

  Future<InfosLivre?> _googleBooks(String isbn) async {
    final json = await _json(
      Uri.https('www.googleapis.com', '/books/v1/volumes', {'q': 'isbn:$isbn'}),
    );
    final items = json?['items'] as List?;
    if (items == null || items.isEmpty) {
      return null;
    }
    final v = (items.first as Map)['volumeInfo'] as Map? ?? {};
    final titre = [
      v['title'] as String? ?? '',
      if (v['subtitle'] != null) v['subtitle'] as String,
    ].where((t) => t.isNotEmpty).join(' : ');
    if (titre.isEmpty) {
      return null;
    }
    return InfosLivre(
      isbn: isbn,
      titre: titre,
      auteur: ((v['authors'] as List?) ?? const []).join(', '),
      annee: _annee(v['publishedDate'] as String?),
      genre: ((v['categories'] as List?) ?? const []).firstOrNull as String?,
    );
  }

  Future<InfosLivre?> _openLibrary(String isbn) async {
    final cle = 'ISBN:$isbn';
    final json = await _json(
      Uri.https('openlibrary.org', '/api/books', {
        'bibkeys': cle,
        'format': 'json',
        'jscmd': 'data',
      }),
    );
    final livre = json?[cle] as Map?;
    final titre = livre?['title'] as String?;
    if (livre == null || titre == null || titre.isEmpty) {
      return null;
    }
    final auteurs = [
      for (final a in (livre['authors'] as List?) ?? const [])
        (a as Map)['name'] as String? ?? '',
    ].where((a) => a.isNotEmpty);
    final sujets = (livre['subjects'] as List?) ?? const [];
    return InfosLivre(
      isbn: isbn,
      titre: titre,
      auteur: auteurs.join(', '),
      annee: _annee(livre['publish_date'] as String?),
      genre: sujets.isEmpty ? null : (sujets.first as Map)['name'] as String?,
    );
  }

  /// Première année à 4 chiffres trouvée dans « 2005-03-01 », « mars 1965 »…
  static int? _annee(String? date) {
    final m = RegExp(r'\b(\d{4})\b').firstMatch(date ?? '');
    return m == null ? null : int.parse(m.group(1)!);
  }
}
