import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/depot.dart';
import 'data/liens.dart';
import 'data/partage_adresse.dart';
import 'data/recherche_isbn.dart';
import 'data/recherche_recettes.dart';
import 'models/recette.dart';
import 'screens/annuaire/reception_adresse.dart';
import 'screens/bibliotheque/scanner_isbn_screen.dart';
import 'screens/racine_screen.dart';
import 'state/agenda_controller.dart';
import 'state/annuaire_controller.dart';
import 'state/bibliotheque_controller.dart';
import 'state/categories_controller.dart';
import 'state/cave_controller.dart';
import 'state/cuisine.dart';
import 'state/frigo_controller.dart';
import 'state/lieux_controller.dart';
import 'state/preferences_controller.dart';
import 'state/recettes_controller.dart';
import 'state/types_bouteille_controller.dart';
import 'theme.dart';

class MyTinyMessApp extends StatefulWidget {
  const MyTinyMessApp({
    super.key,
    required this.depot,
    this.preferences,
    this.rechercheIsbn,
    this.scannerIsbn,
    this.rechercheRecettes,
    this.chargerRecettesIntegrees,
    this.ouvrirLien = ouvrirLienExterne,
    this.partager = partagerNatif,
    this.liensRecus,
  });

  final Depot depot;

  /// Préférences déjà chargées (par main.dart, pour ouvrir directement
  /// le bon thème). Sinon elles sont chargées ici.
  final PreferencesController? preferences;

  /// Recherche par ISBN (par défaut : en ligne) et scanner (par défaut :
  /// appareil photo, si la plateforme en a un). Remplaçables dans les tests.
  final RechercheIsbn? rechercheIsbn;
  final ScannerIsbn? scannerIsbn;

  /// Recherche de recettes en ligne (par défaut : TheMealDB).
  final RechercheRecettes? rechercheRecettes;

  /// Lecture du carnet intégré (par défaut : fichier de l'appli).
  final Future<List<Recette>> Function()? chargerRecettesIntegrees;

  /// Ouverture des liens de l'annuaire (téléphone, e-mail, site, carte).
  final OuvrirLien ouvrirLien;

  /// Menu de partage de l'appareil.
  final Partager partager;

  /// Liens touchés hors de l'application (celui qui l'a ouverte, puis les
  /// suivants).
  final Stream<Uri>? liensRecus;

  @override
  State<MyTinyMessApp> createState() => _MyTinyMessAppState();
}

class _MyTinyMessAppState extends State<MyTinyMessApp> {
  late final LieuxController _lieux;
  late final BibliothequeController _bibliotheque;
  late final CaveController _cave;
  late final TypesBouteilleController _types;
  late final CategoriesController _categories;
  late final FrigoController _frigo;
  late final RecettesController _recettes;
  late final CoursesController _courses;
  late final RepasController _repas;
  late final EvenementsController _evenements;
  late final AnnuaireController _annuaire;
  late final Cuisine _cuisine;
  late final PreferencesController _preferences;
  final _rechercheIsbn = RechercheIsbnEnLigne();
  final _navigateur = GlobalKey<NavigatorState>();
  late final Future<void> _annuairePret;
  StreamSubscription<Uri>? _ecouteLiens;

  /// Liens traités l'un après l'autre.
  Future<void> _reception = Future.value();

  @override
  void initState() {
    super.initState();
    final depot = widget.depot;
    // Emplacements (livres, cave, frigo).
    _lieux = LieuxController(depot);
    _bibliotheque = BibliothequeController(depot, lieux: _lieux)..charger();
    _cave = CaveController(depot, lieux: _lieux);
    _types = TypesBouteilleController(depot)..charger();
    _categories = CategoriesController(depot);
    _frigo = FrigoController(depot, lieux: _lieux, categories: _categories);
    // Les catégories saisies librement avant rejoignent la liste.
    Future.wait([
      _categories.charger(),
      _frigo.charger(),
    ]).then((_) => _frigo.reprendreCategories());
    _recettes = RecettesController(
      depot,
      chargerIntegrees: widget.chargerRecettesIntegrees,
    )..charger();
    _courses = CoursesController(depot)..charger();
    _repas = RepasController(depot)..charger();
    _evenements = EvenementsController(depot)..charger();
    _annuaire = AnnuaireController(depot);
    _annuairePret = _annuaire.charger();
    _cuisine = Cuisine(
      recettes: _recettes,
      frigo: _frigo,
      courses: _courses,
      repas: _repas,
      evenements: _evenements,
      enLigne: widget.rechercheRecettes ?? RechercheRecettesEnLigne(),
    );
    // Les anciennes zones de la cave deviennent des lieux une fois tout lu.
    Future.wait([
      _lieux.charger(),
      _cave.charger(),
    ]).then((_) => _cave.migrerZones());
    _preferences =
        widget.preferences ?? (PreferencesController(depot)..charger());
    _ecouteLiens = widget.liensRecus?.listen(
      (lien) => _reception = _reception.then((_) => _recevoir(lien)),
      onError: (_) {},
    );
  }

  Future<void> _recevoir(Uri lien) async {
    // Annuaire lu et premier écran affiché (lien qui ouvre l'application).
    await _annuairePret;
    if (_navigateur.currentState == null) {
      await WidgetsBinding.instance.endOfFrame;
    }
    final navigateur = _navigateur.currentState;
    if (!mounted || navigateur == null) {
      return;
    }
    await recevoirAdresse(
      navigateur,
      lien: lien,
      annuaire: _annuaire,
      ouvrirLien: widget.ouvrirLien,
      partager: widget.partager,
    );
  }

  @override
  void dispose() {
    _ecouteLiens?.cancel();
    for (final c in [
      _lieux,
      _bibliotheque,
      _cave,
      _types,
      _categories,
      _frigo,
      _recettes,
      _courses,
      _repas,
      _evenements,
      _annuaire,
    ]) {
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
        navigatorKey: _navigateur,
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
          categories: _categories,
          frigo: _frigo,
          preferences: _preferences,
          cuisine: _cuisine,
          annuaire: _annuaire,
          ouvrirLien: widget.ouvrirLien,
          partager: widget.partager,
          rechercheIsbn: widget.rechercheIsbn ?? _rechercheIsbn,
          scannerIsbn:
              widget.scannerIsbn ??
              (scannerDisponible ? scannerIsbnCamera : null),
        ),
      ),
    );
  }
}
