import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// Téléphone (Android) et ordinateur (Windows) : un fichier dans le dossier
/// de données de l'application.
Future<Database> ouvrirBase() async {
  final dossier = await getApplicationSupportDirectory();
  return databaseFactoryIo.openDatabase(
    p.join(dossier.path, 'my_tiny_mess.db'),
  );
}
