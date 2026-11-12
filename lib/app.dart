import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/depot.dart';
import 'screens/racine_screen.dart';
import 'state/bibliotheque_controller.dart';
import 'state/cave_controller.dart';
import 'state/lieux_controller.dart';
import 'state/preferences_controller.dart';
import 'theme.dart';

class MyTinyMessApp extends StatefulWidget {
  const MyTinyMessApp({super.key, required this.depot, this.preferences});

  final Depot depot;

  /// Préférences déjà chargées (par main.dart, pour ouvrir directement
  /// le bon thème). Sinon elles sont chargées ici.
  final PreferencesController? preferences;

  @override
  State<MyTinyMessApp> createState() => _MyTinyMessAppState();
}

class _MyTinyMessAppState extends State<MyTinyMessApp> {
  late final LieuxController _lieuxLivres;
  late final LieuxController _lieuxCave;
  late final BibliothequeController _bibliotheque;
  late final CaveController _cave;
  late final PreferencesController _preferences;

  @override
  void initState() {
    super.initState();
    final depot = widget.depot;
    _lieuxLivres = LieuxController(depot, LieuxController.cleLivres)..charger();
    _lieuxCave = LieuxController(depot, LieuxController.cleCave);
    _bibliotheque = BibliothequeController(depot, lieux: _lieuxLivres)
      ..charger();
    _cave = CaveController(depot, lieux: _lieuxCave);
    // Les anciennes zones de la cave deviennent des lieux une fois tout lu.
    Future.wait([
      _lieuxCave.charger(),
      _cave.charger(),
    ]).then((_) => _cave.migrerZones());
    _preferences =
        widget.preferences ?? (PreferencesController(depot)..charger());
  }

  @override
  void dispose() {
    for (final c in [_lieuxLivres, _lieuxCave, _bibliotheque, _cave]) {
      c.dispose();
    }
    if (widget.preferences == null) {
      _preferences.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _preferences,
      builder: (context, _) => MaterialApp(
        title: 'My Tiny Mess',
        debugShowCheckedModeBanner: false,
        theme: construireTheme(Brightness.light),
        darkTheme: construireTheme(Brightness.dark),
        themeMode: _preferences.theme.mode,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: RacineScreen(
          bibliotheque: _bibliotheque,
          lieuxLivres: _lieuxLivres,
          cave: _cave,
          lieuxCave: _lieuxCave,
          preferences: _preferences,
        ),
      ),
    );
  }
}
