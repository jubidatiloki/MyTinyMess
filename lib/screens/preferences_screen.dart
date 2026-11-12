import 'package:flutter/material.dart';

import '../models/section.dart';
import '../state/preferences_controller.dart';
import '../theme.dart';
import '../widgets/page.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key, required this.controller, this.menu});

  final PreferencesController controller;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: Section.preferences.libelle,
      sousTitre: 'Apparence et navigation',
      menu: menu,
      corps: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const TitreSection('Thème'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    for (final t in ChoixTheme.values) ...[
                      if (t != ChoixTheme.values.first)
                        const SizedBox(width: 10),
                      Expanded(
                        child: _VignetteTheme(
                          choix: t,
                          actif: controller.theme == t,
                          onTap: () => controller.changerTheme(t),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const TitreSection('Navigation'),
            CarteGroupe(
              enfants: [
                SwitchListTile(
                  key: const Key('pref-menu-fixe'),
                  secondary: const IconeCarree(Icons.view_sidebar_outlined),
                  title: const Text('Garder le menu ouvert'),
                  subtitle: const Text(
                    'Sur tablette et ordinateur. Sur téléphone, il s\'ouvre '
                    'avec ☰.',
                  ),
                  value: controller.menuFixe,
                  onChanged: controller.changerMenuFixe,
                ),
                ListTile(
                  leading: const IconeCarree(Icons.home_outlined),
                  title: const Text('Écran à l\'ouverture'),
                  subtitle: const Text('Ce que vous voyez en premier'),
                  trailing: _ChoixDemarrage(controller: controller),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste déroulante compacte pour l'écran d'ouverture.
class _ChoixDemarrage extends StatelessWidget {
  const _ChoixDemarrage({required this.controller});

  final PreferencesController controller;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: p.champ,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Section>(
          key: const Key('pref-demarrage'),
          value: controller.ecranDemarrage,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: p.carte,
          items: [
            for (final s in Section.demarrages)
              DropdownMenuItem(
                key: Key('demarrage-${s.name}'),
                value: s,
                child: Text(s.libelle),
              ),
          ],
          onChanged: (s) {
            if (s != null) {
              controller.changerEcranDemarrage(s);
            }
          },
        ),
      ),
    );
  }
}

/// Vignette d'aperçu d'un thème (mini fenêtre : menu + contenu).
class _VignetteTheme extends StatelessWidget {
  const _VignetteTheme({
    required this.choix,
    required this.actif,
    required this.onTap,
  });

  final ChoixTheme choix;
  final bool actif;
  final VoidCallback onTap;

  Widget _apercu(PaletteOdv p, Color fond) => Container(
    color: fond,
    padding: const EdgeInsets.all(5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 14,
          decoration: BoxDecoration(
            color: p.menuSelection,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: p.carte,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    const fondSombre = Color(0xFF1E201F);
    const fondClair = Color(0xFFF3F4F3);
    final apercu = switch (choix) {
      ChoixTheme.sombre => _apercu(PaletteOdv.sombre, fondSombre),
      ChoixTheme.clair => _apercu(PaletteOdv.clair, fondClair),
      ChoixTheme.systeme => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Container(color: fondSombre)),
          Expanded(child: Container(color: fondClair)),
        ],
      ),
    };
    final icone = switch (choix) {
      ChoixTheme.sombre => Icons.dark_mode_outlined,
      ChoixTheme.clair => Icons.light_mode_outlined,
      ChoixTheme.systeme => Icons.devices_outlined,
    };
    return InkWell(
      key: Key('theme-${choix.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: actif ? vertOdv : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(height: 52, child: apercu),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icone,
                  size: 16,
                  color: actif ? p.accentDoux : p.texteSecondaire,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    choix.libelle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: actif ? FontWeight.w600 : FontWeight.w400,
                      color: actif ? null : p.texteSecondaire,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
