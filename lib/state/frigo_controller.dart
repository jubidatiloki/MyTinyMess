import '../data/depot.dart';
import '../models/aliment.dart';
import 'collection_controller.dart';
import 'lieux_controller.dart';

enum FiltreAliments {
  tous('Tous'),
  bientot('À consommer bientôt'),
  perimes('Périmés'),
  epuises('Épuisés');

  const FiltreAliments(this.libelle);
  final String libelle;
}

/// Le frigo : aliments, quantités et dates de péremption.
class FrigoController extends CollectionController<Aliment> {
  FrigoController(Depot depot, {this.lieux, DateTime Function()? maintenant})
    : _maintenant = maintenant ?? DateTime.now,
      super(depot, cle);

  static const cle = 'aliments';

  /// Emplacements (ceux de type frigo).
  LieuxController? lieux;
  final DateTime Function() _maintenant;

  DateTime get aujourdhui => _maintenant();

  @override
  Aliment depuisJson(Map<String, dynamic> json) => Aliment.fromJson(json);
  @override
  Map<String, dynamic> versJson(Aliment element) => element.toJson();
  @override
  String idDe(Aliment element) => element.id;

  EtatPeremption etatDe(Aliment a) => a.etat(aujourdhui);

  /// Nombre d'unités en stock (tous aliments confondus).
  int get nombreArticles => elements.fold(0, (s, a) => s + a.quantite);

  /// Aliments en stock périmés ou à consommer bientôt.
  int get nombreASurveiller => elements
      .where(
        (a) =>
            a.enStock &&
            (etatDe(a) == EtatPeremption.bientot ||
                etatDe(a) == EtatPeremption.perime),
      )
      .length;

  /// Unités dans ce lieu, sous-emplacements compris.
  int nombreDans(String lieuId) {
    final dedans = lieux?.descendantsEtSoi(lieuId) ?? {lieuId};
    return elements
        .where((a) => dedans.contains(a.lieuId))
        .fold(0, (s, a) => s + a.quantite);
  }

  String? emplacementDe(Aliment a) => lieux?.chemin(a.lieuId);

  Future<void> ajouterUn(String id) => _changer(id, 1);
  Future<void> retirerUn(String id) => _changer(id, -1);

  Future<void> _changer(String id, int delta) {
    final a = parId(id);
    if (a == null) {
      throw StateError('Aliment introuvable : $id');
    }
    return enregistrer(a.avecQuantite(a.quantite + delta));
  }

  /// Aliments selon la recherche, le filtre et l'emplacement ; ceux qui
  /// périment le plus tôt d'abord (sans date à la fin), épuisés en dernier.
  List<Aliment> rechercher({
    String texte = '',
    FiltreAliments filtre = FiltreAliments.tous,
    String? lieuId,
  }) {
    final t = normaliser(texte.trim());
    final dansLieu = lieuId == null
        ? null
        : (lieux?.descendantsEtSoi(lieuId) ?? {lieuId});
    final resultat = elements.where((a) {
      final etat = etatDe(a);
      final garde = switch (filtre) {
        FiltreAliments.tous => true,
        FiltreAliments.bientot => a.enStock && etat == EtatPeremption.bientot,
        FiltreAliments.perimes => a.enStock && etat == EtatPeremption.perime,
        FiltreAliments.epuises => !a.enStock,
      };
      if (!garde) {
        return false;
      }
      if (dansLieu != null && !dansLieu.contains(a.lieuId)) {
        return false;
      }
      if (t.isEmpty) {
        return true;
      }
      return normaliser(
        [
          a.nom,
          a.categorie ?? '',
          a.contenance ?? '',
          emplacementDe(a) ?? '',
        ].join(' '),
      ).contains(t);
    }).toList();
    resultat.sort((a, b) {
      if (a.enStock != b.enStock) {
        return a.enStock ? -1 : 1;
      }
      final da = a.datePeremption;
      final db = b.datePeremption;
      if (da != null && db != null && da != db) {
        return da.compareTo(db);
      }
      if ((da == null) != (db == null)) {
        return da == null ? 1 : -1;
      }
      return normaliser(a.nom).compareTo(normaliser(b.nom));
    });
    return resultat;
  }
}
