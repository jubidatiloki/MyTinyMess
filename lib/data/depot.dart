import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lieu de stockage des données : une liste d'objets JSON par clé
/// (ex. « livres », « bouteilles »).
abstract class Depot {
  Future<List<Map<String, dynamic>>> lire(String cle);
  Future<void> ecrire(String cle, List<Map<String, dynamic>> elements);
}

/// Stockage sur l'appareil (navigateur, téléphone, PC).
class DepotPreferences implements Depot {
  DepotPreferences(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<List<Map<String, dynamic>>> lire(String cle) async {
    final texte = _prefs.getString(cle);
    if (texte == null || texte.isEmpty) {
      return [];
    }
    final liste = jsonDecode(texte) as List;
    return [for (final e in liste) (e as Map).cast<String, dynamic>()];
  }

  @override
  Future<void> ecrire(String cle, List<Map<String, dynamic>> elements) async {
    await _prefs.setString(cle, jsonEncode(elements));
  }
}

/// Stockage en mémoire, pour les tests.
class DepotMemoire implements Depot {
  final Map<String, String> _donnees = {};

  @override
  Future<List<Map<String, dynamic>>> lire(String cle) async {
    final texte = _donnees[cle];
    if (texte == null) {
      return [];
    }
    final liste = jsonDecode(texte) as List;
    return [for (final e in liste) (e as Map).cast<String, dynamic>()];
  }

  @override
  Future<void> ecrire(String cle, List<Map<String, dynamic>> elements) async {
    // Passage par du texte JSON, comme le vrai stockage.
    _donnees[cle] = jsonEncode(elements);
  }
}
