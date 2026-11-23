import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/app.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/models/aliment.dart';
import 'package:my_tiny_mess/models/lieu.dart';
import 'package:my_tiny_mess/state/categories_controller.dart';
import 'package:my_tiny_mess/state/frigo_controller.dart';
import 'package:my_tiny_mess/state/lieux_controller.dart';
import 'package:my_tiny_mess/state/preferences_controller.dart';
import 'package:my_tiny_mess/widgets/communs.dart';

Future<void> _lancer(
  WidgetTester tester,
  DepotMemoire depot, {
  Size taille = const Size(1000, 1600),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MyTinyMessApp(depot: depot, chargerRecettesIntegrees: () async => []),
  );
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  test('catégories : reprise des saisies libres, renommage, filtre', () async {
    final depot = DepotMemoire();
    final categories = CategoriesController(depot);
    final frigo = FrigoController(depot, categories: categories);
    await categories.charger();
    await frigo.charger();
    expect(categories.elements, hasLength(CategorieAliment.parDefaut.length));
    await frigo.enregistrer(
      const Aliment(id: 'a', nom: 'Tofu', categorie: 'Végétal', quantite: 1),
    );
    await frigo.enregistrer(
      const Aliment(id: 'b', nom: 'Brie', categorie: 'produits laitiers '),
    );
    await frigo.reprendreCategories();
    expect(categories.parNom('vegetal')?.nom, 'Végétal');
    expect(frigo.parId('b')!.categorie, 'Produits laitiers');

    await frigo.renommerCategorie('Végétal', 'Vegan');
    expect(frigo.parId('a')!.categorie, 'Vegan');
    expect(frigo.rechercher(categorie: 'Vegan').single.nom, 'Tofu');

    // Relecture : les catégories par défaut ne sont pas recréées.
    final n = categories.elements.length;
    final relu = CategoriesController(depot);
    await relu.charger();
    expect(relu.elements, hasLength(n));
  });

  test('plusJours passe les changements d\'heure', () {
    expect(plusJours(DateTime(2026, 10, 25), 1), DateTime(2026, 10, 26));
    expect(plusJours(DateTime(2026, 3, 29), 1), DateTime(2026, 3, 30));
    expect(debutSemaine(DateTime(2026, 11, 1)), DateTime(2026, 10, 26));
  });

  testWidgets('préférences : ajouter une catégorie, refus si utilisée', (
    tester,
  ) async {
    final depot = DepotMemoire();
    await FrigoController(
      depot,
    ).enregistrer(const Aliment(id: 'a', nom: 'Tofu', categorie: 'Végétal'));
    await _lancer(tester, depot);
    await _toucher(tester, find.byKey(const Key('menu-preferences')));
    await _toucher(tester, find.byKey(const Key('pref-categories')));
    await tester.tap(find.byTooltip('Ajouter une catégorie'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('champ-nom-categorie')),
      'Apéro',
    );
    await tester.tap(find.byKey(const Key('valider-categorie')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categorie-Apéro')), findsOneWidget);

    // Une catégorie utilisée ne se supprime pas.
    await _toucher(
      tester,
      find.descendant(
        of: find.byKey(const Key('categorie-Végétal')),
        matching: find.byTooltip('Supprimer'),
      ),
    );
    expect(find.textContaining('utilisent encore'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categorie-Végétal')), findsOneWidget);
  });

  testWidgets('frigo : le formulaire et le filtre proposent les catégories', (
    tester,
  ) async {
    final depot = DepotMemoire();
    final frigo = FrigoController(depot);
    await frigo.enregistrer(
      const Aliment(
        id: 'a',
        nom: 'Brie',
        categorie: 'Produits laitiers',
        quantite: 1,
      ),
    );
    await frigo.enregistrer(
      const Aliment(id: 'b', nom: 'Colin', categorie: 'Poissons', quantite: 1),
    );
    await _lancer(tester, depot);
    await _toucher(tester, find.byKey(const Key('menu-frigo')));
    await _toucher(tester, find.byKey(const Key('filtre-categorie')));
    await tester.tap(find.widgetWithText(SimpleDialogOption, 'Poissons'));
    await tester.pumpAndSettle();
    expect(find.text('Colin'), findsOneWidget);
    expect(find.text('Brie'), findsNothing);
    await _toucher(tester, find.text('Colin'));
    expect(find.byKey(const Key('champ-categorie')), findsOneWidget);
  });

  testWidgets('vue d\'ensemble : regrouper et déplier les emplacements', (
    tester,
  ) async {
    final depot = DepotMemoire();
    final lieux = LieuxController(depot);
    final salon = await lieux.creer('Salon');
    final etagere = await lieux.creer('Étagère', parentId: salon.id);
    await _lancer(tester, depot);
    final ligne = find.byKey(Key('resume-lieu-${etagere.id}'));
    expect(ligne, findsOneWidget);

    // Replier un meuble cache ce qu'il contient, pas lui-même.
    await _toucher(tester, find.byTooltip('Regrouper'));
    expect(ligne, findsNothing);
    expect(find.byKey(Key('resume-lieu-${salon.id}')), findsOneWidget);
    await _toucher(tester, find.byTooltip('Déplier'));
    expect(ligne, findsOneWidget);

    // Replier un type entier, puis tout regrouper / tout déplier.
    await _toucher(tester, find.byKey(Key('groupe-${salon.type.name}')));
    expect(find.byKey(Key('resume-lieu-${salon.id}')), findsNothing);
    final relu = PreferencesController(depot);
    await relu.charger();
    expect(relu.replies, {salon.type.name});
    await _toucher(tester, find.byKey(const Key('regrouper-emplacements')));
    await relu.charger();
    expect(relu.replies, {for (final t in TypeLieu.values) t.name});
    await _toucher(tester, find.text('Tout déplier'));
    expect(ligne, findsOneWidget);
  });

  testWidgets('agenda : calendrier, choix du jour et vue mémorisée', (
    tester,
  ) async {
    final depot = DepotMemoire();
    // Écran de téléphone : rien ne doit déborder.
    await _lancer(tester, depot, taille: const Size(400, 900));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await _toucher(tester, find.byKey(const Key('menu-agenda')));
    await _toucher(tester, find.text('Calendrier'));
    final a = DateTime.now();
    expect(find.text(moisEnLettres(a)), findsOneWidget);
    await _toucher(tester, find.byTooltip('Mois suivant'));
    final s = DateTime(a.year, a.month + 1);
    expect(find.text(moisEnLettres(s)), findsOneWidget);
    await _toucher(tester, find.byKey(Key('cal-${s.year}-${s.month}-15')));

    // Un nouvel événement est proposé au jour choisi.
    await tester.tap(find.byTooltip('Ajouter un événement'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('champ-titre-evenement')),
      'Dentiste',
    );
    await tester.tap(find.byKey(const Key('valider-evenement')));
    await tester.pumpAndSettle();
    final ev = (await depot.lire('evenements')).single;
    expect(
      ev.values.whereType<String>().any(
        (v) =>
            v.startsWith('${s.year}-${s.month.toString().padLeft(2, '0')}-15'),
      ),
      isTrue,
    );

    final relu = PreferencesController(depot);
    await relu.charger();
    expect(relu.agendaCalendrier, isTrue);
  });
}
