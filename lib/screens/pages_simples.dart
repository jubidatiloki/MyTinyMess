import 'package:flutter/material.dart';

import '../models/section.dart';
import '../theme.dart';
import '../version.dart';
import '../widgets/communs.dart';
import '../widgets/page.dart';

/// Rubrique pas encore construite (Mon bazar…).
class EcranAVenir extends StatelessWidget {
  const EcranAVenir({
    super.key,
    required this.section,
    required this.icone,
    this.menu,
  });

  final Section section;
  final IconData icone;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: section.libelle,
      menu: menu,
      corps: ListeVide(icone: icone, message: 'Bientôt disponible.'),
    );
  }
}

class AProposScreen extends StatelessWidget {
  const AProposScreen({super.key, this.menu});

  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    return PageOdv(
      titre: Section.aPropos.libelle,
      menu: menu,
      corps: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: vertOdv,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_stories,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Tiny Mess',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Version $kVersionApp',
                              style: TextStyle(color: p.texteSecondaire),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pour gérer sa bibliothèque (livres, notes, prêts et '
                    'emprunts) et sa cave à vin (bouteilles, emplacements, '
                    'entrées et sorties).\n\n'
                    'Les données restent sur l\'appareil.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
