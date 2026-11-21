import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../data/depot.dart';
import '../models/aliment.dart';
import '../models/recette.dart';
import 'collection_controller.dart';

const _motsVides = {
  'de',
  'des',
  'du',
  'la',
  'le',
  'les',
  'aux',
  'au',
  'en',
  'et',
  'pour',
  'avec',
  'sans',
  'une',
  'un',
  'bio',
  'frais',
  'fraiche',
  'fraiches',
};

String _singulier(String mot) =>
    mot.length > 3 && (mot.endsWith('s') || mot.endsWith('x'))
    ? mot.substring(0, mot.length - 1)
    : mot;

/// Mots significatifs d'un nom, dans l'ordre : « Pommes de terre » →
/// [pomme, terre] ; « Œufs bio » → [oeuf].
List<String> motsCles(String texte) {
  final propre = normaliser(
    texte.toLowerCase().replaceAll('œ', 'oe').replaceAll('æ', 'ae'),
  );
  return [
    for (final mot in propre.split(RegExp(r'[^a-z]+')))
      if (mot.length >= 3 && !_motsVides.contains(mot)) _singulier(mot),
  ];
}

/// L'ingrédient est-il dans le frigo ? On compare le premier mot significatif
/// de l'ingrédient (« pomme » pour « pommes de terre ») aux mots des aliments.
bool ingredientDisponible(Ingredient i, Iterable<String> nomsFrigo) {
  final cles = motsCles(i.nom);
  if (cles.isEmpty) {
    return false;
  }
  return nomsFrigo.any((nom) => motsCles(nom).contains(cles.first));
}

/// Une recette proposée, avec ce qu'on a et ce qui manque.
class Suggestion {
  const Suggestion({
    required this.recette,
    required this.disponibles,
    required this.manquants,
  });

  final Recette recette;
  final List<Ingredient> disponibles;

  /// Ingrédients à acheter (hors produits de placard).
  final List<Ingredient> manquants;

  /// Part des ingrédients déjà là (0 à 1).
  double get score {
    final total = disponibles.length + manquants.length;
    return total == 0 ? 0 : disponibles.length / total;
  }

  bool get complete => manquants.isEmpty;
}

/// Carnet de recettes : recettes intégrées (fichier fourni avec l'appli) +
/// recettes personnelles (enregistrées, clé `recettes`).
class RecettesController extends CollectionController<Recette> {
  RecettesController(
    Depot depot, {
    Future<List<Recette>> Function()? chargerIntegrees,
  }) : _chargerIntegrees = chargerIntegrees ?? _depuisFichier,
       super(depot, cle);

  static const cle = 'recettes';
  static const fichier = 'assets/data/recettes.json';

  final Future<List<Recette>> Function() _chargerIntegrees;
  List<Recette> _integrees = const [];

  static Future<List<Recette>> _depuisFichier() async {
    final texte = await rootBundle.loadString(fichier);
    return [
      for (final r in jsonDecode(texte) as List)
        Recette.fromJson(
          (r as Map).cast<String, dynamic>(),
          source: SourceRecette.integree,
        ),
    ];
  }

  @override
  Recette depuisJson(Map<String, dynamic> json) => Recette.fromJson(json);
  @override
  Map<String, dynamic> versJson(Recette element) => element.toJson();
  @override
  String idDe(Recette element) => element.id;

  @override
  Future<void> charger() async {
    try {
      _integrees = await _chargerIntegrees();
    } catch (_) {
      _integrees = const []; // carnet intégré illisible : on continue
    }
    await super.charger();
  }

  List<Recette> get integrees => List.unmodifiable(_integrees);

  /// Carnet complet : intégrées puis personnelles, triées par nom.
  List<Recette> get toutes =>
      [..._integrees, ...elements]
        ..sort((a, b) => normaliser(a.nom).compareTo(normaliser(b.nom)));

  Recette? recette(String? id) {
    if (id == null) {
      return null;
    }
    for (final r in _integrees) {
      if (r.id == id) {
        return r;
      }
    }
    return parId(id);
  }

  /// Ajoute une recette trouvée en ligne au carnet personnel.
  Future<Recette> ajouterAuCarnet(Recette r) async {
    final copie = r.copie(id: const Uuid().v4(), source: SourceRecette.perso);
    await enregistrer(copie);
    return copie;
  }

  List<Recette> rechercher({String texte = '', StyleRecette? style}) {
    final t = normaliser(texte.trim());
    return toutes.where((r) {
      if (style != null && !r.styles.contains(style)) {
        return false;
      }
      if (t.isEmpty) {
        return true;
      }
      return normaliser(
        [r.nom, ...r.ingredients.map((i) => i.nom)].join(' '),
      ).contains(t);
    }).toList();
  }

  Suggestion analyser(Recette r, Iterable<String> nomsFrigo) {
    final dispo = <Ingredient>[];
    final manque = <Ingredient>[];
    for (final i in r.ingredients) {
      if (i.placard) {
        continue;
      }
      (ingredientDisponible(i, nomsFrigo) ? dispo : manque).add(i);
    }
    return Suggestion(recette: r, disponibles: dispo, manquants: manque);
  }

  /// Recettes réalisables avec le frigo (aliments en stock), les plus
  /// complètes d'abord. Au moins un ingrédient doit être déjà là.
  List<Suggestion> suggestions(Iterable<Aliment> frigo, {StyleRecette? style}) {
    final noms = [
      for (final a in frigo)
        if (a.enStock) a.nom,
    ];
    final liste = [
      for (final r in toutes)
        if (style == null || r.styles.contains(style)) analyser(r, noms),
    ].where((s) => s.disponibles.isNotEmpty).toList();
    liste.sort((a, b) {
      final c = b.score.compareTo(a.score);
      if (c != 0) {
        return c;
      }
      return a.manquants.length.compareTo(b.manquants.length);
    });
    return liste;
  }
}
