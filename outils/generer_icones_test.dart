// Génère les images de l'icône à partir du dessin de `lib/widgets/icone_app.dart`.
// À relancer seulement si l'icône change :
//   flutter test outils/generer_icones_test.dart
//   dart run flutter_launcher_icons
// (pas dans le dossier test/ : ne tourne pas avec les tests habituels).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tiny_mess/widgets/icone_app.dart';

Future<void> _ecrire(String chemin, int taille, PeintreIcone peintre) async {
  final enregistreur = ui.PictureRecorder();
  peintre.paint(Canvas(enregistreur), Size.square(taille.toDouble()));
  final image = await enregistreur.endRecording().toImage(taille, taille);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(chemin)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('génère les images de l\'icône', (tester) async {
    await tester.runAsync(() async {
      // Icône complète (carré arrondi vert) : web, Windows, Android ancien.
      await _ecrire('assets/icone/icone.png', 1024, const PeintreIcone());
      // Premier plan des icônes adaptatives Android (fond vert à part).
      // flutter_launcher_icons y ajoute une marge de 16 % : le dessin reste
      // dans la zone visible quelle que soit la forme (rond, goutte…).
      await _ecrire(
        'assets/icone/icone_premier_plan.png',
        1024,
        const PeintreIcone(fond: false),
      );
    });
    expect(File('assets/icone/icone.png').existsSync(), isTrue);
  });
}
