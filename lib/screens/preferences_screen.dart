import 'package:flutter/material.dart';

import '../models/section.dart';
import '../state/preferences_controller.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key, required this.controller, this.menu});

  final PreferencesController controller;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final titre = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
    );
    return Scaffold(
      drawer: menu,
      appBar: AppBar(title: Text(Section.preferences.libelle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Thème', style: titre),
            ),
            for (final t in ChoixTheme.values)
              ListTile(
                key: Key('theme-${t.name}'),
                leading: Icon(switch (t) {
                  ChoixTheme.sombre => Icons.dark_mode_outlined,
                  ChoixTheme.clair => Icons.light_mode_outlined,
                  ChoixTheme.systeme => Icons.brightness_auto_outlined,
                }),
                title: Text(t.libelle),
                trailing: controller.theme == t
                    ? const Icon(Icons.check)
                    : null,
                selected: controller.theme == t,
                onTap: () => controller.changerTheme(t),
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Écran à l\'ouverture', style: titre),
            ),
            for (final s in Section.demarrages)
              ListTile(
                key: Key('demarrage-${s.name}'),
                title: Text(s.libelle),
                trailing: controller.ecranDemarrage == s
                    ? const Icon(Icons.check)
                    : null,
                selected: controller.ecranDemarrage == s,
                onTap: () => controller.changerEcranDemarrage(s),
              ),
          ],
        ),
      ),
    );
  }
}
