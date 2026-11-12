import 'package:flutter/material.dart';

import '../models/section.dart';
import '../version.dart';

/// Menu latéral vert (maquette « categories »).
class MenuLateral extends StatelessWidget {
  const MenuLateral({
    super.key,
    required this.courante,
    required this.onChoisir,
  });

  final Section courante;
  final ValueChanged<Section> onChoisir;

  @override
  Widget build(BuildContext context) {
    const blanc = Colors.white;
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'My Tiny Mess',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: blanc,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: blanc, thickness: 1, height: 1),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final s in Section.values)
                  ListTile(
                    key: Key('menu-${s.name}'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(
                      s.libelle,
                      style: TextStyle(
                        color: blanc,
                        fontSize: 16,
                        fontWeight: s == courante
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    selected: s == courante,
                    selectedTileColor: blanc.withValues(alpha: 0.15),
                    onTap: () {
                      Navigator.pop(context);
                      onChoisir(s);
                    },
                  ),
              ],
            ),
          ),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Version $kVersionApp',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
