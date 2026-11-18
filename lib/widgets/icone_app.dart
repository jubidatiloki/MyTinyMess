import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Icône de l'application (« l'étagère ») : un livre, une bouteille et un
/// bocal posés sur une étagère, en blanc sur le vert de l'appli.
/// Dessinée ici pour servir partout : logo du menu, « À propos » et images de
/// lancement (générées par `outils/generer_icones.dart`).
class IconeApp extends StatelessWidget {
  const IconeApp({super.key, this.taille = 36, this.fond = true});

  final double taille;

  /// Carré arrondi vert derrière le dessin (sinon fond transparent).
  final bool fond;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: taille,
    child: CustomPaint(painter: PeintreIcone(fond: fond)),
  );
}

/// Dessin de l'icône, sur une grille de 512 × 512 mise à l'échelle.
/// [echelleContenu] < 1 réduit le dessin autour du centre (premier plan des
/// icônes adaptatives Android, qui rognent les bords).
class PeintreIcone extends CustomPainter {
  const PeintreIcone({this.fond = true, this.echelleContenu = 1});

  final bool fond;
  final double echelleContenu;

  static const _blanc = Color(0xFFFFFFFF);
  static const _pale = Color(0xFFE9F5EC);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);
    final p = Paint()..isAntiAlias = true;
    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

    if (fond) {
      canvas.drawRRect(rr(0, 0, 512, 512, 112), p..color = vertOdv);
    }

    // Le dessin est centré verticalement (sa boîte va de y 150 à 394).
    canvas.translate(256, 256);
    canvas.scale(echelleContenu);
    canvas.translate(-256, -272);

    // Étagère.
    canvas.drawRRect(rr(88, 372, 336, 22, 11), p..color = _blanc);
    // Livre debout, avec deux bandes.
    canvas.drawRRect(rr(112, 186, 58, 186, 10), p..color = _blanc);
    canvas.drawRRect(rr(124, 214, 34, 8, 4), p..color = vertOdv);
    canvas.drawRRect(rr(124, 236, 34, 8, 4), p..color = vertOdv);
    // Livre penché.
    canvas.save();
    canvas.translate(202, 372);
    canvas.rotate(-8 * math.pi / 180);
    canvas.translate(-202, -372);
    canvas.drawRRect(rr(180, 218, 44, 154, 8), p..color = _pale);
    canvas.restore();
    // Bouteille et son étiquette.
    final bouteille = Path()
      ..moveTo(276, 372)
      ..lineTo(276, 250)
      ..quadraticBezierTo(276, 222, 296, 206)
      ..lineTo(296, 150)
      ..lineTo(320, 150)
      ..lineTo(320, 206)
      ..quadraticBezierTo(340, 222, 340, 250)
      ..lineTo(340, 372)
      ..close();
    canvas.drawPath(bouteille, p..color = _blanc);
    canvas.drawRRect(rr(290, 270, 36, 46, 6), p..color = vertOdv);
    // Bocal et son couvercle.
    canvas.drawRRect(rr(356, 268, 56, 104, 14), p..color = _blanc);
    canvas.drawRRect(rr(350, 250, 68, 22, 8), p..color = _pale);

    canvas.restore();
  }

  @override
  bool shouldRepaint(PeintreIcone ancien) =>
      ancien.fond != fond || ancien.echelleContenu != echelleContenu;
}
