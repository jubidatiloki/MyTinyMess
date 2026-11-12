import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/app.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/models/livre.dart';

void main() {
  Future<DepotMemoire> lancer(WidgetTester tester) async {
    final depot = DepotMemoire();
    await tester.pumpWidget(MyTinyMessApp(depot: depot));
    await tester.pumpAndSettle();
    return depot;
  }

  testWidgets('au démarrage : bibliothèque vide', (tester) async {
    await lancer(tester);
    expect(find.text('Ma bibliothèque'), findsOneWidget);
    expect(find.textContaining('Aucun livre'), findsOneWidget);
  });

  testWidgets('ajouter un livre prêté avec des notes', (tester) async {
    final depot = await lancer(tester);

    await tester.tap(find.byTooltip('Ajouter un livre'));
    await tester.pumpAndSettle();

    // Le titre est obligatoire.
    await tester.tap(find.byTooltip('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Le titre est obligatoire'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('champ-titre')), 'Dune');
    await tester.enterText(find.byKey(const Key('champ-auteur')), 'Herbert');

    await tester.tap(find.byKey(const Key('champ-possession')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prêté').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('champ-personne')), 'Julie');
    await tester.scrollUntilVisible(
      find.byKey(const Key('champ-notes')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('champ-notes')), 'Génial');
    await tester.tap(find.byTooltip('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Prêté à Julie'), findsOneWidget);

    final enregistre = Livre.fromJson((await depot.lire('livres')).single);
    expect(enregistre.notes, 'Génial');
    expect(enregistre.possession, Possession.prete);
    expect(enregistre.datePret, isNotNull);
  });

  testWidgets('cave : ajouter un vin, puis + et -', (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Cave'));
    await tester.pumpAndSettle();
    expect(find.text('Ma cave (0 bouteille)'), findsOneWidget);

    await tester.tap(find.byTooltip('Ajouter un vin'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ-nom')), 'Chinon');
    await tester.enterText(find.byKey(const Key('champ-millesime')), '2020');
    await tester.enterText(find.byKey(const Key('champ-quantite')), '3');
    await tester.enterText(find.byKey(const Key('champ-zone')), 'Cellier');
    await tester.enterText(find.byKey(const Key('champ-rangee')), '2');
    await tester.tap(find.byTooltip('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Chinon 2020'), findsOneWidget);
    expect(find.text('Cellier · rangée 2'), findsOneWidget);
    expect(find.text('Ma cave (3 bouteilles)'), findsOneWidget);

    await tester.tap(find.byTooltip('Retirer une bouteille'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retirer une bouteille'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter une bouteille'));
    await tester.pumpAndSettle();
    expect(find.text('Ma cave (2 bouteilles)'), findsOneWidget);

    // L'historique est visible dans la fiche.
    await tester.tap(find.text('Chinon 2020'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Historique (2 en stock)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Historique (2 en stock)'), findsOneWidget);
  });
}
