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

  /// Choisit une rubrique dans le menu latéral (en l'ouvrant avec ☰ s'il
  /// n'est pas fixé à gauche).
  Future<void> ouvrir(WidgetTester tester, Section section) async {
    final burger = find.byIcon(Icons.menu);
    if (burger.evaluate().isNotEmpty) {
      await tester.tap(burger);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(Key('menu-${section.name}')));
    await tester.pumpAndSettle();
  }

  /// Simule un écran de téléphone (le menu n'est alors jamais fixé).
  void ecranTelephone(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('au démarrage : vue d\'ensemble avec compteurs à zéro', (
    tester,
  ) async {
    await lancer(tester);
    expect(find.widgetWithText(AppBar, 'Vue d\'ensemble'), findsOneWidget);
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
    await cave.enregistrer(const Bouteille(id: 'b', nom: 'Chinon').ajouter(5));

    await lancer(tester, depot);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('livres'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('bouteilles'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tuile-bouteilles')));
    await tester.pumpAndSettle();
    expect(find.text('5 bouteilles'), findsOneWidget);
  });

  testWidgets('menu latéral : toutes les rubriques s\'ouvrent', (tester) async {
    await lancer(tester);
    await ouvrir(tester, Section.bibliotheque);
    expect(find.textContaining('Aucun livre'), findsOneWidget);
    await ouvrir(tester, Section.bazar);
    expect(find.text('Bientôt disponible.'), findsOneWidget);
    expect(find.text('Contact'), findsNothing); // rubrique retirée
    await ouvrir(tester, Section.aPropos);
    expect(find.text('My Tiny Mess'), findsWidgets);
    await ouvrir(tester, Section.accueil);
    expect(find.byKey(const Key('tuile-livres')), findsOneWidget);
  });

  testWidgets('menu latéral fixe sur grand écran, désactivable', (
    tester,
  ) async {
    await lancer(tester); // écran de test : 800 px de large
    // Ouvert par défaut : visible sans bouton ☰.
    expect(find.byKey(const Key('menu-cave')), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);

    await ouvrir(tester, Section.preferences);
    await tester.tap(find.byKey(const Key('pref-menu-fixe')));
    await tester.pumpAndSettle();
    // Menu replié : il revient derrière le bouton ☰.
    expect(find.byKey(const Key('menu-cave')), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    await ouvrir(tester, Section.cave);
    expect(find.text('0 bouteille'), findsOneWidget);
  });

  testWidgets('sur téléphone, le menu s\'ouvre avec ☰', (tester) async {
    ecranTelephone(tester);
    await lancer(tester);
    expect(find.byKey(const Key('menu-cave')), findsNothing);
    await ouvrir(tester, Section.bibliotheque);
    expect(find.widgetWithText(AppBar, 'Ma bibliothèque'), findsOneWidget);
  });

  testWidgets('bibliothèque : créer des emplacements et y ranger un livre', (
    tester,
  ) async {
    final depot = await lancer(tester);
    await ouvrir(tester, Section.bibliotheque);

    // Écran des emplacements : « Salon », puis « Étagère 1 » dedans.
    await tester.tap(find.byTooltip('Emplacements'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter un emplacement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ-nom-lieu')), 'Salon');
    await tester.tap(find.byKey(const Key('valider-lieu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter dedans'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('champ-nom-lieu')),
      'Étagère 1',
    );
    await tester.tap(find.byKey(const Key('valider-lieu')));
    await tester.pumpAndSettle();
    expect(find.text('Salon'), findsOneWidget);
    expect(find.text('Étagère 1'), findsOneWidget);
    // Le bouton de la bibliothèque a ouvert la rubrique « Emplacements ».
    expect(find.widgetWithText(AppBar, 'Emplacements'), findsOneWidget);
    await ouvrir(tester, Section.bibliotheque);

    // Nouveau livre rangé sur l'étagère.
    await tester.tap(find.byTooltip('Ajouter un livre'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ-titre')), 'Dune');
    await tester.scrollUntilVisible(
      find.byKey(const Key('champ-lieu')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Aucun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Étagère 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Salon › Étagère 1'), findsOneWidget);
    final livre = Livre.fromJson((await depot.lire('livres')).single);
    expect(livre.lieuId, isNotNull);

    // Filtre par emplacement : le salon contient l'étagère, donc le livre.
    await tester.tap(find.byKey(const Key('filtre-lieu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salon').last);
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);

    // Vue d'ensemble : chaque emplacement avec son nombre de livres.
    await ouvrir(tester, Section.accueil);
    final salon = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('resume-lieu-') &&
          !(w.key! as ValueKey<String>).value.startsWith('resume-lieu-aucun'),
    );
    expect(salon, findsNWidgets(2));
    expect(
      find.descendant(of: salon.first, matching: find.text('1')),
      findsOneWidget,
    );
    expect(find.text('Sans emplacement'), findsNothing);
  });

  testWidgets('emplacements : modifier et supprimer depuis le menu', (
    tester,
  ) async {
    await lancer(tester);
    await ouvrir(tester, Section.emplacements);
    expect(find.textContaining('Aucun emplacement'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Ajouter un emplacement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ-nom-lieu')), 'Garage');
    await tester.tap(find.byKey(const Key('valider-lieu')));
    await tester.pumpAndSettle();
    expect(find.text('Vide'), findsOneWidget);

    await tester.tap(find.byTooltip('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ-nom-lieu')), 'Cellier');
    await tester.tap(find.byKey(const Key('valider-lieu')));
    await tester.pumpAndSettle();
    expect(find.text('Cellier'), findsOneWidget);
    expect(find.text('Garage'), findsNothing);

    await tester.tap(find.byTooltip('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(find.text('Cellier'), findsNothing);
    expect(find.textContaining('Aucun emplacement'), findsNWidgets(2));

    // Un emplacement pour la cave ne s'affiche que du côté cave.
    await tester.tap(find.byKey(const Key('ajouter-lieu-cave')));
    await tester.pumpAndSettle();
    expect(find.text('Pour les bouteilles'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('champ-nom-lieu')), 'Cellier');
    await tester.tap(find.byKey(const Key('valider-lieu')));
    await tester.pumpAndSettle();
    expect(find.text('Aucun emplacement pour les livres'), findsOneWidget);
    expect(find.text('Cellier'), findsOneWidget);

    await ouvrir(tester, Section.bibliotheque);
    await tester.tap(find.byTooltip('Ajouter un livre'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('champ-lieu')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Aucun — créez-en un avec +'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await ouvrir(tester, Section.cave);
    await tester.tap(find.byTooltip('Ajouter un vin'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('champ-lieu')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Aucun — créez-en un avec +'), findsNothing);
  });

  testWidgets('liste de souhaits : sans emplacement, à part des livres', (
    tester,
  ) async {
    final depot = await lancer(tester);
    await ouvrir(tester, Section.bibliotheque);
    await tester.tap(find.byTooltip('Ajouter un livre'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ-titre')), 'Hypérion');
    expect(find.byKey(const Key('champ-lieu')), findsOneWidget);
    await tester.tap(find.byKey(const Key('champ-lecture')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liste de souhaits').last);
    await tester.pumpAndSettle();
    // Pas encore chez moi : ni emplacement, ni prêt.
    expect(find.byKey(const Key('champ-lieu')), findsNothing);
    expect(find.byKey(const Key('champ-possession')), findsNothing);
    await tester.tap(find.byTooltip('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Hypérion'), findsNothing); // filtre « Tous »
    expect(find.text('0 livre · 1 en liste de souhaits'), findsOneWidget);
    await tester.ensureVisible(find.text('Liste de souhaits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liste de souhaits'));
    await tester.pumpAndSettle();
    expect(find.text('Hypérion'), findsOneWidget);
    final livre = Livre.fromJson((await depot.lire('livres')).single);
    expect(livre.statut, StatutLecture.souhait);
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

    await tester.tap(find.byKey(const Key('pref-demarrage')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ma cave').last);
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

    await tester.scrollUntilVisible(
      find.byKey(const Key('champ-possession')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('champ-possession')));
    await tester.pumpAndSettle();
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
    expect(find.text('0 bouteille'), findsOneWidget);

    await tester.tap(find.byTooltip('Ajouter un vin'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ-nom')), 'Chinon');
    await tester.enterText(find.byKey(const Key('champ-millesime')), '2020');
    await tester.enterText(find.byKey(const Key('champ-quantite')), '3');
    // Emplacement créé directement depuis le formulaire (bouton à côté).
    await tester.scrollUntilVisible(
      find.byKey(const Key('champ-rangee')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Nouvel emplacement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ-nom-lieu')), 'Cellier');
    await tester.tap(find.byKey(const Key('valider-lieu')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ-rangee')), '2');
    await tester.tap(find.byTooltip('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Chinon 2020'), findsOneWidget);
    expect(find.text('Cellier · rangée 2'), findsOneWidget);
    expect(find.text('3 bouteilles'), findsOneWidget);

    await tester.tap(find.byTooltip('Retirer une bouteille'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retirer une bouteille'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter une bouteille'));
    await tester.pumpAndSettle();
    expect(find.text('2 bouteilles'), findsOneWidget);

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
