import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/depot.dart';
import 'state/preferences_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final depot = DepotPreferences(await SharedPreferences.getInstance());
  // Chargées avant l'affichage : l'appli s'ouvre directement dans le bon
  // thème et sur le bon écran.
  final preferences = PreferencesController(depot);
  await preferences.charger();
  runApp(MyTinyMessApp(depot: depot, preferences: preferences));
}
