import 'package:flutter/foundation.dart';

import '../data/recherche_recettes.dart';
import 'agenda_controller.dart';
import 'frigo_controller.dart';
import 'recettes_controller.dart';

/// Ce dont ont besoin les écrans Repas, Agenda et Courses : regroupé pour ne
/// pas passer six paramètres partout.
class Cuisine {
  const Cuisine({
    required this.recettes,
    required this.frigo,
    required this.courses,
    required this.repas,
    required this.evenements,
    this.enLigne,
  });

  final RecettesController recettes;
  final FrigoController frigo;
  final CoursesController courses;
  final RepasController repas;
  final EvenementsController evenements;

  /// Recherche de recettes sur Internet (null = indisponible).
  final RechercheRecettes? enLigne;

  /// Pour redessiner un écran dès que l'un d'eux change.
  Listenable get tout =>
      Listenable.merge([recettes, frigo, courses, repas, evenements]);
}
