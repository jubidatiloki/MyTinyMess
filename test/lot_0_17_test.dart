import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/app.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/models/adresse.dart';
import 'package:my_tiny_mess/models/aliment.dart';
import 'package:my_tiny_mess/models/bouteille.dart';
import 'package:my_tiny_mess/models/recette.dart';
import 'package:my_tiny_mess/state/annuaire_controller.dart';
import 'package:my_tiny_mess/state/categories_controller.dart';
import 'package:my_tiny_mess/state/cave_controller.dart';
import 'package:my_tiny_mess/state/frigo_controller.dart';
import 'package:my_tiny_mess/state/recettes_controller.dart';
import 'package:my_tiny_mess/widgets/icones_aliments.dart';

List<Recette> _carnet() => [
  for (final r
      in jsonDecode(File('assets/data/recettes.json').readAsStringSync())
          as List)
    Recette.fromJson(
      (r as Map).cast<String, dynamic>(),
      source: SourceRecette.integree,
    ),
];

void main() {
  test('catégories par ordre alphabétique', () async {
    final c = CategoriesController(DepotMemoire());
    await c.charger();
    await c.creer('Apéro');
    final noms = c.elements.map((e) => e.nom).toList();
    expect(noms.first, 'Apéro');
    expect(noms.indexOf('Œufs'), lessThan(noms.indexOf('Poissons')));
    expect(noms.indexOf('Épicerie salée'), lessThan(noms.indexOf('Fromages')));
  });

  test('icônes des catégories, aussi pour une catégorie libre', () {
    expect(iconeCategorie('Fromages'), Icons.pie_chart_outline);
    expect(iconeCategorie('Légumes du jardin'), Icons.eco_outlined);
    expect(iconeCategorie('Surgelés'), Icons.ac_unit);
    expect(iconeCategorie('Produits laitiers'), Icons.local_drink_outlined);
    expect(iconeCategorie(null), Icons.kitchen_outlined);
    expect(iconeCategorie('Divers'), Icons.kitchen_outlined);
    for (final c in CategorieAliment.parDefaut) {
      expect(iconeCategorie(c), isNot(Icons.kitchen_outlined), reason: c);
    }
  });

  test('variante : enregistrée, cherchée et proposée', () async {
    final c = FrigoController(DepotMemoire());
    await c.enregistrer(
      const Aliment(id: 'a', nom: 'Pommes de terre', variante: 'grenailles'),
    );
    await c.enregistrer(
      const Aliment(id: 'b', nom: 'pommes de terre', variante: 'Rissolées'),
    );
    await c.enregistrer(const Aliment(id: 'c', nom: 'Beurre'));
    expect(c.parId('a')!.nomComplet, 'Pommes de terre · grenailles');
    expect(c.parId('c')!.nomComplet, 'Beurre');
    expect(Aliment.fromJson(c.parId('a')!.toJson()).variante, 'grenailles');
    expect(c.variantesDe('Pommes de Terre'), ['grenailles', 'Rissolées']);
    expect(c.variantesDe('Beurre'), isEmpty);
    expect(c.rechercher(texte: 'rissol').single.id, 'b');
  });

  test('bouteille : niveau et adresse gardés, niveau remis à plein', () {
    var b = const Bouteille(
      id: 'b',
      nom: 'Chablis',
      quantite: 2,
      niveau: 40,
      adresseId: 'cave',
    );
    b = Bouteille.fromJson(b.toJson());
    expect(b.niveau, 40);
    expect(b.adresseId, 'cave');
    expect(b.ajouter(1).niveau, 40);
    final retiree = b.retirer(1);
    expect(retiree.niveau, isNull);
    expect(retiree.adresseId, 'cave');
  });

  test('recettes : apéritifs, boissons et conseils dans le carnet', () {
    final carnet = _carnet();
    expect(carnet, hasLength(72));
    expect(carnet.map((r) => r.id).toSet(), hasLength(72));
    expect(
      carnet.where((r) => r.styles.contains(StyleRecette.aperitif)),
      hasLength(5),
    );
    expect(
      carnet.where((r) => r.styles.contains(StyleRecette.boisson)),
      hasLength(4),
    );
    expect(carnet.where((r) => r.conseils.isNotEmpty), hasLength(9));
    final r = carnet.firstWhere((r) => r.id == 'int-limonade');
    expect(Recette.fromJson(r.toJson()).conseils, r.conseils);
  });

  Future<void> lancer(WidgetTester tester, DepotMemoire depot) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MyTinyMessApp(
        depot: depot,
        chargerRecettesIntegrees: () async => _carnet(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> toucher(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> ouvrirMenu(WidgetTester tester, String section) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await toucher(tester, find.byKey(Key('menu-$section')));
  }

  String entete(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(const Key('entete-recettes')),
          matching: find.byType(Text),
        ),
      )
      .last
      .data!;

  testWidgets(
    'recettes : nombre dans l\'en-tête selon l\'onglet et le filtre',
    (tester) async {
      final depot = DepotMemoire();
      await FrigoController(
        depot,
      ).enregistrer(const Aliment(id: 'l', nom: 'Lait', quantite: 2));
      await lancer(tester, depot);
      await ouvrirMenu(tester, 'recettes');
      expect(entete(tester), endsWith('propositions'));
      await toucher(tester, find.text('Carnet'));
      expect(entete(tester), '72 recettes');
      // Puces de style : liste horizontale, à faire défiler.
      final boisson = find.byKey(const Key('style-boisson'));
      await tester.scrollUntilVisible(
        boisson,
        150,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
            )
            .last,
      );
      await toucher(tester, boisson);
      expect(entete(tester), '4 recettes · Boisson');
      await tester.enterText(find.byType(TextField).first, 'chocolat');
      await tester.pumpAndSettle();
      expect(entete(tester), '1 recette · Boisson · « chocolat »');

      await toucher(tester, find.text('Chocolat chaud'));
      expect(find.text('Conseils'), findsOneWidget);
      expect(find.byKey(const Key('conseils-recette')), findsOneWidget);
    },
  );

  testWidgets('recette perso : conseils enregistrés', (tester) async {
    final depot = DepotMemoire();
    await lancer(tester, depot);
    await ouvrirMenu(tester, 'recettes');
    await toucher(tester, find.byTooltip('Ajouter une recette'));
    await tester.enterText(find.byType(TextFormField).first, 'Kir');
    final conseils = find.byKey(const Key('champ-conseils'));
    await tester.ensureVisible(conseils);
    await tester.enterText(conseils, 'Bien frais.');
    await toucher(tester, find.byKey(const Key('bouton-enregistrer')));
    expect(
      (await depot.lire(RecettesController.cle)).single['conseils'],
      'Bien frais.',
    );
  });

  testWidgets('cave : adresse d\'origine et niveau d\'une bouteille', (
    tester,
  ) async {
    final depot = DepotMemoire();
    await AnnuaireController(depot).enregistrer(
      const Adresse(
        id: 'dom',
        nom: 'Domaine des Lilas',
        type: TypeAdresse.commerce,
      ),
    );
    await CaveController(
      depot,
    ).enregistrer(const Bouteille(id: 'b', nom: 'Chablis', quantite: 2));
    await lancer(tester, depot);
    await toucher(tester, find.byKey(const Key('tuile-bouteilles')));
    await toucher(tester, find.text('Chablis'));
    await toucher(tester, find.byKey(const Key('champ-adresse-origine')));
    await toucher(tester, find.byKey(const Key('choix-adresse-dom')));
    expect(find.text('Domaine des Lilas'), findsOneWidget);
    final curseur = find.byKey(const Key('curseur-niveau'));
    await tester.ensureVisible(curseur);
    await tester.pumpAndSettle();
    await tester.tap(curseur);
    await tester.pumpAndSettle();
    await toucher(tester, find.byKey(const Key('bouton-enregistrer')));

    final b = Bouteille.fromJson((await depot.lire(CaveController.cle)).single);
    expect(b.adresseId, 'dom');
    expect(b.niveau, 50);
    expect(find.text('Domaine des Lilas'), findsOneWidget);
    expect(find.byKey(const Key('niveau-b')), findsOneWidget);
  });

  testWidgets('frigo : variante et icône sur la carte', (tester) async {
    final depot = DepotMemoire();
    await FrigoController(depot).enregistrer(
      const Aliment(
        id: 'a',
        nom: 'Pommes de terre',
        variante: 'grenailles',
        categorie: 'Fruits et légumes',
      ),
    );
    await lancer(tester, depot);
    await toucher(tester, find.byKey(const Key('tuile-aliments')));
    expect(find.text('Pommes de terre · grenailles'), findsOneWidget);
    expect(find.byIcon(Icons.eco_outlined), findsOneWidget);

    // Nouvel aliment du même nom : la variante est proposée.
    await toucher(tester, find.byTooltip('Ajouter un aliment'));
    expect(find.byKey(const Key('choix-variante')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('champ-nom-aliment')),
      'pommes de terre',
    );
    await tester.pumpAndSettle();
    await toucher(tester, find.byKey(const Key('choix-variante')));
    await toucher(tester, find.text('grenailles').last);
    await toucher(tester, find.byKey(const Key('bouton-enregistrer')));
    expect(find.text('pommes de terre · grenailles'), findsOneWidget);
  });
}
