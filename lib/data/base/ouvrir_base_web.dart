import 'package:sembast_web/sembast_web.dart';

/// Navigateur : base IndexedDB (persistante, propre à l'adresse du site).
Future<Database> ouvrirBase() =>
    databaseFactoryWeb.openDatabase('my_tiny_mess');
