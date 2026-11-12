import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/depot.dart';
import 'screens/accueil_screen.dart';
import 'state/bibliotheque_controller.dart';
import 'state/cave_controller.dart';

class MyTinyMessApp extends StatefulWidget {
  const MyTinyMessApp({super.key, required this.depot});

  final Depot depot;

  @override
  State<MyTinyMessApp> createState() => _MyTinyMessAppState();
}

class _MyTinyMessAppState extends State<MyTinyMessApp> {
  late final BibliothequeController _bibliotheque;
  late final CaveController _cave;

  @override
  void initState() {
    super.initState();
    _bibliotheque = BibliothequeController(widget.depot)..charger();
    _cave = CaveController(widget.depot)..charger();
  }

  @override
  void dispose() {
    _bibliotheque.dispose();
    _cave.dispose();
    super.dispose();
  }

  ThemeData _theme(Brightness luminosite) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B1E3A), // bordeaux
      brightness: luminosite,
    ),
    useMaterial3: true,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Tiny Mess',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AccueilScreen(bibliotheque: _bibliotheque, cave: _cave),
    );
  }
}
