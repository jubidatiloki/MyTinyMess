import '../data/depot.dart';
import '../models/bouteille.dart';
import 'collection_controller.dart';

class CaveController extends CollectionController<Bouteille> {
  CaveController(Depot depot) : super(depot, cle);

  static const cle = 'bouteilles';

  @override
  Bouteille depuisJson(Map<String, dynamic> json) => Bouteille.fromJson(json);
  @override
  Map<String, dynamic> versJson(Bouteille element) => element.toJson();
  @override
  String idDe(Bouteille element) => element.id;

  /// Nombre total de bouteilles dans la cave.
  int get totalBouteilles => elements.fold(0, (s, b) => s + b.quantite);

  Future<void> ajouterBouteilles(String id, int n, {String? commentaire}) =>
      _modifier(id, (b) => b.ajouter(n, commentaire: commentaire));

  Future<void> retirerBouteilles(String id, int n, {String? commentaire}) =>
      _modifier(id, (b) => b.retirer(n, commentaire: commentaire));

  Future<void> _modifier(String id, Bouteille Function(Bouteille) action) {
    final b = parId(id);
    if (b == null) {
      throw StateError('Bouteille introuvable : $id');
    }
    return enregistrer(action(b));
  }

  /// Bouteilles correspondant à la recherche (nom, appellation, région,
  /// emplacement…) et au type. Celles en stock d'abord, puis par nom.
  List<Bouteille> rechercher({
    String texte = '',
    TypeVin? type,
    bool seulementEnStock = false,
  }) {
    final t = normaliser(texte.trim());
    final resultat = elements.where((b) {
      if (type != null && b.type != type) {
        return false;
      }
      if (seulementEnStock && !b.enStock) {
        return false;
      }
      if (t.isEmpty) {
        return true;
      }
      final cible = normaliser(
        [
          b.nom,
          b.producteur ?? '',
          b.appellation ?? '',
          b.region ?? '',
          b.millesime?.toString() ?? '',
          b.emplacement.libelle,
        ].join(' '),
      );
      return cible.contains(t);
    }).toList();
    resultat.sort((a, b) {
      if (a.enStock != b.enStock) {
        return a.enStock ? -1 : 1;
      }
      return normaliser(a.nom).compareTo(normaliser(b.nom));
    });
    return resultat;
  }
}
