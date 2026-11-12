import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/data/depot_base.dart';
import 'package:my_tiny_mess/models/livre.dart';
import 'package:my_tiny_mess/state/bibliotheque_controller.dart';
import 'package:my_tiny_mess/state/lieux_controller.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late DatabaseFactory fabrique;

  setUp(() => fabrique = newDatabaseFactoryMemory());

  Future<DepotBase> ouvrir() async =>
      DepotBase(await fabrique.openDatabase('test.db'));

  test('écrit, relit dans l\'ordre et supprime ce qui a disparu', () async {
    final depot = await ouvrir();
    await depot.ecrire('livres', [
      {'id': 'z', 'titre': 'Zadig'},
      {'id': 'a', 'titre': 'Antigone'},
      {'id': 'm', 'titre': 'Madame Bovary'},
    ]);
    expect((await depot.lire('livres')).map((e) => e['titre']), [
      'Zadig',
      'Antigone',
      'Madame Bovary',
    ]);

    await depot.ecrire('livres', [
      {'id': 'm', 'titre': 'Madame Bovary', 'note': 4},
      {'id': 'z', 'titre': 'Zadig'},
    ]);
    final relu = await depot.lire('livres');
    expect(relu.map((e) => e['id']), ['m', 'z']);
    expect(relu.first['note'], 4);
    expect(relu.first.containsKey('_ordre'), isFalse);
    expect(await depot.lire('inconnu'), isEmpty);
  });

  test('les données restent après fermeture et réouverture', () async {
    final depot = await ouvrir();
    await depot.ecrire('bouteilles', [
      {
        'id': 'b1',
        'nom': 'Chinon',
        'mouvements': [
          {'date': '2026-01-02T00:00:00.000', 'quantite': 3},
        ],
      },
    ]);
    // Sans id (préférences) : enregistrées quand même.
    await depot.ecrire('preferences', [
      {'theme': 'clair'},
    ]);

    final rouvert = await ouvrir();
    final b = (await rouvert.lire('bouteilles')).single;
    expect(b['nom'], 'Chinon');
    expect((b['mouvements'] as List).single['quantite'], 3);
    expect((await rouvert.lire('preferences')).single['theme'], 'clair');
  });

  test('les contrôleurs fonctionnent sur la base', () async {
    final depot = await ouvrir();
    final lieux = LieuxController(depot, LieuxController.cleLivres);
    await lieux.charger();
    final salon = await lieux.creer('Salon');
    final biblio = BibliothequeController(depot, lieux: lieux);
    await biblio.charger();
    await biblio.enregistrer(Livre(id: '1', titre: 'Dune', lieuId: salon.id));
    await biblio.supprimer('1');
    await biblio.enregistrer(const Livre(id: '2', titre: 'Zadig'));

    final autre = BibliothequeController(await ouvrir());
    await autre.charger();
    expect(autre.elements.single.titre, 'Zadig');
    final autresLieux = LieuxController(
      await ouvrir(),
      LieuxController.cleLivres,
    );
    await autresLieux.charger();
    expect(autresLieux.chemin(salon.id), 'Salon');
  });

  test('reprise unique des données de l\'ancien stockage', () async {
    final ancien = DepotMemoire();
    await ancien.ecrire('livres', [
      {'id': '1', 'titre': 'Dune'},
    ]);
    await ancien.ecrire('preferences', [
      {'theme': 'clair'},
    ]);
    final depot = await ouvrir();
    // Déjà quelque chose dans la base pour les bouteilles : pas écrasé.
    await depot.ecrire('bouteilles', [
      {'id': 'b', 'nom': 'Chinon'},
    ]);
    await ancien.ecrire('bouteilles', [
      {'id': 'x', 'nom': 'Ancienne'},
    ]);

    final repris = await depot.reprendreDepuis(ancien, [
      'livres',
      'bouteilles',
      'preferences',
    ]);
    expect(repris, 2);
    expect((await depot.lire('livres')).single['titre'], 'Dune');
    expect((await depot.lire('bouteilles')).single['nom'], 'Chinon');

    // Une seconde fois : rien n'est repris (même si la base a été vidée).
    await depot.ecrire('livres', []);
    expect(await depot.reprendreDepuis(ancien, ['livres']), 0);
    expect(await depot.lire('livres'), isEmpty);
  });
}
