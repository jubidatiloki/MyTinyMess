import 'package:uuid/uuid.dart';

import '../models/lieu.dart';
import '../state/bibliotheque_controller.dart';
import '../state/cave_controller.dart';
import '../state/lieux_controller.dart';
import 'depot.dart';

/// Versions 0.3 à 0.5 : les livres et la cave avaient chacun leur liste
/// d'emplacements (clés `lieuxLivres` / `lieuxCave`). Elles sont réunies dans
/// la liste unique `lieux`, chaque emplacement gardant son type d'origine.
/// Les anciennes listes sont ensuite vidées : ne se fait qu'une fois.
Future<void> fusionnerAnciensLieux(Depot depot) async {
  final livres = await depot.lire(LieuxController.ancienneCleLivres);
  final cave = await depot.lire(LieuxController.ancienneCleCave);
  if (livres.isEmpty && cave.isEmpty) {
    return;
  }
  await depot.ecrire(LieuxController.cle, [
    ...await depot.lire(LieuxController.cle),
    for (final l in livres) {...l, 'type': TypeLieu.livres.name},
    for (final l in cave) {...l, 'type': TypeLieu.cave.name},
  ]);
  await depot.ecrire(LieuxController.ancienneCleLivres, []);
  await depot.ecrire(LieuxController.ancienneCleCave, []);
}

/// Version 0.6 : les emplacements n'avaient pas de type (communs aux livres
/// et à la cave). Chaque arbre d'emplacements reçoit le type de ce qu'il
/// contient :
/// - seulement des bouteilles → cave ;
/// - des livres, ou rien → bibliothèque ;
/// - les deux → l'arbre est dédoublé : l'original reste à la bibliothèque,
///   une copie (mêmes noms) va à la cave et les bouteilles y sont rangées.
Future<void> typerLieux(Depot depot) async {
  final lieux = await depot.lire(LieuxController.cle);
  if (lieux.every((l) => l['type'] != null)) {
    return;
  }
  final parId = {for (final l in lieux) l['id'] as String: l};
  String racineDe(String id) {
    final vus = <String>{};
    var courant = id;
    while (vus.add(courant)) {
      final p = parId[courant]?['parentId'] as String?;
      if (p == null || !parId.containsKey(p)) {
        break;
      }
      courant = p;
    }
    return courant;
  }

  final livres = await depot.lire(BibliothequeController.cle);
  final bouteilles = await depot.lire(CaveController.cle);
  String? lieuDeBouteille(Map<String, dynamic> b) =>
      (b['emplacement'] as Map?)?['lieuId'] as String?;

  final racinesAvecLivres = {
    for (final l in livres)
      if (parId.containsKey(l['lieuId'])) racineDe(l['lieuId'] as String),
  };
  final racinesAvecBouteilles = {
    for (final b in bouteilles)
      if (parId.containsKey(lieuDeBouteille(b))) racineDe(lieuDeBouteille(b)!),
  };

  final resultat = <Map<String, dynamic>>[];
  // Ancien id → id de la copie « cave » (arbres qui contenaient les deux).
  final copies = <String, String>{};
  for (final l in lieux) {
    if (l['type'] != null) {
      resultat.add(l);
      continue;
    }
    final racine = racineDe(l['id'] as String);
    final avecLivres = racinesAvecLivres.contains(racine);
    final avecBouteilles = racinesAvecBouteilles.contains(racine);
    if (avecBouteilles && !avecLivres) {
      resultat.add({...l, 'type': TypeLieu.cave.name});
    } else {
      resultat.add({...l, 'type': TypeLieu.livres.name});
      if (avecBouteilles) {
        copies[l['id'] as String] = const Uuid().v4();
      }
    }
  }
  for (final entree in copies.entries) {
    final original = parId[entree.key]!;
    final parent = original['parentId'] as String?;
    resultat.add({
      'id': entree.value,
      'nom': original['nom'],
      'parentId': ?copies[parent],
      'type': TypeLieu.cave.name,
    });
  }

  await depot.ecrire(LieuxController.cle, resultat);
  if (copies.isNotEmpty) {
    await depot.ecrire(CaveController.cle, [
      for (final b in bouteilles)
        if (copies.containsKey(lieuDeBouteille(b)))
          {
            ...b,
            'emplacement': {
              ...(b['emplacement'] as Map).cast<String, dynamic>(),
              'lieuId': copies[lieuDeBouteille(b)],
            },
          }
        else
          b,
    ]);
  }
}
