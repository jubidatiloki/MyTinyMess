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
    'Fromages',
    'Œufs',
    'Épicerie salée',
    'Épicerie sucrée',
    'Boissons',
    'Surgelés',
    'Condiments',
  ];

  /// Catégories ajoutées après coup (0.16.0) : proposées une seule fois aux
  /// listes déjà créées ; supprimées ensuite, elles ne reviennent pas.
  static const ajouts = ['Fromages'];
}

/// Liste des catégories d'aliments, modifiable dans les préférences.
class CategoriesController extends CollectionController<CategorieAliment> {
  CategoriesController(this._depotAjouts) : super(_depotAjouts, cle);

  static const cle = 'categoriesAliment';

  /// Ajouts déjà faits (liste de noms).
  static const cleAjouts = 'categoriesAjoutees';
  final Depot _depotAjouts;

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

  /// Par ordre alphabétique (accents et majuscules ignorés).
  @override
  List<CategorieAliment> get elements =>
      [...super.elements]
        ..sort((a, b) => normaliser(a.nom).compareTo(normaliser(b.nom)));

  /// Au premier lancement (liste vide), crée les catégories par défaut.
  @override
  Future<void> charger() async {
    await super.charger();
    final faits = {
      for (final e in await _depotAjouts.lire(cleAjouts)) e['nom'] as String?,
    };
    if (elements.isEmpty) {
      for (final nom in CategorieAliment.parDefaut) {
        await creer(nom);
      }
    } else {
      for (final nom in CategorieAliment.ajouts) {
        if (!faits.contains(nom) && parNom(nom) == null) {
          await creer(nom);
        }
      }
    }
    if (!CategorieAliment.ajouts.every(faits.contains)) {
      await _depotAjouts.ecrire(cleAjouts, [
        for (final nom in {...faits.nonNulls, ...CategorieAliment.ajouts})
          {'nom': nom},
      ]);
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
