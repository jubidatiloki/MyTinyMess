import 'package:flutter/foundation.dart';

import '../data/depot.dart';

/// Base commune : une liste d'éléments chargée depuis un [Depot]
/// et réenregistrée à chaque changement.
abstract class CollectionController<T> extends ChangeNotifier {
  CollectionController(this._depot, this._cle);

  final Depot _depot;
  final String _cle;
  List<T> _elements = [];
  bool _charge = false;

  T depuisJson(Map<String, dynamic> json);
  Map<String, dynamic> versJson(T element);
  String idDe(T element);

  List<T> get elements => List.unmodifiable(_elements);
  bool get charge => _charge;

  T? parId(String id) {
    for (final e in _elements) {
      if (idDe(e) == id) {
        return e;
      }
    }
    return null;
  }

  Future<void> charger() async {
    final donnees = await _depot.lire(_cle);
    _elements = donnees.map(depuisJson).toList();
    _charge = true;
    notifyListeners();
  }

  /// Ajoute l'élément, ou le remplace s'il existe déjà (même id).
  Future<void> enregistrer(T element) async {
    final i = _elements.indexWhere((e) => idDe(e) == idDe(element));
    if (i >= 0) {
      _elements[i] = element;
    } else {
      _elements.add(element);
    }
    await _sauver();
  }

  Future<void> supprimer(String id) async {
    _elements.removeWhere((e) => idDe(e) == id);
    await _sauver();
  }

  Future<void> _sauver() async {
    notifyListeners();
    await _depot.ecrire(_cle, _elements.map(versJson).toList());
  }
}

/// Texte simplifié pour la recherche (minuscules, sans accents).
String normaliser(String texte) {
  const avec = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæ';
  const sans = 'aaaaaaceeeeiiiinooooouuuuyyoa';
  final buffer = StringBuffer();
  for (final c in texte.toLowerCase().split('')) {
    final i = avec.indexOf(c);
    buffer.write(i >= 0 ? sans[i] : c);
  }
  return buffer.toString();
}
