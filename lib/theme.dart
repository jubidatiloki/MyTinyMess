import 'package:flutter/material.dart';

/// Vert de l'application (accents : boutons, interrupteurs, sélection).
const vertOdv = Color(0xFF4A9D60);

/// Couleurs propres à l'application, en plus du thème Material.
/// Accès : `PaletteOdv.de(context)`.
@immutable
class PaletteOdv extends ThemeExtension<PaletteOdv> {
  const PaletteOdv({
    required this.menu,
    required this.menuTexte,
    required this.menuSelection,
    required this.menuSelectionTexte,
    required this.carte,
    required this.champ,
    required this.separateur,
    required this.accentDoux,
    required this.texteSecondaire,
  });

  /// Fond du menu latéral.
  final Color menu;
  final Color menuTexte;

  /// Pastille de la rubrique active (fond et texte).
  final Color menuSelection;
  final Color menuSelectionTexte;

  /// Cartes posées sur le fond des pages.
  final Color carte;

  /// Fond des champs de saisie et des petites pastilles d'icône.
  final Color champ;
  final Color separateur;

  /// Vert doux pour les titres de section.
  final Color accentDoux;
  final Color texteSecondaire;

  static const sombre = PaletteOdv(
    menu: Color(0xFF1E201F),
    menuTexte: Color(0xFFB9BCBA),
    menuSelection: Color(0xFF2E4A36),
    menuSelectionTexte: Color(0xFF9EE0AE),
    carte: Color(0xFF303331),
    champ: Color(0xFF3A3D3B),
    separateur: Color(0xFF3A3D3B),
    accentDoux: Color(0xFF8FCF9F),
    texteSecondaire: Color(0xFF9A9E9C),
  );

  static const clair = PaletteOdv(
    menu: Color(0xFFFFFFFF),
    menuTexte: Color(0xFF4B4F4D),
    menuSelection: Color(0xFFD7EEDD),
    menuSelectionTexte: Color(0xFF1F5C33),
    carte: Color(0xFFFFFFFF),
    champ: Color(0xFFEDEFEE),
    separateur: Color(0xFFE3E6E4),
    accentDoux: Color(0xFF2F7A45),
    texteSecondaire: Color(0xFF6B706D),
  );

  static PaletteOdv de(BuildContext context) =>
      Theme.of(context).extension<PaletteOdv>() ?? sombre;

  @override
  PaletteOdv copyWith() => this;

  @override
  PaletteOdv lerp(PaletteOdv? other, double t) {
    if (other == null) {
      return this;
    }
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return PaletteOdv(
      menu: m(menu, other.menu),
      menuTexte: m(menuTexte, other.menuTexte),
      menuSelection: m(menuSelection, other.menuSelection),
      menuSelectionTexte: m(menuSelectionTexte, other.menuSelectionTexte),
      carte: m(carte, other.carte),
      champ: m(champ, other.champ),
      separateur: m(separateur, other.separateur),
      accentDoux: m(accentDoux, other.accentDoux),
      texteSecondaire: m(texteSecondaire, other.texteSecondaire),
    );
  }
}

ThemeData construireTheme(Brightness luminosite) {
  final sombre = luminosite == Brightness.dark;
  final p = sombre ? PaletteOdv.sombre : PaletteOdv.clair;
  final fond = sombre ? const Color(0xFF262827) : const Color(0xFFF3F4F3);
  final texte = sombre ? const Color(0xFFECEDEC) : const Color(0xFF1E201F);
  final schema =
      ColorScheme.fromSeed(seedColor: vertOdv, brightness: luminosite).copyWith(
        primary: sombre ? const Color(0xFF7CCB91) : vertOdv,
        onPrimary: sombre ? const Color(0xFF0E2416) : Colors.white,
        surface: fond,
        onSurface: texte,
        onSurfaceVariant: p.texteSecondaire,
        surfaceContainerHighest: p.champ,
        outlineVariant: p.separateur,
      );
  final arrondi = BorderRadius.circular(12);
  return ThemeData(
    colorScheme: schema,
    useMaterial3: true,
    scaffoldBackgroundColor: fond,
    extensions: [p],
    appBarTheme: AppBarTheme(
      backgroundColor: fond,
      foregroundColor: texte,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: texte,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: p.menu,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      endShape: const RoundedRectangleBorder(),
    ),
    cardTheme: CardThemeData(
      color: p.carte,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: p.separateur, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.champ,
      border: OutlineInputBorder(
        borderRadius: arrondi,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: arrondi,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: arrondi,
        borderSide: BorderSide(color: schema.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: arrondi,
        borderSide: BorderSide(color: schema.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: arrondi,
        borderSide: BorderSide(color: schema.error, width: 1.5),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: vertOdv,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: StadiumBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.carte,
      selectedColor: p.menuSelection,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(color: texte),
      secondaryLabelStyle: TextStyle(color: p.menuSelectionTexte),
      checkmarkColor: p.menuSelectionTexte,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? vertOdv : null,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.transparent : null,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: vertOdv,
        foregroundColor: Colors.white,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.carte,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(color: p.carte),
  );
}
