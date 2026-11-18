import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/models/aliment.dart';
import 'package:my_tiny_mess/models/bouteille.dart';
import 'package:my_tiny_mess/models/lieu.dart';
import 'package:my_tiny_mess/models/type_bouteille.dart';
import 'package:my_tiny_mess/state/frigo_controller.dart';
import 'package:my_tiny_mess/state/lieux_controller.dart';
import 'package:my_tiny_mess/state/types_bouteille_controller.dart';

void main() {
  group('Types de bouteille', () {
    test('types par défaut au premier lancement, puis modifiables', () async {
      final depot = DepotMemoire();
      final types = TypesBouteilleController(depot);
      await types.charger();
      expect(types.elements.map((t) => t.id), [
        'rouge',
        'blanc',
        'rose',
        'effervescent',
        'liquoreux',
        'autre',
      ]);

      final biere = await types.creer('Bière', TypeBouteille.palette[4]);
      await types.supprimer('liquoreux');
      final relu = TypesBouteilleController(depot);
      await relu.charger();
      expect(relu.elements, hasLength(6));
      expect(relu.nomDe(biere.id), 'Bière');
      expect(relu.nomDe('liquoreux'), 'Sans type');
    });

    test('une bouteille des versions ≤ 0.7 garde son type', () {
      final b = Bouteille.fromJson({
        'id': 'x',
        'nom': 'Chinon',
        'type': 'rouge',
      });
      expect(b.typeId, 'rouge');
      expect(Bouteille.fromJson({'id': 'y', 'nom': 'Sans'}).typeId, 'autre');
      expect(b.toJson()['type'], 'rouge');
    });
  });

  group('Frigo', () {
    final aujourdhui = DateTime(2026, 11, 18, 15);

    test('état de péremption', () {
      Aliment avec(DateTime? d) =>
          Aliment(id: 'a', nom: 'Yaourt', datePeremption: d);
      expect(avec(null).etat(aujourdhui), EtatPeremption.sansDate);
      expect(
        avec(DateTime(2026, 11, 17)).etat(aujourdhui),
        EtatPeremption.perime,
      );
      expect(
        avec(DateTime(2026, 11, 18)).etat(aujourdhui),
        EtatPeremption.bientot,
      );
      expect(
        avec(DateTime(2026, 11, 21)).etat(aujourdhui),
        EtatPeremption.bientot,
      );
      expect(avec(DateTime(2026, 11, 22)).etat(aujourdhui), EtatPeremption.ok);
      expect(avec(DateTime(2026, 11, 16)).joursRestants(aujourdhui), -2);
    });

    test('JSON relu à l\'identique', () {
      final a = Aliment(
        id: 'a',
        nom: 'Beurre',
        categorie: 'Laitage',
        quantite: 2,
        contenance: '250 g',
        datePeremption: DateTime(2026, 12, 1),
        lieuId: 'frigo',
        notes: 'Doux',
      );
      final relu = Aliment.fromJson(a.toJson());
      expect(relu.nom, 'Beurre');
      expect(relu.quantite, 2);
      expect(relu.contenance, '250 g');
      expect(relu.datePeremption, DateTime(2026, 12, 1));
      expect(relu.lieuId, 'frigo');
    });

    test('quantités, tri, filtres et emplacements', () async {
      final depot = DepotMemoire();
      final lieux = LieuxController(depot);
      await lieux.charger();
      final frigo = await lieux.creer('Frigo', type: TypeLieu.frigo);
      final bac = await lieux.creer('Bac à légumes', parentId: frigo.id);
      expect(bac.type, TypeLieu.frigo);

      final ctrl = FrigoController(
        depot,
        lieux: lieux,
        maintenant: () => aujourdhui,
      );
      await ctrl.charger();
      await ctrl.enregistrer(
        Aliment(
          id: 'lait',
          nom: 'Lait',
          quantite: 2,
          datePeremption: DateTime(2026, 11, 25),
        ),
      );
      await ctrl.enregistrer(
        Aliment(
          id: 'yaourt',
          nom: 'Yaourts',
          quantite: 4,
          datePeremption: DateTime(2026, 11, 19),
          lieuId: frigo.id,
        ),
      );
      await ctrl.enregistrer(
        Aliment(
          id: 'salade',
          nom: 'Salade',
          datePeremption: DateTime(2026, 11, 15),
          lieuId: bac.id,
        ),
      );
      await ctrl.enregistrer(const Aliment(id: 'sel', nom: 'Sel'));

      // Le plus urgent d'abord, sans date à la fin.
      expect(ctrl.rechercher().map((a) => a.id), [
        'salade',
        'yaourt',
        'lait',
        'sel',
      ]);
      expect(
        ctrl.rechercher(filtre: FiltreAliments.perimes).single.id,
        'salade',
      );
      expect(
        ctrl.rechercher(filtre: FiltreAliments.bientot).single.id,
        'yaourt',
      );
      expect(ctrl.nombreASurveiller, 2);
      expect(ctrl.nombreArticles, 8);
      expect(ctrl.nombreDans(frigo.id), 5); // bac compris
      expect(ctrl.rechercher(lieuId: frigo.id).map((a) => a.id), [
        'salade',
        'yaourt',
      ]);

      await ctrl.retirerUn('salade');
      await ctrl.retirerUn('salade'); // pas en dessous de 0
      expect(ctrl.parId('salade')!.quantite, 0);
      expect(
        ctrl.rechercher(filtre: FiltreAliments.epuises).single.id,
        'salade',
      );
      expect(ctrl.nombreASurveiller, 1); // épuisé : plus à surveiller
      await ctrl.ajouterUn('lait');
      expect(ctrl.parId('lait')!.quantite, 3);
    });
  });
}
