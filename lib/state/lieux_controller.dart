import 'package:uuid/uuid.dart';

import '../models/lieu.dart';
import 'collection_controller.dart';

/// Lieu et sa profondeur dans l'arbre (0 = premier niveau).
typedef NoeudLieu = ({Lieu lieu, int profondeur});

/// Emplacements personnalisés d'une collection (livres ou cave).
class LieuxController extends CollectionController<Lieu> {
  LieuxController(super.depot, super.cle);

  static const cleLivres = 'lieuxLivres';
  static const cleCave = 'lieuxCave';

  @override
  Lieu depuisJson(Map<String, dynamic> json) => Lieu.fromJson(json);
  @override
  Map<String, dynamic> versJson(Lieu element) => element.toJson();
  @override
  String idDe(Lieu element) => element.id;

  /// Parent existant du lieu (un parent supprimé compte comme « aucun »).
  String? _parentDe(Lieu l) =>
      l.parentId != null && parId(l.parentId!) != null ? l.parentId : null;

  /// « Salon › Grande bibliothèque › Étagère 3 », ou null si inconnu.
  String? chemin(String? id) {
    if (id == null) {
      return null;
    }
    final noms = <String>[];
    final vus = <String>{};
    var courant = parId(id);
    while (courant != null && vus.add(courant.id)) {
      noms.insert(0, courant.nom);
      final p = _parentDe(courant);
      courant = p == null ? null : parId(p);
    }
    return noms.isEmpty ? null : noms.join(' › ');
  }

  /// Lieux directement rangés dans [parentId] (null = premier niveau),
  /// triés par nom.
  List<Lieu> enfants(String? parentId) {
    final liste = elements.where((l) => _parentDe(l) == parentId).toList()
      ..sort((a, b) => normaliser(a.nom).compareTo(normaliser(b.nom)));
    return liste;
  }

  /// Tous les lieux dans l'ordre d'affichage (chaque lieu suivi de son
  /// contenu), avec leur profondeur.
  List<NoeudLieu> arbre() {
    final resultat = <NoeudLieu>[];
    final vus = <String>{};
    void parcourir(String? parentId, int profondeur) {
      for (final l in enfants(parentId)) {
        if (vus.add(l.id)) {
          resultat.add((lieu: l, profondeur: profondeur));
          parcourir(l.id, profondeur + 1);
        }
      }
    }

    parcourir(null, 0);
    return resultat;
  }

  /// Le lieu et tout ce qu'il contient (pour filtrer « dans ce lieu »).
  Set<String> descendantsEtSoi(String id) {
    final resultat = <String>{id};
    var ajoute = true;
    while (ajoute) {
      ajoute = false;
      for (final l in elements) {
        final p = _parentDe(l);
        if (p != null && resultat.contains(p) && resultat.add(l.id)) {
          ajoute = true;
        }
      }
    }
    return resultat;
  }

  Future<Lieu> creer(String nom, {String? parentId}) async {
    final lieu = Lieu(
      id: const Uuid().v4(),
      nom: nom.trim(),
      parentId: parentId,
    );
    await enregistrer(lieu);
    return lieu;
  }

  /// Supprime un lieu : ce qu'il contient remonte d'un niveau.
  /// Les livres / bouteilles qui y étaient n'ont plus d'emplacement.
  @override
  Future<void> supprimer(String id) async {
    final lieu = parId(id);
    if (lieu == null) {
      return;
    }
    final parent = _parentDe(lieu);
    for (final enfant in enfants(id)) {
      await enregistrer(Lieu(id: enfant.id, nom: enfant.nom, parentId: parent));
    }
    await super.supprimer(id);
  }
}
