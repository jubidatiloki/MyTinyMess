import 'package:flutter/painting.dart';
import 'package:uuid/uuid.dart';

import '../data/depot.dart';
import '../models/type_bouteille.dart';
import 'collection_controller.dart';

/// Liste des types de bouteille, modifiable dans « Types de bouteille ».
class TypesBouteilleController extends CollectionController<TypeBouteille> {
  TypesBouteilleController(Depot depot) : super(depot, cle);

  static const cle = 'typesBouteille';

  @override
  TypeBouteille depuisJson(Map<String, dynamic> json) =>
      TypeBouteille.fromJson(json);
  @override
  Map<String, dynamic> versJson(TypeBouteille element) => element.toJson();
  @override
  String idDe(TypeBouteille element) => element.id;

  /// Au premier lancement (liste vide), crée les types par défaut.
  @override
  Future<void> charger() async {
    await super.charger();
    if (elements.isEmpty) {
      for (final t in TypeBouteille.parDefaut) {
        await enregistrer(t);
      }
    }
  }

  /// Nom du type, ou « Sans type » s'il n'existe plus.
  String nomDe(String id) => parId(id)?.nom ?? 'Sans type';

  Color couleurDe(String id) => parId(id)?.color ?? const Color(0xFF9E9E9E);

  Future<TypeBouteille> creer(String nom, int couleur) async {
    final type = TypeBouteille(
      id: const Uuid().v4(),
      nom: nom.trim(),
      couleur: couleur,
    );
    await enregistrer(type);
    return type;
  }
}
