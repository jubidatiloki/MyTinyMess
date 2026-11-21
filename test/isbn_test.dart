import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_tiny_mess/data/recherche_isbn.dart';
import 'package:my_tiny_mess/models/isbn.dart';

void main() {
  group('ISBN', () {
    test('normalisation et clé de contrôle', () {
      expect(normaliserIsbn('978-0-306-40615-7'), '9780306406157');
      expect(normaliserIsbn(' 9780306406157 '), '9780306406157');
      expect(normaliserIsbn('9780306406158'), isNull); // mauvaise clé
      expect(normaliserIsbn('0-306-40615-2'), '0306406152');
      expect(normaliserIsbn('080442957x'), '080442957X');
      expect(normaliserIsbn('12345'), isNull);
    });

    test('ISBN-10 vers ISBN-13 et code-barres de livre', () {
      expect(versIsbn13('0306406152'), '9780306406157');
      expect(versIsbn13('9780306406157'), '9780306406157');
      expect(estCodeBarresLivre('9780306406157'), isTrue);
      // Code-barres valide mais pas un livre (ne commence pas par 978/979).
      expect(estCodeBarresLivre('4006381333931'), isFalse);
    });
  });

  group('Recherche en ligne', () {
    http.Response json(Object corps) => http.Response.bytes(
      utf8.encode(jsonEncode(corps)),
      200,
      headers: {'content-type': 'application/json'},
    );

    test('Google Books trouve le livre', () async {
      final appels = <Uri>[];
      final recherche = RechercheIsbnEnLigne(
        client: MockClient((r) async {
          appels.add(r.url);
          return json({
            'items': [
              {
                'volumeInfo': {
                  'title': 'Le Petit Prince',
                  'authors': ['Antoine de Saint-Exupéry'],
                  'publishedDate': '1999-01-04',
                  'categories': ['Fiction'],
                },
              },
            ],
          });
        }),
      );
      final infos = await recherche.chercher('978-0-306-40615-7');
      expect(infos!.titre, 'Le Petit Prince');
      expect(infos.auteur, 'Antoine de Saint-Exupéry');
      expect(infos.annee, 1999);
      expect(infos.genre, 'Fiction');
      expect(appels.single.host, 'www.googleapis.com');
      expect(appels.single.queryParameters['q'], 'isbn:9780306406157');
    });

    test('rien chez Google : Open Library prend le relais', () async {
      final recherche = RechercheIsbnEnLigne(
        client: MockClient((r) async {
          if (r.url.host == 'www.googleapis.com') {
            return json({'totalItems': 0});
          }
          return json({
            'ISBN:9780306406157': {
              'title': 'Dune',
              'authors': [
                {'name': 'Frank Herbert'},
              ],
              'publish_date': 'mars 1965',
            },
          });
        }),
      );
      final infos = await recherche.chercher('9780306406157');
      expect(infos!.titre, 'Dune');
      expect(infos.auteur, 'Frank Herbert');
      expect(infos.annee, 1965);
    });

    test('introuvable partout : null ; ISBN invalide : aucun appel', () async {
      var appels = 0;
      final recherche = RechercheIsbnEnLigne(
        client: MockClient((r) async {
          appels++;
          return r.url.host == 'openlibrary.org' ? json({}) : json({});
        }),
      );
      expect(await recherche.chercher('9780306406157'), isNull);
      expect(appels, 2);
      expect(await recherche.chercher('123'), isNull);
      expect(appels, 2);
    });

    test('pas de connexion : erreur signalée', () async {
      final recherche = RechercheIsbnEnLigne(
        client: MockClient(
          (r) async => throw http.ClientException('hors ligne'),
        ),
      );
      expect(recherche.chercher('9780306406157'), throwsA(isA<Exception>()));
    });
  });
}
