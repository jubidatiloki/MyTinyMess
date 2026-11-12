/// Ouverture de la base de données locale, selon la plateforme :
/// fichier sur téléphone / PC, IndexedDB dans le navigateur.
library;

export 'ouvrir_base_io.dart'
    if (dart.library.js_interop) 'ouvrir_base_web.dart';
