import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/app.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/models/aliment.dart';
import 'package:my_tiny_mess/models/unite.dart';
import 'package:my_tiny_mess/state/frigo_controller.dart';

void main() {
  test('unités : accord et saisie', () {
    expect(accorderUnite('tranche', 1), 'tranche');
    expect(accorderUnite('tranche', 3), 'tranches');
    expect(accorderUnite('morceau', 2), 'morceaux');
    expect(accorderUnite('bocal', 2), 'bocaux');
    expect(accorderUnite('pot de yaourt', 4), 'pots de yaourt');
    expect(accorderUnite('kg', 2), 'kg');
    expect(accorderUnite('noix', 2), 'noix');
    expect(lireUnite(' Tranches '), 'tranche');
    expect(lireUnite('Morceaux'), 'morceau');
    expect(lireUnite('barquette'), 'barquette');
    expect(lireUnite('  '), isNull);
  });

  test(
    'unité gardée à l\'enregistrement et au changement de quantité',
    () async {
      final depot = DepotMemoire();
      final c = FrigoController(depot);
      await c.enregistrer(
        const Aliment(id: 's', nom: 'Saumon', quantite: 4, unite: 'tranche'),
      );
      await c.changerQuantite('s', 3);
      final relu = FrigoController(depot);
      await relu.charger();
      expect(relu.parId('s')!.quantiteLisible, '3 tranches');
      await c.changerQuantite('s', -2);
      expect(c.parId('s')!.quantite, 0);
      // Aliments des versions précédentes : sans unité.
      expect(
        Aliment.fromJson({
          'id': 'x',
          'nom': 'Lait',
          'quantite': 2,
        }).quantiteLisible,
        '2',
      );
    },
  );

  test('recherche : épuisés cachés, sauf avec le filtre « Épuisés »', () async {
    final c = FrigoController(DepotMemoire());
    await c.enregistrer(const Aliment(id: 'a', nom: 'Lait'));
    await c.enregistrer(const Aliment(id: 'b', nom: 'Brie', quantite: 0));
    expect(c.nombreEpuises, 1);
    expect(c.rechercher(), hasLength(2));
    expect(c.rechercher(epuises: false).single.id, 'a');
    expect(
      c.rechercher(epuises: false, filtre: FiltreAliments.epuises).single.id,
      'b',
    );
  });

  Future<void> lancer(WidgetTester tester, DepotMemoire depot) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MyTinyMessApp(
        key: UniqueKey(),
        depot: depot,
        chargerRecettesIntegrees: () async => [],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tuile-aliments')));
    await tester.pumpAndSettle();
  }

  Future<void> toucher(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('modifier la quantité depuis la liste', (tester) async {
    final depot = DepotMemoire();
    await FrigoController(depot).enregistrer(
      const Aliment(id: 's', nom: 'Saumon fumé', quantite: 4, unite: 'tranche'),
    );
    await lancer(tester, depot);
    // J'en mange une.
    await toucher(tester, find.byTooltip('Retirer 1 du stock'));
    expect(find.text('3 tranches'), findsOneWidget);
    // Saisie directe.
    await toucher(tester, find.byKey(const Key('quantite-s')));
    await tester.enterText(
      find.byKey(const Key('champ-nouvelle-quantite')),
      'abc',
    );
    await toucher(tester, find.byKey(const Key('valider-quantite')));
    expect(find.text('Nombre positif attendu'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('champ-nouvelle-quantite')),
      '7',
    );
    await toucher(tester, find.byTooltip('Un de moins'));
    await toucher(tester, find.byKey(const Key('valider-quantite')));
    expect(find.text('6 tranches'), findsOneWidget);
    expect((await depot.lire('aliments')).single['quantite'], 6);
  });

  testWidgets('cacher, afficher et supprimer les épuisés', (tester) async {
    final depot = DepotMemoire();
    final c = FrigoController(depot);
    await c.enregistrer(const Aliment(id: 'a', nom: 'Lait'));
    await c.enregistrer(const Aliment(id: 'b', nom: 'Brie', quantite: 0));
    await lancer(tester, depot);
    expect(find.text('Brie'), findsOneWidget);
    await toucher(tester, find.text('Cacher les épuisés (1)'));
    expect(find.text('Brie'), findsNothing);
    expect(find.text('Lait'), findsOneWidget);

    // Le choix est gardé.
    await lancer(tester, depot);
    expect(find.text('Brie'), findsNothing);
    await toucher(tester, find.text('Afficher les épuisés (1)'));

    // Le bouton n'existe que sur l'aliment épuisé.
    final supprimer = find.byTooltip('Supprimer définitivement');
    expect(supprimer, findsOneWidget);
    await toucher(tester, supprimer);
    await toucher(tester, find.text('Annuler'));
    expect(find.text('Brie'), findsOneWidget);
    await toucher(tester, supprimer);
    await toucher(tester, find.text('Confirmer'));
    expect(find.text('Brie'), findsNothing);
    expect((await depot.lire('aliments')).single['id'], 'a');
    expect(find.byKey(const Key('bouton-epuises')), findsNothing);
  });

  testWidgets('formulaire : choisir ou saisir une unité', (tester) async {
    final depot = DepotMemoire();
    await lancer(tester, depot);
    await tester.tap(find.byTooltip('Ajouter un aliment'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ-nom-aliment')), 'Thon');
    await tester.enterText(
      find.byKey(const Key('champ-quantite-aliment')),
      '2',
    );
    await toucher(tester, find.byKey(const Key('choix-unite')));
    await toucher(tester, find.text('conserve'));
    await toucher(tester, find.byKey(const Key('bouton-enregistrer')));
    expect(find.text('2 conserves'), findsOneWidget);

    await toucher(tester, find.text('Thon'));
    await tester.enterText(find.byKey(const Key('champ-unite')), 'barquette');
    await toucher(tester, find.byKey(const Key('bouton-enregistrer')));
    expect(find.text('2 barquettes'), findsOneWidget);
    expect((await depot.lire('aliments')).single['unite'], 'barquette');

    // Une unité saisie est ensuite proposée.
    await tester.tap(find.byTooltip('Ajouter un aliment'));
    await tester.pumpAndSettle();
    await toucher(tester, find.byKey(const Key('choix-unite')));
    expect(find.text('barquette'), findsOneWidget);
  });
}
