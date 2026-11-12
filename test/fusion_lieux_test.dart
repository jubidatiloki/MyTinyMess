import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/data/fusion_lieux.dart';
import 'package:my_tiny_mess/models/lieu.dart';
import 'package:my_tiny_mess/state/bibliotheque_controller.dart';
import 'package:my_tiny_mess/state/cave_controller.dart';
import 'package:my_tiny_mess/state/lieux_controller.dart';

void main() {
  test('≤ 0.5 : les deux listes réunies, chacune gardant son type', () async {
    final depot = DepotMemoire();
    await depot.ecrire(LieuxController.ancienneCleLivres, [
      {'id': 'L-salon', 'nom': 'Salon'},
      {'id': 'L-etagere', 'nom': 'Étagère', 'parentId': 'L-salon'},
    ]);
    await depot.ecrire(LieuxController.ancienneCleCave, [
      // Même nom que côté livres : reste un emplacement à part (cave).
      {'id': 'C-salon', 'nom': 'Salon'},
      {'id': 'C-buffet', 'nom': 'Buffet', 'parentId': 'C-salon'},
    ]);

    await fusionnerAnciensLieux(depot);

    final lieux = LieuxController(depot);
    await lieux.charger();
    String noms(TypeLieu t) => lieux
        .arbre(type: t)
        .map((n) => '${n.profondeur}:${n.lieu.nom}')
        .join(', ');
    expect(noms(TypeLieu.livres), '0:Salon, 1:Étagère');
    expect(noms(TypeLieu.cave), '0:Salon, 1:Buffet');
    // Anciennes listes vidées : une seconde fusion ne change rien.
    expect(await depot.lire(LieuxController.ancienneCleCave), isEmpty);
    await fusionnerAnciensLieux(depot);
    expect(await depot.lire(LieuxController.cle), hasLength(4));
  });

  test('0.6 : type donné selon le contenu, dédoublé si mélangé', () async {
    final depot = DepotMemoire();
    await depot.ecrire(LieuxController.cle, [
      {'id': 'salon', 'nom': 'Salon'},
      {'id': 'etagere', 'nom': 'Étagère', 'parentId': 'salon'},
      {'id': 'cellier', 'nom': 'Cellier'},
      {'id': 'garage', 'nom': 'Garage'},
    ]);
    await depot.ecrire(BibliothequeController.cle, [
      {'id': 'l1', 'titre': 'Dune', 'lieuId': 'etagere'},
    ]);
    await depot.ecrire(CaveController.cle, [
      {
        'id': 'b1',
        'nom': 'Chinon',
        'emplacement': {'lieuId': 'cellier'},
      },
      {
        'id': 'b2',
        'nom': 'Vouvray',
        'emplacement': {'lieuId': 'etagere', 'rangee': '2'},
      },
    ]);

    await typerLieux(depot);

    final lieux = LieuxController(depot);
    await lieux.charger();
    expect(lieux.typeDe(lieux.parId('cellier')!), TypeLieu.cave);
    expect(lieux.typeDe(lieux.parId('garage')!), TypeLieu.livres); // vide
    expect(lieux.typeDe(lieux.parId('etagere')!), TypeLieu.livres);
    // Le salon contenait livres ET bouteilles : copie côté cave.
    expect(
      lieux.arbre(type: TypeLieu.cave).map((n) => lieux.chemin(n.lieu.id)),
      ['Cellier', 'Salon', 'Salon › Étagère'],
    );
    final b2 = (await depot.lire(CaveController.cle))[1];
    final lieuB2 = lieux.parId(b2['emplacement']['lieuId'] as String)!;
    expect(lieux.typeDe(lieuB2), TypeLieu.cave);
    expect(lieux.chemin(lieuB2.id), 'Salon › Étagère');
    expect(b2['emplacement']['rangee'], '2');
    // Le livre reste dans l'emplacement d'origine.
    expect(
      (await depot.lire(BibliothequeController.cle)).single['lieuId'],
      'etagere',
    );

    // Une seconde fois : tout est déjà typé, rien ne change.
    final avant = await depot.lire(LieuxController.cle);
    await typerLieux(depot);
    expect(await depot.lire(LieuxController.cle), avant);
  });
}
