import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/models/bouteille.dart';
import 'package:my_tiny_mess/models/livre.dart';
import 'package:my_tiny_mess/state/bibliotheque_controller.dart';
import 'package:my_tiny_mess/state/cave_controller.dart';
import 'package:my_tiny_mess/state/lieux_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LieuxController', () {
    late DepotMemoire depot;
    late LieuxController lieux;
    late String salon, biblio, etagere, cave;

    setUp(() async {
      depot = DepotMemoire();
      lieux = LieuxController(depot, LieuxController.cleLivres);
      await lieux.charger();
      salon = (await lieux.creer('Salon')).id;
      biblio = (await lieux.creer('Grande bibliothèque', parentId: salon)).id;
      etagere = (await lieux.creer('Étagère 1', parentId: biblio)).id;
      cave = (await lieux.creer('Bureau')).id;
    });

    test('chemin complet et arbre trié', () {
      expect(lieux.chemin(etagere), 'Salon › Grande bibliothèque › Étagère 1');
      expect(lieux.chemin(null), isNull);
      expect(lieux.chemin('inconnu'), isNull);
      expect(lieux.arbre().map((n) => '${n.profondeur}:${n.lieu.nom}'), [
        '0:Bureau',
        '0:Salon',
        '1:Grande bibliothèque',
        '2:Étagère 1',
      ]);
    });

    test('contenu d\'un lieu (pour filtrer)', () {
      expect(lieux.descendantsEtSoi(salon), {salon, biblio, etagere});
      expect(lieux.descendantsEtSoi(cave), {cave});
    });

    test('supprimer : le contenu remonte d\'un niveau', () async {
      await lieux.supprimer(biblio);
      expect(lieux.chemin(etagere), 'Salon › Étagère 1');
      expect(lieux.elements, hasLength(3));
    });

    test('gardés après redémarrage', () async {
      final autre = LieuxController(depot, LieuxController.cleLivres);
      await autre.charger();
      expect(autre.chemin(etagere), 'Salon › Grande bibliothèque › Étagère 1');
      // Les lieux de la cave sont séparés de ceux des livres.
      final caveLieux = LieuxController(depot, LieuxController.cleCave);
      await caveLieux.charger();
      expect(caveLieux.elements, isEmpty);
    });

    test('filtre et recherche des livres par emplacement', () async {
      final biblioCtrl = BibliothequeController(depot, lieux: lieux);
      await biblioCtrl.charger();
      await biblioCtrl.enregistrer(
        Livre(id: '1', titre: 'Dune', lieuId: etagere),
      );
      await biblioCtrl.enregistrer(
        Livre(id: '2', titre: 'Zadig', lieuId: cave),
      );
      await biblioCtrl.enregistrer(const Livre(id: '3', titre: 'Sans place'));
      expect(biblioCtrl.rechercher(lieuId: salon).single.titre, 'Dune');
      expect(biblioCtrl.rechercher(lieuId: cave).single.titre, 'Zadig');
      expect(biblioCtrl.rechercher(texte: 'etagere').single.titre, 'Dune');
      expect(biblioCtrl.nombreDans(etagere), 1);
      expect(
        biblioCtrl.emplacementDe(biblioCtrl.parId('1')!),
        'Salon › Grande bibliothèque › Étagère 1',
      );
    });
  });

  group('BibliothequeController', () {
    late DepotMemoire depot;
    late BibliothequeController ctrl;

    setUp(() async {
      depot = DepotMemoire();
      ctrl = BibliothequeController(depot);
      await ctrl.charger();
      await ctrl.enregistrer(
        const Livre(id: '1', titre: 'Zadig', auteur: 'Voltaire'),
      );
      await ctrl.enregistrer(
        const Livre(
          id: '2',
          titre: 'Les Misérables',
          auteur: 'Hugo',
          statut: StatutLecture.lu,
        ).preter('Julie'),
      );
    });

    test('les livres sont gardés après redémarrage', () async {
      final autre = BibliothequeController(depot);
      await autre.charger();
      expect(autre.elements.map((l) => l.titre), ['Zadig', 'Les Misérables']);
    });

    test('modifier remplace le livre existant', () async {
      await ctrl.enregistrer(ctrl.parId('1')!.avecStatut(StatutLecture.lu));
      expect(ctrl.elements, hasLength(2));
      expect(ctrl.parId('1')!.statut, StatutLecture.lu);
    });

    test('supprimer', () async {
      await ctrl.supprimer('1');
      expect(ctrl.elements.map((l) => l.id), ['2']);
    });

    test('recherche sans accents, triée par titre', () {
      expect(ctrl.rechercher(texte: 'miserables').single.id, '2');
      expect(ctrl.rechercher(texte: 'julie').single.id, '2');
      expect(ctrl.rechercher().map((l) => l.titre), [
        'Les Misérables',
        'Zadig',
      ]);
    });

    test('filtres', () {
      expect(ctrl.rechercher(filtre: FiltreLivres.pretes).single.id, '2');
      expect(ctrl.rechercher(filtre: FiltreLivres.aLire).single.id, '1');
      expect(ctrl.rechercher(filtre: FiltreLivres.empruntes), isEmpty);
    });
  });

  group('CaveController', () {
    late CaveController ctrl;
    late LieuxController lieux;
    late String casier, fond;

    setUp(() async {
      final depot = DepotMemoire();
      lieux = LieuxController(depot, LieuxController.cleCave);
      await lieux.charger();
      casier = (await lieux.creer('Casier')).id;
      fond = (await lieux.creer('Cave du fond')).id;
      ctrl = CaveController(depot, lieux: lieux);
      await ctrl.charger();
      await ctrl.enregistrer(
        Bouteille(
          id: 'a',
          nom: 'Sancerre',
          type: TypeVin.blanc,
          emplacement: Emplacement(lieuId: casier, rangee: '1'),
        ).ajouter(3),
      );
      await ctrl.enregistrer(
        Bouteille(
          id: 'b',
          nom: 'Bordeaux',
          emplacement: Emplacement(lieuId: fond),
        ),
      );
    });

    test('libellé et filtre par emplacement', () {
      expect(ctrl.emplacementDe(ctrl.parId('a')!), 'Casier · rangée 1');
      expect(ctrl.rechercher(lieuId: casier).single.id, 'a');
      expect(ctrl.nombreDans(casier), 3);
    });

    test('anciennes zones (0.2) transformées en lieux', () async {
      final depot = DepotMemoire();
      await depot.ecrire(CaveController.cle, [
        {
          'id': 'x',
          'nom': 'Chinon',
          'quantite': 2,
          'emplacement': {'zone': 'Cellier', 'rangee': '3'},
        },
        {
          'id': 'y',
          'nom': 'Vouvray',
          'emplacement': {'zone': 'cellier'},
        },
      ]);
      final l = LieuxController(depot, LieuxController.cleCave);
      await l.charger();
      final c = CaveController(depot, lieux: l);
      await c.charger();
      await c.migrerZones();
      // Un seul lieu « Cellier » pour les deux (même nom, accents/casse).
      expect(l.elements.single.nom, 'Cellier');
      expect(c.emplacementDe(c.parId('x')!), 'Cellier · rangée 3');
      expect(c.parId('y')!.emplacement.lieuId, l.elements.single.id);
      expect(c.parId('x')!.emplacement.ancienneZone, isNull);
    });

    test('ajout et retrait de bouteilles', () async {
      await ctrl.ajouterBouteilles('b', 2);
      await ctrl.retirerBouteilles('a', 1, commentaire: 'Apéro');
      expect(ctrl.parId('a')!.quantite, 2);
      expect(ctrl.parId('b')!.quantite, 2);
      expect(ctrl.totalBouteilles, 4);
      expect(ctrl.parId('a')!.mouvements.last.commentaire, 'Apéro');
    });

    test('retrait impossible au-delà du stock', () {
      expect(() => ctrl.retirerBouteilles('b', 1), throwsStateError);
    });

    test('recherche par emplacement et filtres', () {
      expect(ctrl.rechercher(texte: 'fond').single.id, 'b');
      expect(ctrl.rechercher(type: TypeVin.blanc).single.id, 'a');
      expect(ctrl.rechercher(seulementEnStock: true).single.id, 'a');
      // En stock d'abord.
      expect(ctrl.rechercher().map((b) => b.id), ['a', 'b']);
    });
  });

  test('DepotPreferences relit ce qu\'il a écrit', () async {
    SharedPreferences.setMockInitialValues({});
    final depot = DepotPreferences(await SharedPreferences.getInstance());
    await depot.ecrire('livres', [
      {'id': '1', 'titre': 'A'},
    ]);
    expect(await depot.lire('livres'), [
      {'id': '1', 'titre': 'A'},
    ]);
    expect(await depot.lire('inconnu'), isEmpty);
  });
}
