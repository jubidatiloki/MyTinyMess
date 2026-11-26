import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/app.dart';
import 'package:my_tiny_mess/data/changelog.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/main.dart';
import 'package:my_tiny_mess/models/adresse.dart';
import 'package:my_tiny_mess/models/aliment.dart';
import 'package:my_tiny_mess/models/lieu.dart';
import 'package:my_tiny_mess/state/categories_controller.dart';
import 'package:my_tiny_mess/state/frigo_controller.dart';
import 'package:my_tiny_mess/state/lieux_controller.dart';
import 'package:my_tiny_mess/version.dart';

void main() {
  test('historique : version actuelle en tête, sans doublon', () {
    expect(historiqueVersions.first.version, kVersionApp);
    final versions = historiqueVersions.map((v) => v.version).toList();
    expect(versions.toSet(), hasLength(versions.length));
    for (final v in historiqueVersions) {
      expect(v.nouveautes, isNotEmpty, reason: v.version);
      expect(RegExp(r'^\d\d/\d\d/\d{4}$').hasMatch(v.date), isTrue);
    }
  });

  test('catégorie Fromages : nouvelle liste et liste existante', () async {
    final neuve = CategoriesController(DepotMemoire());
    await neuve.charger();
    expect(neuve.parNom('fromages'), isNotNull);

    // Liste d'une version précédente, sans « Fromages ».
    final depot = DepotMemoire();
    await depot.ecrire(CategoriesController.cle, [
      {'id': 'a', 'nom': 'Boissons'},
    ]);
    expect(clesDonnees, contains(CategoriesController.cleAjouts));
    final c = CategoriesController(depot);
    await c.charger();
    expect(c.elements.map((e) => e.nom), ['Boissons', 'Fromages']);
    // Supprimée par l'utilisateur : elle ne revient pas.
    await c.supprimer(c.parNom('Fromages')!.id);
    final relue = CategoriesController(depot);
    await relue.charger();
    expect(relue.elements.map((e) => e.nom), ['Boissons']);
  });

  test('type d\'adresse Application', () {
    final a = Adresse.fromJson({
      'id': 'x',
      'nom': 'Vinted',
      'type': 'application',
    });
    expect(a.type.libelle, 'Application');
  });

  test('niveau : gardé, remis à plein quand une unité est finie', () async {
    final c = FrigoController(DepotMemoire());
    await c.enregistrer(
      const Aliment(id: 'j', nom: 'Jus', quantite: 2, niveau: 50),
    );
    await c.ajouterUn('j');
    expect(c.parId('j')!.niveau, 50);
    await c.retirerUn('j');
    expect(c.parId('j')!.niveau, isNull);
    await c.changerQuantite('j', 2, niveau: 30);
    expect(Aliment.fromJson(c.parId('j')!.toJson()).niveau, 30);
    await c.changerQuantite('j', 2, niveau: 100);
    expect(c.parId('j')!.niveau, isNull);
    await c.changerQuantite('j', 0, niveau: 30);
    expect(c.parId('j')!.niveau, isNull);
  });

  test('seul emplacement d\'un type', () async {
    final lieux = LieuxController(DepotMemoire());
    expect(lieux.seulLieu(TypeLieu.frigo), isNull);
    final frigo = await lieux.creer('Frigo', type: TypeLieu.frigo);
    await lieux.creer('Étagère', type: TypeLieu.livres);
    expect(lieux.seulLieu(TypeLieu.frigo), frigo.id);
    await lieux.creer('Bac', parentId: frigo.id);
    expect(lieux.seulLieu(TypeLieu.frigo), isNull);
  });

  Future<void> lancer(WidgetTester tester, DepotMemoire depot) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MyTinyMessApp(depot: depot, chargerRecettesIntegrees: () async => []),
    );
    await tester.pumpAndSettle();
  }

  Future<void> toucher(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('frigo : choix d\'office, curseur dans la fiche et la liste', (
    tester,
  ) async {
    final depot = DepotMemoire();
    await depot.ecrire(CategoriesController.cle, [
      {'id': 'b', 'nom': 'Boissons'},
    ]);
    await depot.ecrire(CategoriesController.cleAjouts, [
      {'nom': 'Fromages'},
    ]);
    final frigo = await LieuxController(
      depot,
    ).creer('Frigo', type: TypeLieu.frigo);
    await lancer(tester, depot);
    await toucher(tester, find.byKey(const Key('tuile-aliments')));
    await toucher(tester, find.byTooltip('Ajouter un aliment'));
    await tester.enterText(
      find.byKey(const Key('champ-nom-aliment')),
      'Jus d\'orange',
    );
    expect(find.text('Plein (pas entamé)'), findsOneWidget);
    final curseur = find.byKey(const Key('curseur-niveau'));
    await tester.ensureVisible(curseur);
    await tester.pumpAndSettle();
    // Au milieu du curseur : 50 %.
    await tester.tap(curseur);
    await tester.pumpAndSettle();
    expect(find.text('Entamé : reste environ 50 %'), findsOneWidget);
    await toucher(tester, find.byKey(const Key('bouton-enregistrer')));

    final a = Aliment.fromJson((await depot.lire('aliments')).single);
    expect(a.categorie, 'Boissons');
    expect(a.lieuId, frigo.id);
    expect(a.niveau, 50);
    expect(find.byKey(Key('niveau-${a.id}')), findsOneWidget);

    // Dans la fenêtre de la quantité : on revient à « plein ».
    await toucher(tester, find.byKey(Key('quantite-${a.id}')));
    await tester.drag(
      find.byKey(const Key('curseur-niveau')),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();
    await toucher(tester, find.byKey(const Key('valider-quantite')));
    expect((await depot.lire('aliments')).single['niveau'], isNull);
    expect(find.byKey(Key('niveau-${a.id}')), findsNothing);
  });

  testWidgets('menu : écran Nouveautés', (tester) async {
    await lancer(tester, DepotMemoire());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await toucher(tester, find.byKey(const Key('menu-nouveautes')));
    expect(
      find.text(
        'Version $kVersionApp · ${historiqueVersions.first.date}'
        ' · actuelle',
      ),
      findsOneWidget,
    );
    expect(find.byKey(Key('version-$kVersionApp')), findsOneWidget);
  });
}
