import 'package:url_launcher/url_launcher.dart';

/// Ouvre un lien hors de l'application (téléphone, e-mail, navigateur…).
/// Renvoie false si rien n'a pu l'ouvrir.
typedef OuvrirLien = Future<bool> Function(Uri lien);

Future<bool> ouvrirLienExterne(Uri lien) async {
  try {
    return await launchUrl(lien, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
