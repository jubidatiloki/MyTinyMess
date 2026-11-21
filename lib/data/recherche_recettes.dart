import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recette.dart';

/// Recherche de recettes sur Internet.
abstract class RechercheRecettes {
  /// Recettes dont le nom contient [texte]. Lève une exception sans
  /// connexion.
  Future<List<Recette>> chercher(String texte);
}

/// TheMealDB (gratuit, sans compte) : beaucoup de recettes, **en anglais**.
/// Seul le mot cherché est envoyé.
class RechercheRecettesEnLigne implements RechercheRecettes {
  RechercheRecettesEnLigne({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<Recette>> chercher(String texte) async {
    final t = texte.trim();
    if (t.isEmpty) {
      return const [];
    }
    final adresse = Uri.https(
      'www.themealdb.com',
      '/api/json/v1/1/search.php',
      {'s': t},
    );
    final reponse = await _client
        .get(adresse)
        .timeout(const Duration(seconds: 10));
    if (reponse.statusCode != 200) {
      throw http.ClientException('Réponse ${reponse.statusCode}', adresse);
    }
    final json = jsonDecode(utf8.decode(reponse.bodyBytes)) as Map;
    final meals = json['meals'] as List?;
    return [
      for (final m in meals ?? const [])
        _versRecette((m as Map).cast<String, dynamic>()),
    ];
  }

  static Recette _versRecette(Map<String, dynamic> m) {
    final ingredients = <Ingredient>[];
    for (var i = 1; i <= 20; i++) {
      final nom = (m['strIngredient$i'] as String?)?.trim() ?? '';
      if (nom.isEmpty) {
        continue;
      }
      final quantite = (m['strMeasure$i'] as String?)?.trim() ?? '';
      ingredients.add(
        Ingredient(nom: nom, quantite: quantite.isEmpty ? null : quantite),
      );
    }
    final categorie = (m['strCategory'] as String? ?? '').toLowerCase();
    return Recette(
      id: 'mealdb-${m['idMeal']}',
      nom: m['strMeal'] as String? ?? '',
      styles: {
        if (categorie == 'vegetarian' || categorie == 'vegan')
          StyleRecette.vegetarien,
        if (categorie == 'dessert') StyleRecette.gourmand,
      },
      ingredients: ingredients,
      etapes: (m['strInstructions'] as String? ?? '')
          .replaceAll('\r\n', '\n')
          .trim(),
      source: SourceRecette.enLigne,
      image: m['strMealThumb'] as String?,
    );
  }
}
