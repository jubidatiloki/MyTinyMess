import 'package:uuid/uuid.dart';

import '../data/depot.dart';
import 'collection_controller.dart';

/// Catégorie d'aliment (« Produits laitiers »…). Les aliments y font
/// référence par son nom (`Aliment.categorie`).
class CategorieAliment {
  const CategorieAliment({required this.id, required this.nom});

  final String id;
  final String nom;

  static const parDefaut = [
    'Fruits et légumes',
    'Viandes et charcuterie',
    'Poissons',
    'Produits laitiers',
    'Œufs',
    'Épicerie salée',
    'Épicerie sucrée',
    'Boissons',
    'Surgelés',
    'Condiments',
  ];
}

/// Liste des catégories d'aliments, modifiable dans les préférences.
class CategoriesController extends CollectionController<CategorieAliment> {
  CategoriesController(Depot depot) : super(depot, cle);

  static const cle = 'categoriesAliment';

  @override
  CategorieAliment depuisJson(Map<String, dynamic> json) => CategorieAliment(
    id: json['id'] as String,
    nom: json['nom'] as String? ?? '',
  );
  @override
  Map<String, dynamic> versJson(CategorieAliment element) => {
    'id': element.id,
    'nom': element.nom,
  };
  @override
  String idDe(CategorieAliment element) => element.id;

  /// Au premier lancement (liste vide), crée les catégories par défaut.
  @override
  Future<void> charger() async {
    await super.charger();
    if (elements.isEmpty) {
      for (final nom in CategorieAliment.parDefaut) {
        await creer(nom);
      }
    }
  }

  /// Catégorie portant ce nom (sans tenir compte des accents ni majuscules).
  CategorieAliment? parNom(String? nom) {
    final n = normaliser((nom ?? '').trim());
    for (final c in elements) {
      if (normaliser(c.nom) == n) {
        return c;
      }
    }
    return null;
  }

  Future<CategorieAliment> creer(String nom) async {
    final c = CategorieAliment(id: const Uuid().v4(), nom: nom.trim());
    await enregistrer(c);
    return c;
  }
}
