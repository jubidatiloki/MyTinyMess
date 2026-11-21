import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/depot.dart';
import 'data/recherche_isbn.dart';
import 'screens/bibliotheque/scanner_isbn_screen.dart';
import 'screens/racine_screen.dart';
import 'state/bibliotheque_controller.dart';
import 'state/cave_controller.dart';
import 'state/frigo_controller.dart';
import 'state/lieux_controller.dart';
import 'state/preferences_controller.dart';
import 'state/types_bouteille_controller.dart';
import 'theme.dart';

class MyTinyMessApp extends StatefulWidget {
  const MyTinyMessApp({
    super.key,
    required this.depot,
    this.preferences,
    this.rechercheIsbn,
    this.scannerIsbn,
  });

  final Depot depot;

  /// Préférences déjà chargées (par main.dart, pour ouvrir directement
  /// le bon thème). Sinon elles sont chargées ici.
  final PreferencesController? preferences;

  /// Recherche par ISBN (par défaut : en ligne) et scanner (par défaut :
  /// appareil photo, si la plateforme en a un). Remplaçables dans les tests.
  final RechercheIsbn? rechercheIsbn;
  final ScannerIsbn? scannerIsbn;

  @override
  State<MyTinyMessApp> createState() => _MyTinyMessAppState();
}

class _MyTinyMessAppState extends State<MyTinyMessApp> {
  late final LieuxController _lieux;
  late final BibliothequeController _bibliotheque;
  late final CaveController _cave;
  late final TypesBouteilleController _types;
  late final FrigoController _frigo;
  late final PreferencesController _preferences;
  final _rechercheIsbn = RechercheIsbnEnLigne();

  @override
  void initState() {
    super.initState();
    final depot = widget.depot;
    // Emplacements (livres, cave, frigo).
    _lieux = LieuxController(depot);
    _bibliotheque = BibliothequeController(depot, lieux: _lieux)..charger();
    _cave = CaveController(depot, lieux: _lieux);
    _types = TypesBouteilleController(depot)..charger();
    _frigo = FrigoController(depot, lieux: _lieux)..charger();
    // Les anciennes zones de la cave deviennent des lieux une fois tout lu.
    Future.wait([
      _lieux.charger(),
      _cave.charger(),
    ]).then((_) => _cave.migrerZones());
    _preferences =
        widget.preferences ?? (PreferencesController(depot)..charger());
  }

  @override
  void dispose() {
    for (final c in [_lieux, _bibliotheque, _cave, _types, _frigo]) {
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
          lieux: _lieux,
          cave: _cave,
          types: _types,
          frigo: _frigo,
          preferences: _preferences,
          rechercheIsbn: widget.rechercheIsbn ?? _rechercheIsbn,
          scannerIsbn:
              widget.scannerIsbn ??
              (scannerDisponible ? scannerIsbnCamera : null),
        ),
      ),
    );
  }
}
