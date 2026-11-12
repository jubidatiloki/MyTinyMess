import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/app.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/models/bouteille.dart';
import 'package:my_tiny_mess/models/livre.dart';
import 'package:my_tiny_mess/models/section.dart';
import 'package:my_tiny_mess/state/bibliotheque_controller.dart';
import 'package:my_tiny_mess/state/cave_controller.dart';
import 'package:my_tiny_mess/state/preferences_controller.dart';

void main() {
  Future<DepotMemoire> lancer(WidgetTester tester, [DepotMemoire? d]) async {
    final depot = d ?? DepotMemoire();
    await tester.pumpWidget(MyTinyMessApp(depot: depot));
    await tester.pumpAndSettle();
    return depot;
  }

  /// Ouvre le menu latéral (☰) et choisit une rubrique.
  Future<void> ouvrir(WidgetTester tester, Section section) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('menu-${section.name}')));
    await tester.pumpAndSettle();
  }

  testWidgets('au démarrage : vue d\'ensemble avec compteurs à zéro', (
    tester,
  ) async {
    await lancer(tester);
    expect(find.text('Vue d\'ensemble'), findsOneWidget);
    expect(find.text('livre'), findsOneWidget);
    expect(find.text('bouteille'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('vue d\'ensemble : compteurs et accès par les tuiles', (
    tester,
  ) async {
    final depot = DepotMemoire();
    final biblio = BibliothequeController(depot);
    await biblio.charger();
    await biblio.enregistrer(const Livre(id: '1', titre: 'Dune'));
    await biblio.enregistrer(const Livre(id: '2', titre: 'Zadig'));
    final cave = CaveController(depot);
    await cave.charger();
    await cave.enregistrer(
      const Bouteille(
        id: 'b',
        nom: 'Chinon',
        emplacement: Emplacement(zone: 'Cellier'),
      ).ajouter(5),
    );

    await lancer(tester, depot);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('livres'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('bouteilles'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tuile-bouteilles')));
    await tester.pumpAndSettle();
    expect(find.text('Ma cave (5 bouteilles)'), findsOneWidget);
  });

  testWidgets('menu latéral : toutes les rubriques s\'ouvrent', (tester) async {
    await lancer(tester);
    await ouvrir(tester, Section.bibliotheque);
    expect(find.textContaining('Aucun livre'), findsOneWidget);
    await ouvrir(tester, Section.bazar);
    expect(find.text('Bientôt disponible.'), findsOneWidget);
    await ouvrir(tester, Section.contact);
    expect(find.text('Contact'), findsOneWidget);
    await ouvrir(tester, Section.aPropos);
    expect(find.textContaining('Version'), findsOneWidget);
    await ouvrir(tester, Section.accueil);
    expect(find.byKey(const Key('tuile-livres')), findsOneWidget);
  });

  testWidgets('préférences : thème clair et écran d\'ouverture enregistrés', (
    tester,
  ) async {
    final depot = await lancer(tester);
    ThemeMode modeActuel() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
    expect(modeActuel(), ThemeMode.dark); // sombre par défaut

    await ouvrir(tester, Section.preferences);
    await tester.tap(find.byKey(const Key('theme-clair')));
    await tester.pumpAndSettle();
    expect(modeActuel(), ThemeMode.light);

    await tester.tap(find.byKey(const Key('demarrage-cave')));
    await tester.pumpAndSettle();

    // Relu par un nouveau contrôleur : c'est bien enregistré.
    final relu = PreferencesController(depot);
    await relu.charger();
    expect(relu.theme, ChoixTheme.clair);
    expect(relu.ecranDemarrage, Section.cave);
  });

  testWidgets('ajouter un livre prêté avec des notes', (tester) async {
    final depot = await lancer(tester);
    await ouvrir(tester, Section.bibliotheque);

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
    await ouvrir(tester, Section.cave);
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
