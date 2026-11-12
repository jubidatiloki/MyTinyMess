import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/models/bouteille.dart';
import 'package:my_tiny_mess/models/livre.dart';

void main() {
  group('Livre', () {
    const livre = Livre(
      id: 'l1',
      titre: 'Le Petit Prince',
      auteur: 'Saint-Exupéry',
      annee: 1943,
      note: 5,
      notes: 'Relu en 2026',
      lieuId: 'salon',
    );

    test('se sauvegarde et se relit à l\'identique (JSON)', () {
      final prete = livre.preter('Julie', le: DateTime(2026, 3, 1));
      final relu = Livre.fromJson(prete.toJson());
      expect(relu.lieuId, 'salon');
      expect(prete.rendre().avecStatut(StatutLecture.lu).lieuId, 'salon');
      expect(relu.titre, 'Le Petit Prince');
      expect(relu.annee, 1943);
      expect(relu.note, 5);
      expect(relu.notes, 'Relu en 2026');
      expect(relu.possession, Possession.prete);
      expect(relu.personne, 'Julie');
      expect(relu.datePret, DateTime(2026, 3, 1));
    });

    test('prêter, emprunter puis rendre', () {
      final prete = livre.preter('Julie');
      expect(prete.possession, Possession.prete);
      expect(prete.estChezMoi, isFalse);

      final emprunte = livre.preter('Marc', emprunte: true);
      expect(emprunte.possession, Possession.emprunte);
      expect(emprunte.personne, 'Marc');

      final rendu = prete.rendre();
      expect(rendu.estChezMoi, isTrue);
      expect(rendu.personne, isNull);
      expect(rendu.datePret, isNull);
      expect(rendu.titre, livre.titre);
    });

    test('valeurs inconnues ou absentes dans le JSON → valeurs par défaut', () {
      final l = Livre.fromJson({'id': 'x', 'statut': 'bizarre'});
      expect(l.titre, '');
      expect(l.statut, StatutLecture.aLire);
      expect(l.possession, Possession.possede);
    });
  });

  group('Bouteille', () {
    const bouteille = Bouteille(
      id: 'b1',
      nom: 'Château Test',
      millesime: 2018,
      emplacement: Emplacement(lieuId: 'cave', rangee: '2', colonne: 'B'),
    );

    test('ajouter et retirer mettent à jour le stock et l\'historique', () {
      final b = bouteille
          .ajouter(6, commentaire: 'Achat salon')
          .retirer(2, commentaire: 'Repas');
      expect(b.quantite, 4);
      expect(b.mouvements.map((m) => m.quantite), [6, -2]);
      expect(b.mouvements.first.commentaire, 'Achat salon');
    });

    test('impossible de retirer plus que le stock', () {
      final b = bouteille.ajouter(1);
      expect(() => b.retirer(2), throwsStateError);
      expect(() => b.ajouter(0), throwsArgumentError);
    });

    test('libellé de l\'emplacement', () {
      expect(
        bouteille.emplacement.libelle('Cave › Casier A'),
        'Cave › Casier A · rangée 2 · colonne B',
      );
      expect(const Emplacement(rangee: '3').libelle(null), 'rangée 3');
      expect(const Emplacement().libelle(null), '');
    });

    test('ancienne zone (version 0.2) relue depuis le JSON', () {
      final b = Bouteille.fromJson({
        'id': 'x',
        'nom': 'Vieux',
        'emplacement': {'zone': 'Frigo', 'rangee': '1'},
      });
      expect(b.emplacement.ancienneZone, 'Frigo');
      expect(b.emplacement.lieuId, isNull);
      expect(b.emplacement.libelle(null), 'Frigo · rangée 1');
      // Une fois rattachée à un lieu, l'ancienne zone disparaît.
      final migree = b.emplacement.avecLieu('frigo');
      expect(migree.ancienneZone, isNull);
      expect(migree.rangee, '1');
    });

    test('se sauvegarde et se relit à l\'identique (JSON)', () {
      final b = bouteille.ajouter(3, le: DateTime(2026, 1, 2));
      final relu = Bouteille.fromJson(b.toJson());
      expect(relu.nom, 'Château Test');
      expect(relu.millesime, 2018);
      expect(relu.quantite, 3);
      expect(relu.emplacement.lieuId, 'cave');
      expect(relu.emplacement.libelle('X'), b.emplacement.libelle('X'));
      expect(relu.mouvements.single.date, DateTime(2026, 1, 2));
    });
  });
}
