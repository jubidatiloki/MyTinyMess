import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/data/fusion_lieux.dart';
import 'package:my_tiny_mess/state/cave_controller.dart';
import 'package:my_tiny_mess/state/lieux_controller.dart';

void main() {
  test('fusion des emplacements des livres et de la cave (≤ 0.5)', () async {
    final depot = DepotMemoire();
    await depot.ecrire(LieuxController.ancienneCleLivres, [
      {'id': 'L-salon', 'nom': 'Salon'},
      {'id': 'L-etagere', 'nom': 'Étagère', 'parentId': 'L-salon'},
    ]);
    await depot.ecrire(LieuxController.ancienneCleCave, [
      // Même nom au même endroit que côté livres : fusionnés.
      {'id': 'C-salon', 'nom': 'salon'},
      {'id': 'C-buffet', 'nom': 'Buffet', 'parentId': 'C-salon'},
      {'id': 'C-cellier', 'nom': 'Cellier'},
    ]);
    await depot.ecrire(CaveController.cle, [
      {
        'id': 'b1',
        'nom': 'Chinon',
        'emplacement': {'lieuId': 'C-salon', 'rangee': '2'},
      },
      {
        'id': 'b2',
        'nom': 'Vouvray',
        'emplacement': {'lieuId': 'C-buffet'},
      },
    ]);

    await fusionnerAnciensLieux(depot);

    final lieux = LieuxController(depot);
    await lieux.charger();
    expect(lieux.arbre().map((n) => '${n.profondeur}:${n.lieu.nom}'), [
      '0:Cellier',
      '0:Salon',
      '1:Buffet',
      '1:Étagère',
    ]);
    final bouteilles = await depot.lire(CaveController.cle);
    expect(bouteilles[0]['emplacement'], {'lieuId': 'L-salon', 'rangee': '2'});
    expect(
      lieux.chemin(bouteilles[1]['emplacement']['lieuId'] as String),
      'Salon › Buffet',
    );
    // Anciennes listes vidées : une seconde fusion ne change rien.
    expect(await depot.lire(LieuxController.ancienneCleCave), isEmpty);
    await fusionnerAnciensLieux(depot);
    expect((await depot.lire(LieuxController.cle)), hasLength(4));
  });

  test('rien à fusionner : rien ne change', () async {
    final depot = DepotMemoire();
    await depot.ecrire(LieuxController.cle, [
      {'id': 'x', 'nom': 'Bureau'},
    ]);
    await fusionnerAnciensLieux(depot);
    expect(await depot.lire(LieuxController.cle), [
      {'id': 'x', 'nom': 'Bureau'},
    ]);
  });
}
