import 'package:uuid/uuid.dart';

import '../data/depot.dart';
import '../models/lieu.dart';
import 'collection_controller.dart';

/// Lieu et sa profondeur dans l'arbre (0 = premier niveau).
typedef NoeudLieu = ({Lieu lieu, int profondeur});

/// Emplacements personnalisés. Chacun est soit pour les livres, soit pour la
/// cave (`TypeLieu`), jamais les deux ; les deux sortes sont dans la même liste.
class LieuxController extends CollectionController<Lieu> {
  LieuxController(Depot depot) : super(depot, cle);

  static const cle = 'lieux';

  /// Anciennes clés (versions 0.3 à 0.5 : un jeu de lieux par collection),
  /// fusionnées par `fusionnerAnciensLieux`.
  static const ancienneCleLivres = 'lieuxLivres';
  static const ancienneCleCave = 'lieuxCave';

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

  /// Type effectif d'un lieu : celui de son emplacement de premier niveau
  /// (un sous-emplacement suit toujours son parent).
  TypeLieu typeDe(Lieu l) {
    final vus = <String>{};
    var courant = l;
    while (vus.add(courant.id)) {
      final p = _parentDe(courant);
      if (p == null) {
        break;
      }
      courant = parId(p)!;
    }
    return courant.type;
  }

  /// Lieux directement rangés dans [parentId] (null = premier niveau),
  /// triés par nom. [type] : seulement les emplacements de ce type.
  List<Lieu> enfants(String? parentId, {TypeLieu? type}) {
    final liste =
        elements
            .where(
              (l) =>
                  _parentDe(l) == parentId &&
                  (type == null || typeDe(l) == type),
            )
            .toList()
          ..sort((a, b) => normaliser(a.nom).compareTo(normaliser(b.nom)));
    return liste;
  }

  /// Tous les lieux (ou ceux d'un [type]) dans l'ordre d'affichage : chaque
  /// lieu suivi de son contenu, avec sa profondeur.
  List<NoeudLieu> arbre({TypeLieu? type}) {
    final resultat = <NoeudLieu>[];
    final vus = <String>{};
    void parcourir(String? parentId, int profondeur) {
      for (final l in enfants(parentId, type: type)) {
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

  /// Crée un emplacement. Dans un parent, il en prend le type ; sinon
  /// [type] (bibliothèque par défaut).
  Future<Lieu> creer(
    String nom, {
    String? parentId,
    TypeLieu type = TypeLieu.livres,
  }) async {
    final parent = parentId == null ? null : parId(parentId);
    final lieu = Lieu(
      id: const Uuid().v4(),
      nom: nom.trim(),
      parentId: parent?.id,
      type: parent == null ? type : typeDe(parent),
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
    final type = typeDe(lieu);
    for (final enfant in enfants(id)) {
      await enregistrer(
        Lieu(id: enfant.id, nom: enfant.nom, parentId: parent, type: type),
      );
    }
    await super.supprimer(id);
  }
}
