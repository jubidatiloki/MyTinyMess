import '../state/cave_controller.dart';
import '../state/collection_controller.dart';
import '../state/lieux_controller.dart';
import 'depot.dart';

/// Versions 0.3 à 0.5 : les livres et la cave avaient chacun leurs
/// emplacements. Depuis 0.6 ils sont communs : on fusionne les deux jeux.
///
/// - Les emplacements des livres sont gardés tels quels.
/// - Un emplacement de la cave qui porte le même nom, au même endroit, qu'un
///   emplacement existant est fusionné avec lui (les bouteilles suivent).
/// - Les anciennes listes sont ensuite vidées : la fusion n'a lieu qu'une fois.
Future<void> fusionnerAnciensLieux(Depot depot) async {
  final livres = await depot.lire(LieuxController.ancienneCleLivres);
  final cave = await depot.lire(LieuxController.ancienneCleCave);
  if (livres.isEmpty && cave.isEmpty) {
    return;
  }
  final resultat = [...await depot.lire(LieuxController.cle), ...livres];
  final idsCave = {for (final l in cave) l['id'] as String};
  // Ancien id d'un lieu de la cave → id final après fusion.
  final correspondance = <String, String>{};

  var restants = [...cave];
  var progres = true;
  while (restants.isNotEmpty && progres) {
    progres = false;
    final suivants = <Map<String, dynamic>>[];
    for (final l in restants) {
      final parentAncien = l['parentId'] as String?;
      // Les parents d'abord : on attend que le parent soit traité.
      if (parentAncien != null &&
          idsCave.contains(parentAncien) &&
          !correspondance.containsKey(parentAncien)) {
        suivants.add(l);
        continue;
      }
      final parent = parentAncien == null
          ? null
          : (correspondance[parentAncien] ?? parentAncien);
      final nom = normaliser(l['nom'] as String? ?? '');
      final identique = resultat.where(
        (r) =>
            r['parentId'] == parent &&
            normaliser(r['nom'] as String? ?? '') == nom,
      );
      final id = l['id'] as String;
      if (identique.isNotEmpty) {
        correspondance[id] = identique.first['id'] as String;
      } else {
        resultat.add({'id': id, 'nom': l['nom'], 'parentId': ?parent});
        correspondance[id] = id;
      }
      progres = true;
    }
    restants = suivants;
  }
  // Cas anormal (boucle de parents) : gardés tels quels.
  for (final l in restants) {
    resultat.add(l);
    correspondance[l['id'] as String] = l['id'] as String;
  }

  final bouteilles = await depot.lire(CaveController.cle);
  final bouteillesMaj = [
    for (final b in bouteilles) _rattacher(b, correspondance),
  ];

  await depot.ecrire(LieuxController.cle, resultat);
  await depot.ecrire(CaveController.cle, bouteillesMaj);
  await depot.ecrire(LieuxController.ancienneCleLivres, []);
  await depot.ecrire(LieuxController.ancienneCleCave, []);
}

Map<String, dynamic> _rattacher(
  Map<String, dynamic> bouteille,
  Map<String, String> correspondance,
) {
  final emplacement = (bouteille['emplacement'] as Map?)
      ?.cast<String, dynamic>();
  final lieuId = emplacement?['lieuId'] as String?;
  final nouveau = lieuId == null ? null : correspondance[lieuId];
  if (emplacement == null || nouveau == null || nouveau == lieuId) {
    return bouteille;
  }
  return {
    ...bouteille,
    'emplacement': {...emplacement, 'lieuId': nouveau},
  };
}
