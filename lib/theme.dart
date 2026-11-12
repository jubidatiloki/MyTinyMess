import 'package:flutter/material.dart';

/// Palette de l'application (maquette : vert + gris anthracite).
class Couleurs {
  Couleurs._();

  /// Vert des barres de titre et du menu latéral.
  static const vert = Color(0xFF4A9D60);

  /// Fond des écrans en thème sombre.
  static const fondSombre = Color(0xFF454545);

  /// Fond des écrans en thème clair.
  static const fondClair = Color(0xFFF2F2F2);
}

ThemeData construireTheme(Brightness luminosite) {
  final sombre = luminosite == Brightness.dark;
  final schema =
      ColorScheme.fromSeed(
        seedColor: Couleurs.vert,
        brightness: luminosite,
      ).copyWith(
        primary: sombre ? const Color(0xFF7CCB91) : Couleurs.vert,
        onPrimary: sombre ? Colors.black : Colors.white,
        surface: sombre ? Couleurs.fondSombre : Couleurs.fondClair,
        onSurface: sombre ? Colors.white : const Color(0xFF1E1E1E),
      );
  return ThemeData(
    colorScheme: schema,
    useMaterial3: true,
    scaffoldBackgroundColor: schema.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Couleurs.vert,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Couleurs.vert,
      shape: RoundedRectangleBorder(),
      endShape: RoundedRectangleBorder(),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Couleurs.vert,
      foregroundColor: Colors.white,
    ),
  );
}
