import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/app.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/data/partage_adresse.dart';
import 'package:my_tiny_mess/models/adresse.dart';
import 'package:my_tiny_mess/state/annuaire_controller.dart';

const _boulanger = Adresse(
  id: 'b',
  nom: 'Au bon pain',
  type: TypeAdresse.commerce,
  description: 'Boulanger',
  lieu: '3 rue des Lilas, Lyon',
  recommandePar: 'Camille',
  avis: 'Le meilleur pain aux noix, dès 7 h — été compris.',
  etiquettes: ['Lyon'],
  favori: true,
);
const _festival = Adresse(
  id: 'f',
  nom: 'Jazz d\'été',
  type: TypeAdresse.festival,
  etiquettes: ['lyon'],
  favori: true,
);

void main() {
  test('lien de partage : aller-retour sans les champs privés', () {
    final lien = lienPartage(_boulanger);
    final attendu = {
      ..._boulanger.toJson(),
      'etiquettes': <String>[],
      'favori': false,
    }..remove('recommandePar');
    expect(lireLienPartage(lien)!.toJson(), attendu);
    // Forme utilisée par le bouton de la page web.
    expect(
      lireLienPartage(
        Uri.parse('mytinymess://adresse/${lien.fragment}'),
      )!.toJson(),
      attendu,
    );
    expect(textePartage(_boulanger), contains('$lien'));
    expect(textePartage(_boulanger), isNot(contains('Camille')));
  });

  test('liens abîmés ou étrangers refusés', () {
    String coder(Object? o) =>
        base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
    final code = lienPartage(_boulanger).fragment;
    const base = 'https://$hoteLien$cheminLien';
    for (final l in [
      'https://autre.example.org$cheminLien#$code',
      'https://$hoteLien/autre/#$code',
      'http://$hoteLien$cheminLien#$code',
      base,
      '$base#${code.substring(0, 30)}.z',
      '$base#2${code.substring(1)}',
      '$base#1.${coder(['x'])}.z',
      '$base#1.${coder({'id': 'a', 'nom': ' '})}.z',
      '$base#1.${coder({'nom': 'sans id'})}.z',
    ]) {
      expect(lireLienPartage(Uri.parse(l)), isNull, reason: l);
    }
    final bizarre = {
      'id': 'a',
      'nom': 'X',
      'avis': 3,
      'favori': true,
      'type': 'zz',
    };
    final a = lireLienPartage(Uri.parse('$base#1.${coder(bizarre)}.z'))!;
    expect(a.favori, isFalse);
    expect(a.avis, '');
    expect(a.type, TypeAdresse.autre);
  });

  test('Android et page web en accord avec l\'application', () {
    final manifeste = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifeste, contains('android:host="$hoteLien"'));
    expect(manifeste, contains('android:pathPrefix="$cheminLien"'));
    final page = File('site${cheminLien}index.html').readAsStringSync();
    for (final t in TypeAdresse.values) {
      expect(page, contains('${t.name}: \'${t.libelle}\''));
    }
    jsonDecode(File('site/.well-known/assetlinks.json').readAsStringSync());
  });

  Future<void> lancer(
    WidgetTester tester,
    DepotMemoire depot, {
    Partager? partager,
    Stream<Uri>? recus,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MyTinyMessApp(
        depot: depot,
        chargerRecettesIntegrees: () async => [],
        partager: partager ?? (_, _) async => false,
        liensRecus: recus,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('partager : menu de l\'appareil', (tester) async {
    final depot = DepotMemoire();
    await AnnuaireController(depot).enregistrer(_boulanger);
    final partages = <(String, String)>[];
    await lancer(
      tester,
      depot,
      partager: (texte, sujet) async {
        partages.add((texte, sujet));
        return true;
      },
    );
    await tester.tap(find.byKey(const Key('tuile-adresses')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Au bon pain'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('partager-fiche')));
    await tester.pumpAndSettle();
    expect(partages, [(textePartage(_boulanger), 'Au bon pain')]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('lien reçu : ajout, déjà présente, lien incomplet', (
    tester,
  ) async {
    final depot = DepotMemoire();
    await AnnuaireController(depot).enregistrer(_festival);
    // Lien présent avant l'ouverture de l'application.
    final recus = StreamController<Uri>()..add(lienPartage(_boulanger));
    await lancer(tester, depot, recus: recus.stream);
    expect(find.text('Ajouter cette adresse ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ajouter-adresse-recue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partager-fiche')), findsOneWidget);
    expect((await depot.lire('annuaire')).map((a) => a['id']), ['f', 'b']);

    recus.add(lienPartage(_festival));
    await tester.pumpAndSettle();
    expect(find.textContaining('déjà dans votre annuaire'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final annuaire = await depot.lire('annuaire');
    expect(annuaire, hasLength(2));
    // La fiche existante n'est pas touchée (favori, étiquettes).
    expect(annuaire.first, _festival.toJson());

    recus.add(Uri.parse('https://$hoteLien$cheminLien#abc'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ne contient pas d\'adresse'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('lien reçu : refus', (tester) async {
    final depot = DepotMemoire();
    final recus = StreamController<Uri>();
    await lancer(tester, depot, recus: recus.stream);
    recus.add(lienPartage(_boulanger));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Non merci'));
    await tester.pumpAndSettle();
    expect(await depot.lire('annuaire'), isEmpty);
  });
}
