import 'package:flutter/material.dart';

import '../state/collection_controller.dart';

/// Icône d'une catégorie d'aliments, d'après les mots de son nom : marche
/// aussi pour les catégories créées par l'utilisateur (« Légumes du
/// jardin »…). Sans correspondance : le frigo.
IconData iconeCategorie(String? categorie) {
  final n = normaliser(categorie ?? '');
  bool a(List<String> mots) => mots.any(n.contains);
  if (n.isEmpty) {
    return Icons.kitchen_outlined;
  }
  if (a(['surgel', 'congel', 'glace'])) {
    return Icons.ac_unit;
  }
  if (a(['fromage'])) {
    return Icons.pie_chart_outline;
  }
  if (a(['lait', 'yaourt', 'creme', 'beurre'])) {
    return Icons.local_drink_outlined;
  }
  // « œ » devient « o » une fois normalisé : on lit aussi le nom brut.
  final brut = (categorie ?? '').toLowerCase();
  if (a(['oeuf']) || (brut.contains('œuf') && !brut.contains('bœuf'))) {
    return Icons.egg_outlined;
  }
  if (a(['poisson', 'fruits de mer', 'crustace', 'mer'])) {
    return Icons.set_meal_outlined;
  }
  if (a(['viande', 'charcut', 'volaille', 'boucher'])) {
    return Icons.kebab_dining_outlined;
  }
  if (a(['fruit', 'legume', 'salade', 'herbe'])) {
    return Icons.eco_outlined;
  }
  if (a(['boisson', 'jus', 'vin', 'biere', 'soda', 'eau'])) {
    return Icons.local_bar_outlined;
  }
  if (a(['sucre', 'gateau', 'biscuit', 'dessert', 'chocolat', 'confiserie'])) {
    return Icons.cookie_outlined;
  }
  if (a(['condiment', 'sauce', 'epice', 'aromate'])) {
    return Icons.soup_kitchen_outlined;
  }
  if (a(['epicerie', 'feculent', 'pate', 'riz', 'cereale', 'conserve'])) {
    return Icons.rice_bowl_outlined;
  }
  if (a(['pain', 'boulang', 'viennois'])) {
    return Icons.bakery_dining_outlined;
  }
  return Icons.kitchen_outlined;
}
