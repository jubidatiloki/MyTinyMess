import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_tiny_mess/data/depot.dart';
import 'package:my_tiny_mess/data/recherche_recettes.dart';
import 'package:my_tiny_mess/models/agenda.dart';
import 'package:my_tiny_mess/models/aliment.dart';
import 'package:my_tiny_mess/models/recette.dart';
import 'package:my_tiny_mess/state/agenda_controller.dart';
import 'package:my_tiny_mess/state/frigo_controller.dart';
import 'package:my_tiny_mess/state/recettes_controller.dart';

const _omelette = Recette(
  id: 'omelette',
  nom: 'Omelette',
  styles: {StyleRecette.rapide, StyleRecette.light},
  ingredients: [
    Ingredient(nom: 'œufs', quantite: '4'),
    Ingredient(nom: 'ciboulette'),
    Ingredient(nom: 'sel', placard: true),
  ],
);
const _gratin = Recette(
  id: 'gratin',
  nom: 'Gratin',
  styles: {StyleRecette.gourmand},
  ingredients: [
    Ingredient(nom: 'pommes de terre', quantite: '1 kg'),
    Ingredient(nom: 'crème', quantite: '20 cl'),
    Ingredient(nom: 'fromage râpé'),
  ],
);
const _tarte = Recette(
  id: 'tarte',
  nom: 'Tarte aux poireaux',
  ingredients: [
    Ingredient(nom: 'poireaux'),
    Ingredient(nom: 'pâte brisée'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ingrédients', () {
    test('correspondance avec les aliments du frigo', () {
      expect(motsCles('Pommes de terre'), ['pomme', 'terre']);
      expect(motsCles('Œufs bio'), ['oeuf']);
      const oeufs = Ingredient(nom: 'œufs');
      expect(ingredientDisponible(oeufs, ['Oeufs frais']), isTrue);
      expect(ingredientDisponible(oeufs, ['Lait']), isFalse);
      expect(
        ingredientDisponible(const Ingredient(nom: 'pommes de terre'), [
          'Pomme de terre',
        ]),
        isTrue,
      );
    });

    test('lecture d\'une ligne saisie', () {
      final a = Ingredient.depuisLigne('200 g de farine');
      expect(a.quantite, '200 g');
      expect(a.nom, 'farine');
      final b = Ingredient.depuisLigne('3 œufs');
      expect(b.quantite, '3');
      expect(b.nom, 'œufs');
      expect(Ingredient.depuisLigne('Sel').nom, 'Sel');
    });
  });

  group('Recettes', () {
    test('le carnet intégré se charge (fichier fourni)', () async {
      final ctrl = RecettesController(DepotMemoire());
      await ctrl.charger();
      expect(ctrl.integrees.length, greaterThanOrEqualTo(30));
      expect(
        ctrl.integrees.every((r) => r.source == SourceRecette.integree),
        isTrue,
      );
    });

    test(
      'propositions selon le frigo, par style, avec les manquants',
      () async {
        final ctrl = RecettesController(
          DepotMemoire(),
          chargerIntegrees: () async => [_omelette, _gratin, _tarte],
        );
        await ctrl.charger();
        final frigo = [
          const Aliment(id: '1', nom: 'Oeufs', quantite: 6),
          const Aliment(id: '2', nom: 'Ciboulette'),
          const Aliment(id: '3', nom: 'Crème fraîche'),
          const Aliment(id: '4', nom: 'Poireaux', quantite: 0), // épuisé
        ];
        final s = ctrl.suggestions(frigo);
        // L'omelette est complète (le sel est au placard) ; la tarte, avec
        // des poireaux épuisés, n'est pas proposée.
        expect(s.map((x) => x.recette.id), ['omelette', 'gratin']);
        expect(s.first.complete, isTrue);
        expect(s[1].manquants.map((i) => i.nom), [
          'pommes de terre',
          'fromage râpé',
        ]);
        expect(
          ctrl
              .suggestions(frigo, style: StyleRecette.gourmand)
              .single
              .recette
              .id,
          'gratin',
        );
      },
    );

    test('recettes personnelles et ajout d\'une recette en ligne', () async {
      final depot = DepotMemoire();
      final ctrl = RecettesController(
        depot,
        chargerIntegrees: () async => [_omelette],
      );
      await ctrl.charger();
      final enLigne = _gratin.copie(
        id: 'mealdb-1',
        source: SourceRecette.enLigne,
      );
      final copie = await ctrl.ajouterAuCarnet(enLigne);
      expect(copie.source, SourceRecette.perso);
      expect(copie.modifiable, isTrue);
      final relu = RecettesController(
        depot,
        chargerIntegrees: () async => [_omelette],
      );
      await relu.charger();
      expect(relu.toutes.map((r) => r.nom), ['Gratin', 'Omelette']);
      expect(relu.rechercher(texte: 'creme').single.nom, 'Gratin');
      expect(relu.rechercher(style: StyleRecette.light).single.nom, 'Omelette');
    });
  });

  group('Agenda', () {
    test('un repas par jour et par moment', () async {
      final repas = RepasController(DepotMemoire());
      await repas.charger();
      final lundi = DateTime(2026, 11, 23);
      await repas.prevoir(lundi, MomentRepas.soir, recette: _omelette);
      await repas.prevoir(lundi, MomentRepas.soir, libelle: 'Restaurant');
      await repas.prevoir(lundi, MomentRepas.midi, recette: _gratin);
      expect(repas.elements, hasLength(2));
      expect(repas.du(lundi, MomentRepas.soir)!.libelle, 'Restaurant');
      expect(repas.du(lundi, MomentRepas.soir)!.recetteId, isNull);
      expect(repas.entre(DateTime(2026, 11, 23), 7), hasLength(2));
      expect(repas.entre(DateTime(2026, 11, 24), 7), isEmpty);
    });

    test('événements du jour triés par heure', () async {
      final ev = EvenementsController(DepotMemoire());
      await ev.charger();
      final jour = DateTime(2026, 11, 25);
      await ev.enregistrer(
        Evenement(id: 'b', titre: 'Dîner', date: jour, heure: '20:00'),
      );
      await ev.enregistrer(
        Evenement(id: 'a', titre: 'Dentiste', date: jour, heure: '09:30'),
      );
      await ev.enregistrer(
        Evenement(id: 'c', titre: 'Anniversaire', date: jour),
      );
      expect(ev.du(jour).map((e) => e.titre), [
        'Anniversaire',
        'Dentiste',
        'Dîner',
      ]);
      expect(ev.du(DateTime(2026, 11, 26)), isEmpty);
    });
  });

  group('Courses', () {
    test('ajout sans doublon, puis rangement dans le frigo', () async {
      final depot = DepotMemoire();
      final frigo = FrigoController(depot);
      await frigo.charger();
      await frigo.enregistrer(
        const Aliment(id: 'lait', nom: 'Lait', quantite: 1),
      );
      final courses = CoursesController(depot);
      await courses.charger();

      expect(await courses.ajouter('Lait', origine: 'Frigo'), isTrue);
      expect(await courses.ajouter('lait'), isFalse); // déjà là
      expect(
        await courses.ajouterIngredients([
          const Ingredient(nom: 'Beurre', quantite: '250 g'),
          const Ingredient(nom: 'Lait'),
        ]),
        1,
      );
      expect(courses.nombreAAcheter, 2);

      for (final a in courses.elements) {
        await courses.basculer(a.id);
      }
      expect(await courses.rangerDansFrigo(frigo), 2);
      expect(courses.elements, isEmpty);
      expect(frigo.parId('lait')!.quantite, 2); // +1 à l'existant
      final beurre = frigo.elements.firstWhere((a) => a.nom == 'Beurre');
      expect(beurre.contenance, '250 g');
    });
  });

  test('recherche en ligne (TheMealDB) lue correctement', () async {
    final recherche = RechercheRecettesEnLigne(
      client: MockClient(
        (r) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'meals': [
                {
                  'idMeal': '52772',
                  'strMeal': 'Teriyaki Chicken',
                  'strCategory': 'Chicken',
                  'strInstructions': 'Mix.\r\nCook.',
                  'strIngredient1': 'Chicken',
                  'strMeasure1': '1 lb',
                  'strIngredient2': 'Soy sauce',
                  'strMeasure2': '',
                  'strIngredient3': '',
                },
              ],
            }),
          ),
          200,
        ),
      ),
    );
    final r = (await recherche.chercher('chicken')).single;
    expect(r.nom, 'Teriyaki Chicken');
    expect(r.source, SourceRecette.enLigne);
    expect(r.ingredients.map((i) => i.libelle), ['1 lb Chicken', 'Soy sauce']);
    expect(r.etapes, 'Mix.\nCook.');
    expect(await recherche.chercher('  '), isEmpty);
  });
}
