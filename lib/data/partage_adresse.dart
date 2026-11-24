import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import '../models/adresse.dart';

/// Propose un texte aux autres applications (menu de partage de l'appareil).
/// Renvoie false si l'appareil n'a pas de menu de partage.
typedef Partager = Future<bool> Function(String texte, String sujet);

Future<bool> partagerNatif(String texte, String sujet) async {
  try {
    final r = await SharePlus.instance.share(
      ShareParams(text: texte, subject: sujet, mailToFallbackEnabled: false),
    );
    return r.status != ShareResultStatus.unavailable;
  } catch (_) {
    return false;
  }
}

/// Page des liens de partage (dossier `site/`). L'adresse est entièrement
/// dans la partie après « # », qui n'est jamais envoyée au serveur.
const hoteLien = 'jubidatiloki.github.io';
const cheminLien = '/mytinymess/';

/// Champs partagés : ni « Recommandé par », ni favori, ni étiquettes (privés).
const _champs = [
  'id',
  'nom',
  'type',
  'description',
  'telephone',
  'email',
  'site',
  'lieu',
  'quand',
  'avis',
];

/// Lien qui ajoute l'adresse dans l'application de la personne qui le reçoit.
/// Le « .z » final évite qu'une messagerie ne coupe un tiret en fin de lien.
Uri lienPartage(Adresse a) {
  final json = a.toJson();
  final code = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            for (final c in _champs)
              if (json[c] != null && json[c] != '') c: json[c],
          }),
        ),
      )
      .replaceAll('=', '');
  return Uri.parse('https://$hoteLien$cheminLien#1.$code.z');
}

/// Message complet : la fiche, puis le lien.
String textePartage(Adresse a) =>
    '${a.enTexte}\n\nAjouter à My Tiny Mess :\n${lienPartage(a)}';

/// Adresse contenue dans un lien reçu, null si ce n'en est pas un (lien
/// incomplet, modifié, ou d'un autre site).
Adresse? lireLienPartage(Uri lien) {
  final String code;
  if (lien.scheme == 'https' &&
      lien.host == hoteLien &&
      lien.path.startsWith(cheminLien)) {
    code = lien.fragment;
  } else if (lien.scheme == 'mytinymess' && lien.host == 'adresse') {
    code = lien.path.replaceFirst('/', '');
  } else {
    return null;
  }
  final m = RegExp(r'^1\.([A-Za-z0-9_-]{1,20000})\.z$').firstMatch(code);
  if (m == null) {
    return null;
  }
  try {
    final json = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(m[1]!))),
    );
    if (json is! Map) {
      return null;
    }
    final propre = <String, dynamic>{
      for (final c in _champs)
        if (json[c] is String && (json[c] as String).trim().isNotEmpty)
          c: (json[c] as String).trim(),
    };
    if (propre['nom'] == null ||
        !RegExp(r'^[A-Za-z0-9-]{1,64}$').hasMatch('${propre['id'] ?? ''}')) {
      return null;
    }
    return Adresse.fromJson(propre);
  } catch (_) {
    return null;
  }
}
