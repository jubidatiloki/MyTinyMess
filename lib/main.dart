import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/base/ouvrir_base.dart';
import 'data/depot.dart';
import 'data/depot_base.dart';
import 'data/fusion_lieux.dart';
import 'state/bibliotheque_controller.dart';
import 'state/cave_controller.dart';
import 'state/lieux_controller.dart';
import 'state/preferences_controller.dart';

/// Tout ce qui est enregistré par l'application.
const clesDonnees = [
  BibliothequeController.cle,
  CaveController.cle,
  LieuxController.cle,
  // Anciennes clés (versions 0.3 à 0.5), fusionnées ensuite dans « lieux ».
  LieuxController.ancienneCleLivres,
  LieuxController.ancienneCleCave,
  PreferencesController.cle,
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final depot = DepotBase(await ouvrirBase());
  // Données saisies avant la base de données (versions ≤ 0.4) : reprises
  // une seule fois. L'ancien stockage n'est pas effacé (copie de secours).
  await depot.reprendreDepuis(
    DepotPreferences(await SharedPreferences.getInstance()),
    clesDonnees,
  );
  // Emplacements des versions précédentes : listes réunies (≤ 0.5) et
  // type livres / cave attribué selon le contenu (0.6).
  await fusionnerAnciensLieux(depot);
  await typerLieux(depot);
  // Chargées avant l'affichage : l'appli s'ouvre directement dans le bon
  // thème et sur le bon écran.
  final preferences = PreferencesController(depot);
  await preferences.charger();
  runApp(MyTinyMessApp(depot: depot, preferences: preferences));
}
