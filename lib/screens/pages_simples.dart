import 'package:flutter/material.dart';

import '../models/section.dart';
import '../version.dart';
import '../widgets/communs.dart';

/// Rubrique pas encore construite (Mon bazar, Contact…).
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
    return Scaffold(
      drawer: menu,
      appBar: AppBar(title: Text(section.libelle)),
      body: ListeVide(icone: icone, message: 'Bientôt disponible.'),
    );
  }
}

class AProposScreen extends StatelessWidget {
  const AProposScreen({super.key, this.menu});

  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    return Scaffold(
      drawer: menu,
      appBar: AppBar(title: Text(Section.aPropos.libelle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('My Tiny Mess', style: textes.headlineSmall),
          const SizedBox(height: 4),
          Text('Version $kVersionApp', style: textes.bodySmall),
          const SizedBox(height: 16),
          const Text(
            'Pour gérer sa bibliothèque (livres, notes, prêts et emprunts) '
            'et sa cave à vin (bouteilles, emplacements, entrées et sorties).\n\n'
            'Les données restent sur l\'appareil.',
          ),
        ],
      ),
    );
  }
}
