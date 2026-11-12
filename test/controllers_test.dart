import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/models/bouteille.dart';
import 'package:my_tiny_mess/models/livre.dart';
import 'package:my_tiny_mess/state/bibliotheque_controller.dart';
import 'package:my_tiny_mess/state/cave_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

    setUp(() async {
      ctrl = CaveController(DepotMemoire());
      await ctrl.charger();
      await ctrl.enregistrer(
        const Bouteille(
          id: 'a',
          nom: 'Sancerre',
          type: TypeVin.blanc,
          emplacement: Emplacement(zone: 'Casier', rangee: '1'),
        ).ajouter(3),
      );
      await ctrl.enregistrer(
        const Bouteille(
          id: 'b',
          nom: 'Bordeaux',
          emplacement: Emplacement(zone: 'Cave du fond'),
        ),
      );
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
