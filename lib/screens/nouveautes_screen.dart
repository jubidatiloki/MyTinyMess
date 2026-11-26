import 'package:flutter/material.dart';

import '../data/changelog.dart';
import '../models/section.dart';
import '../theme.dart';
import '../version.dart';
import '../widgets/page.dart';

IconData _icone(TypeNouveaute t) => switch (t) {
  TypeNouveaute.ajout => Icons.add_circle_outline,
  TypeNouveaute.amelioration => Icons.auto_awesome_outlined,
  TypeNouveaute.correction => Icons.build_outlined,
};

/// Rubrique « Nouveautés » : les évolutions de chaque version, la plus
/// récente en haut.
class NouveautesScreen extends StatelessWidget {
  const NouveautesScreen({super.key, this.menu, this.versions});

  final Widget? menu;

  /// Historique affiché (par défaut, celui de l'application).
  final List<VersionApp>? versions;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    final liste = versions ?? historiqueVersions;
    return PageOdv(
      titre: Section.nouveautes.libelle,
      sousTitre: 'Vous utilisez la version $kVersionApp',
      menu: menu,
      corps: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          for (final v in liste) ...[
            TitreSection(
              v.version == kVersionApp
                  ? 'Version ${v.version} · ${v.date} · actuelle'
                  : 'Version ${v.version} · ${v.date}',
            ),
            CarteGroupe(
              key: Key('version-${v.version}'),
              enfants: [
                for (final n in v.nouveautes)
                  ListTile(
                    leading: Icon(
                      _icone(n.type),
                      color: n.type == TypeNouveaute.correction
                          ? p.texteSecondaire
                          : vertOdv,
                    ),
                    title: Text(n.texte),
                    subtitle: Text(n.type.libelle),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
