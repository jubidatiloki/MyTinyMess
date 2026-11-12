import '../data/depot.dart';
import '../models/bouteille.dart';
import 'collection_controller.dart';
import 'lieux_controller.dart';

class CaveController extends CollectionController<Bouteille> {
  CaveController(Depot depot, {this.lieux}) : super(depot, cle);

  static const cle = 'bouteilles';

  /// Emplacements personnalisés de la cave.
  LieuxController? lieux;

  @override
  Bouteille depuisJson(Map<String, dynamic> json) => Bouteille.fromJson(json);
  @override
  Map<String, dynamic> versJson(Bouteille element) => element.toJson();
  @override
  String idDe(Bouteille element) => element.id;

  /// Nombre total de bouteilles dans la cave.
  int get totalBouteilles => elements.fold(0, (s, b) => s + b.quantite);

  /// Nombre de bouteilles rangées directement dans ce lieu.
  int nombreDans(String lieuId) => elements
      .where((b) => b.emplacement.lieuId == lieuId)
      .fold(0, (s, b) => s + b.quantite);

  /// « Cave › Casier A · rangée 2 » (vide si rien n'est précisé).
  String emplacementDe(Bouteille b) =>
      b.emplacement.libelle(lieux?.chemin(b.emplacement.lieuId));

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

  /// Transforme les zones saisies en texte libre (versions ≤ 0.2) en lieux
  /// personnalisés : une zone = un lieu de premier niveau, réutilisé s'il
  /// existe déjà sous ce nom.
  Future<void> migrerZones() async {
    final l = lieux;
    if (l == null) {
      return;
    }
    for (final b in elements) {
      final zone = b.emplacement.ancienneZone;
      if (zone == null || b.emplacement.lieuId != null) {
        continue;
      }
      final existant = l
          .enfants(null)
          .where((x) => normaliser(x.nom) == normaliser(zone));
      final lieu = existant.isNotEmpty ? existant.first : await l.creer(zone);
      await enregistrer(b.avecEmplacement(b.emplacement.avecLieu(lieu.id)));
    }
  }

  /// Bouteilles correspondant à la recherche (nom, appellation, région,
  /// emplacement…), au type et à l'emplacement ([lieuId] : ce lieu et tout
  /// ce qu'il contient). Celles en stock d'abord, puis par nom.
  List<Bouteille> rechercher({
    String texte = '',
    TypeVin? type,
    bool seulementEnStock = false,
    String? lieuId,
  }) {
    final t = normaliser(texte.trim());
    final dansLieu = lieuId == null
        ? null
        : (lieux?.descendantsEtSoi(lieuId) ?? {lieuId});
    final resultat = elements.where((b) {
      if (type != null && b.type != type) {
        return false;
      }
      if (seulementEnStock && !b.enStock) {
        return false;
      }
      if (dansLieu != null && !dansLieu.contains(b.emplacement.lieuId)) {
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
          emplacementDe(b),
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
