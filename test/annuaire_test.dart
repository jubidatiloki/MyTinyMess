import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/app.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/main.dart';
import 'package:my_tiny_mess/models/adresse.dart';
import 'package:my_tiny_mess/state/annuaire_controller.dart';

const _boulanger = Adresse(
  id: 'b',
  nom: 'Au bon pain',
  type: TypeAdresse.commerce,
  description: 'Boulanger',
  telephone: '+33 (0)4 78 00 00 00',
  site: 'www.aubonpain.example.fr',
  lieu: '3 rue des Lilas, Lyon',
  recommandePar: 'Camille',
  avis: 'Le meilleur pain aux noix.',
  etiquettes: ['Lyon', 'gourmand'],
);
const _festival = Adresse(
  id: 'f',
  nom: 'Jazz d\'été',
  type: TypeAdresse.festival,
  etiquettes: ['lyon'],
  favori: true,
);

void main() {
  test('adresse : enregistrement et relecture complètes', () async {
    expect(clesDonnees, contains(AnnuaireController.cle));
    final depot = DepotMemoire();
    await AnnuaireController(depot).enregistrer(_boulanger);
    final relu = AnnuaireController(depot);
    await relu.charger();
    expect(relu.elements.single.toJson(), _boulanger.toJson());
  });

  test('liens : seuls http et https, téléphone nettoyé', () {
    expect(_boulanger.lienSite.toString(), 'https://www.aubonpain.example.fr');
    expect(_boulanger.lienTelephone.toString(), 'tel:+330478000000');
    expect(_boulanger.lienCarte!.queryParameters['query'], contains('Lilas'));
    expect(Adresse.lienWeb('http://a.fr/x?y=1'), isNotNull);
    for (final mauvais in [
      'javascript:alert(1)',
      'file:///etc/passwd',
      'pas un site',
      'exemple',
      '',
      null,
    ]) {
      expect(Adresse.lienWeb(mauvais), isNull, reason: '$mauvais');
    }
  });

  test('fiche à partager : sans la personne qui a recommandé', () {
    expect(_boulanger.enTexte, contains('Commerçant · Boulanger'));
    expect(_boulanger.enTexte, contains('pain aux noix'));
    expect(_boulanger.enTexte, isNot(contains('Camille')));
  });

  test('recherche, étiquettes et favoris', () async {
    final c = AnnuaireController(DepotMemoire());
    await c.enregistrer(_festival);
    await c.enregistrer(_boulanger);
    expect(c.rechercher().map((a) => a.id), ['b', 'f']);
    expect(c.rechercher(texte: 'ete').single.id, 'f');
    expect(c.rechercher(etiquette: 'LYON'), hasLength(2));
    expect(c.rechercher(type: TypeAdresse.commerce).single.id, 'b');
    expect(c.rechercher(favoris: true).single.id, 'f');
    expect(c.etiquettes, ['gourmand', 'lyon']);
    expect(Adresse.lireEtiquettes(' Lyon, , lyon,vélo '), ['Lyon', 'vélo']);
  });

  Future<void> lancer(
    WidgetTester tester,
    DepotMemoire depot, {
    List<Uri>? liens,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MyTinyMessApp(
        depot: depot,
        chargerRecettesIntegrees: () async => [],
        ouvrirLien: (l) async {
          liens?.add(l);
          return liens != null;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tuile-adresses')));
    await tester.pumpAndSettle();
  }

  testWidgets('ajouter une adresse (avec vérification des champs)', (
    tester,
  ) async {
    final depot = DepotMemoire();
    await lancer(tester, depot);
    await tester.tap(find.byTooltip('Ajouter une adresse'));
    await tester.pumpAndSettle();
    final enregistrer = find.byKey(const Key('bouton-enregistrer'));
    await tester.tap(enregistrer);
    await tester.pumpAndSettle();
    expect(find.text('Le nom est obligatoire'), findsOneWidget);

    Future<void> saisir(String cle, String texte) async {
      final f = find.byKey(Key('champ-adresse-$cle'));
      await tester.ensureVisible(f);
      await tester.enterText(f, texte);
    }

    await saisir('nom', 'Sam');
    await saisir('site', 'pas un site');
    await tester.tap(enregistrer);
    await tester.pumpAndSettle();
    expect(find.text('Adresse de site non valable'), findsOneWidget);
    await saisir('site', 'sam.example.org');
    await saisir('etiquettes', 'bricolage, Lyon');
    await tester.tap(enregistrer);
    await tester.pumpAndSettle();
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Personnes'), findsWidgets);
    final a = (await depot.lire('annuaire')).single;
    expect(a['type'], 'personne');
    expect(a['etiquettes'], ['bricolage', 'Lyon']);
  });

  testWidgets('filtrer, consulter, ouvrir, copier, supprimer', (tester) async {
    final depot = DepotMemoire();
    final c = AnnuaireController(depot);
    await c.enregistrer(_boulanger);
    await c.enregistrer(_festival);
    final liens = <Uri>[];
    String? copie;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (appel) async {
        if (appel.method == 'Clipboard.setData') {
          copie = (appel.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await lancer(tester, depot, liens: liens);
    expect(find.text('2 bonnes adresses'), findsOneWidget);
    final commerces = find.byKey(const Key('filtre-type-commerce'));
    await tester.ensureVisible(commerces);
    await tester.pumpAndSettle();
    await tester.tap(commerces);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adresse-f')), findsNothing);

    await tester.tap(find.text('Au bon pain'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ligne-Téléphone')));
    await tester.tap(find.byKey(const Key('ligne-Site')));
    await tester.pumpAndSettle();
    expect(liens.map((l) => l.scheme), ['tel', 'https']);

    await tester.tap(find.byKey(const Key('copier-fiche')));
    await tester.pumpAndSettle();
    expect(copie, _boulanger.enTexte);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect((await depot.lire('annuaire')).single['id'], 'f');
    // Le filtre « commerçants » n'a plus d'objet : le festival réapparaît.
    expect(find.byKey(const Key('adresse-f')), findsOneWidget);
  });

  testWidgets('lien impossible à ouvrir : message', (tester) async {
    final depot = DepotMemoire();
    await AnnuaireController(depot).enregistrer(_boulanger);
    await lancer(tester, depot);
    await tester.tap(find.text('Au bon pain'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ligne-Site')));
    await tester.pumpAndSettle();
    expect(find.textContaining('pu ouvrir ce lien'), findsOneWidget);
  });
}
