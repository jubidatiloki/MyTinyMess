import '../data/depot.dart';
import '../models/aliment.dart';
import '../models/unite.dart';
import 'categories_controller.dart';
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
  FrigoController(
    Depot depot, {
    this.lieux,
    this.categories,
    DateTime Function()? maintenant,
  }) : _maintenant = maintenant ?? DateTime.now,
       super(depot, cle);

  static const cle = 'aliments';

  /// Emplacements (ceux de type frigo).
  LieuxController? lieux;

  /// Catégories d'aliments (liste paramétrable).
  final CategoriesController? categories;
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

  int get nombreEpuises => elements.where((a) => !a.enStock).length;

  /// Unités proposées, plus celles déjà saisies.
  List<String> get unites {
    final liste = [...unitesProposees];
    for (final a in elements) {
      final u = a.unite;
      if (u != null && !liste.any((x) => normaliser(x) == normaliser(u))) {
        liste.add(u);
      }
    }
    return liste..sort((a, b) => normaliser(a).compareTo(normaliser(b)));
  }

  /// Variantes déjà saisies pour un aliment de ce nom (pour les proposer).
  List<String> variantesDe(String nom) {
    final n = normaliser(nom.trim());
    final vues = <String, String>{};
    for (final a in elements) {
      final v = a.variante;
      if (v != null && n.isNotEmpty && normaliser(a.nom) == n) {
        vues.putIfAbsent(normaliser(v), () => v);
      }
    }
    return vues.values.toList()
      ..sort((a, b) => normaliser(a).compareTo(normaliser(b)));
  }

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

  /// Aliments d'une catégorie (accents et majuscules ignorés).
  Iterable<Aliment> dansCategorie(String nom) => elements.where(
    (a) => normaliser((a.categorie ?? '').trim()) == normaliser(nom.trim()),
  );

  Future<void> renommerCategorie(String ancien, String nouveau) async {
    for (final a in dansCategorie(ancien).toList()) {
      await enregistrer(a.avecCategorie(nouveau));
    }
  }

  /// Catégories saisies librement avant la version 0.12 : ajoutées à la
  /// liste si elles n'y sont pas, pour n'en perdre aucune.
  Future<void> reprendreCategories() async {
    final liste = categories;
    if (liste == null) {
      return;
    }
    for (final a in elements.toList()) {
      final nom = a.categorie?.trim() ?? '';
      if (nom.isEmpty) {
        continue;
      }
      final c = liste.parNom(nom) ?? await liste.creer(nom);
      if (c.nom != a.categorie) {
        await enregistrer(a.avecCategorie(c.nom));
      }
    }
  }

  String? emplacementDe(Aliment a) => lieux?.chemin(a.lieuId);

  Future<void> ajouterUn(String id) => _changer(id, 1);
  Future<void> retirerUn(String id) => _changer(id, -1);

  /// Nouvelle quantité (jamais négative ; 0 = épuisé).
  /// [niveau] : ce qu'il reste de l'unité entamée (null = pleine).
  Future<void> changerQuantite(String id, int quantite, {int? niveau}) async {
    final a = parId(id);
    if (a != null) {
      await enregistrer(
        a.avecQuantite(quantite, niveau: niveau, changerNiveau: true),
      );
    }
  }

  Future<void> _changer(String id, int delta) {
    final a = parId(id);
    if (a == null) {
      throw StateError('Aliment introuvable : $id');
    }
    // Une unité retirée (finie) : la suivante est pleine.
    return enregistrer(
      a.avecQuantite(a.quantite + delta, changerNiveau: delta < 0),
    );
  }

  /// Aliments selon la recherche, le filtre et l'emplacement ; ceux qui
  /// périment le plus tôt d'abord (sans date à la fin), épuisés en dernier.
  /// [epuises] faux : ils sont cachés (sauf avec le filtre « Épuisés »).
  List<Aliment> rechercher({
    String texte = '',
    FiltreAliments filtre = FiltreAliments.tous,
    String? lieuId,
    String? categorie,
    bool epuises = true,
  }) {
    final t = normaliser(texte.trim());
    final dansLieu = lieuId == null
        ? null
        : (lieux?.descendantsEtSoi(lieuId) ?? {lieuId});
    final resultat = elements.where((a) {
      final etat = etatDe(a);
      final garde = switch (filtre) {
        FiltreAliments.tous => epuises || a.enStock,
        FiltreAliments.bientot => a.enStock && etat == EtatPeremption.bientot,
        FiltreAliments.perimes => a.enStock && etat == EtatPeremption.perime,
        FiltreAliments.epuises => !a.enStock,
      };
      if (!garde) {
        return false;
      }
      if (categorie != null &&
          normaliser(a.categorie ?? '') != normaliser(categorie)) {
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
          a.variante ?? '',
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
