import 'package:uuid/uuid.dart';

import '../data/depot.dart';
import '../models/agenda.dart';
import '../models/aliment.dart';
import '../models/recette.dart';
import 'collection_controller.dart';
import 'frigo_controller.dart';

/// Événements de l'agenda (clé `evenements`).
class EvenementsController extends CollectionController<Evenement> {
  EvenementsController(Depot depot) : super(depot, cle);

  static const cle = 'evenements';

  @override
  Evenement depuisJson(Map<String, dynamic> json) => Evenement.fromJson(json);
  @override
  Map<String, dynamic> versJson(Evenement element) => element.toJson();
  @override
  String idDe(Evenement element) => element.id;

  /// Événements d'un jour, triés par heure (journée entière d'abord).
  List<Evenement> du(DateTime jour) {
    final j = jourDe(jour);
    return elements.where((e) => jourDe(e.date) == j).toList()
      ..sort((a, b) => (a.heure ?? '').compareTo(b.heure ?? ''));
  }
}

/// Repas prévus (clé `repas`) : un par jour et par moment.
class RepasController extends CollectionController<RepasPrevu> {
  RepasController(Depot depot) : super(depot, cle);

  static const cle = 'repas';

  @override
  RepasPrevu depuisJson(Map<String, dynamic> json) => RepasPrevu.fromJson(json);
  @override
  Map<String, dynamic> versJson(RepasPrevu element) => element.toJson();
  @override
  String idDe(RepasPrevu element) => element.id;

  RepasPrevu? du(DateTime jour, MomentRepas moment) {
    final j = jourDe(jour);
    for (final r in elements) {
      if (jourDe(r.date) == j && r.moment == moment) {
        return r;
      }
    }
    return null;
  }

  /// Prévoit une recette (ou un texte libre) ; remplace ce qui était prévu.
  Future<void> prevoir(
    DateTime jour,
    MomentRepas moment, {
    Recette? recette,
    String? libelle,
  }) async {
    final existant = du(jour, moment);
    await enregistrer(
      RepasPrevu(
        id: existant?.id ?? const Uuid().v4(),
        date: jourDe(jour),
        moment: moment,
        recetteId: recette?.id,
        libelle: recette?.nom ?? libelle,
      ),
    );
  }

  /// Repas prévus du jour [debut] (inclus) à [debut] + [jours] (exclu).
  List<RepasPrevu> entre(DateTime debut, int jours) {
    final d = jourDe(debut);
    final f = DateTime(d.year, d.month, d.day + jours);
    return elements
        .where((r) => !jourDe(r.date).isBefore(d) && jourDe(r.date).isBefore(f))
        .toList();
  }
}

/// Liste de courses (clé `courses`).
class CoursesController extends CollectionController<ArticleCourses> {
  CoursesController(Depot depot, {DateTime Function()? maintenant})
    : _maintenant = maintenant ?? DateTime.now,
      super(depot, cle);

  static const cle = 'courses';
  final DateTime Function() _maintenant;

  @override
  ArticleCourses depuisJson(Map<String, dynamic> json) =>
      ArticleCourses.fromJson(json);
  @override
  Map<String, dynamic> versJson(ArticleCourses element) => element.toJson();
  @override
  String idDe(ArticleCourses element) => element.id;

  int get nombreAAcheter => elements.where((a) => !a.coche).length;

  /// Article pas encore acheté portant ce nom ?
  bool contient(String nom) => elements.any(
    (a) => !a.coche && normaliser(a.nom.trim()) == normaliser(nom.trim()),
  );

  /// Ajoute un article ; renvoie false s'il est déjà dans la liste.
  Future<bool> ajouter(String nom, {String? quantite, String? origine}) async {
    if (nom.trim().isEmpty || contient(nom)) {
      return false;
    }
    await enregistrer(
      ArticleCourses(
        id: const Uuid().v4(),
        nom: nom.trim(),
        quantite: quantite,
        origine: origine,
      ),
    );
    return true;
  }

  /// Ajoute des ingrédients (manquants d'une recette…) ; renvoie le nombre
  /// d'articles réellement ajoutés.
  Future<int> ajouterIngredients(
    Iterable<Ingredient> ingredients, {
    String? origine,
  }) async {
    var n = 0;
    for (final i in ingredients) {
      if (await ajouter(i.nom, quantite: i.quantite, origine: origine)) {
        n++;
      }
    }
    return n;
  }

  Future<void> basculer(String id) async {
    final a = parId(id);
    if (a != null) {
      await enregistrer(a.avecCoche(!a.coche));
    }
  }

  Future<void> supprimerCoches() async {
    for (final a in elements.where((a) => a.coche).toList()) {
      await supprimer(a.id);
    }
  }

  /// Range les articles cochés (achetés) dans le frigo : +1 si l'aliment y
  /// est déjà (même nom), sinon il est créé. Renvoie le nombre d'articles.
  Future<int> rangerDansFrigo(FrigoController frigo) async {
    final achetes = elements.where((a) => a.coche).toList();
    for (final article in achetes) {
      Aliment? existant;
      for (final al in frigo.elements) {
        if (normaliser(al.nom.trim()) == normaliser(article.nom.trim())) {
          existant = al;
          break;
        }
      }
      if (existant != null) {
        await frigo.ajouterUn(existant.id);
      } else {
        await frigo.enregistrer(
          Aliment(
            id: const Uuid().v4(),
            nom: article.nom,
            contenance: article.quantite,
            dateAjout: _maintenant(),
          ),
        );
      }
      await supprimer(article.id);
    }
    return achetes.length;
  }
}
