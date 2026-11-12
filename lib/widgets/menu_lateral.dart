import 'package:flutter/material.dart';

import '../models/section.dart';
import '../theme.dart';
import '../version.dart';

IconData iconeSection(Section s) => switch (s) {
  Section.accueil => Icons.dashboard_outlined,
  Section.bibliotheque => Icons.menu_book_outlined,
  Section.cave => Icons.wine_bar_outlined,
  Section.bazar => Icons.inventory_2_outlined,
  Section.preferences => Icons.settings_outlined,
  Section.aPropos => Icons.info_outline,
};

/// Menu latéral : logo, rubriques avec icônes, rubrique active en pastille.
class MenuLateral extends StatelessWidget {
  const MenuLateral({
    super.key,
    required this.courante,
    required this.onChoisir,
    this.fixe = false,
  });

  final Section courante;
  final ValueChanged<Section> onChoisir;

  /// Menu affiché en permanence à gauche (et non en tiroir).
  final bool fixe;

  static const largeurFixe = 248.0;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    Widget item(Section s) => _ItemMenu(
      section: s,
      actif: s == courante,
      onTap: () {
        if (!fixe) {
          Navigator.pop(context);
        }
        onChoisir(s);
      },
    );
    return Drawer(
      width: fixe ? largeurFixe : 280,
      elevation: fixe ? 0 : null,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: vertOdv,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_stories,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'My Tiny Mess',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final s in Section.collections) item(s),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Divider(color: p.separateur, height: 1),
                    ),
                    for (final s in Section.values)
                      if (!Section.collections.contains(s)) item(s),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  'Version $kVersionApp',
                  style: TextStyle(color: p.texteSecondaire, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.section,
    required this.actif,
    required this.onTap,
  });

  final Section section;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    final couleur = actif ? p.menuSelectionTexte : p.menuTexte;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: actif ? p.menuSelection : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('menu-${section.name}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Icon(iconeSection(section), size: 20, color: couleur),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    section.libelle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: couleur,
                      fontSize: 15,
                      fontWeight: actif ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
