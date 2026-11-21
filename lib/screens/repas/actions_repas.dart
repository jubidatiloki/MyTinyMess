import 'package:flutter/material.dart';

import '../../models/agenda.dart';
import '../../models/recette.dart';
import '../../state/cuisine.dart';
import '../../widgets/communs.dart';

/// Petit message de confirmation (fenêtre, sans minuterie).
Future<void> informer(BuildContext context, String texte) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    content: Text(texte),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('OK'),
      ),
    ],
  ),
);

/// Ajoute les ingrédients manquants d'une recette à la liste de courses.
Future<void> ajouterManquantsAuxCourses(
  BuildContext context,
  Cuisine cuisine,
  Recette recette,
) async {
  final s = cuisine.recettes.analyser(recette, [
    for (final a in cuisine.frigo.elements)
      if (a.enStock) a.nom,
  ]);
  final n = await cuisine.courses.ajouterIngredients(
    s.manquants,
    origine: 'Recette : ${recette.nom}',
  );
  if (context.mounted) {
    await informer(
      context,
      s.manquants.isEmpty
          ? 'Rien ne manque : tout est dans le frigo.'
          : n == 0
          ? 'Les ingrédients manquants sont déjà dans la liste de courses.'
          : '$n article${n > 1 ? 's' : ''} ajouté${n > 1 ? 's' : ''} '
                'à la liste de courses.',
    );
  }
}

/// Demande un jour et un moment, puis prévoit la recette dans l'agenda.
Future<void> prevoirRecette(
  BuildContext context,
  Cuisine cuisine,
  Recette recette, {
  DateTime? jour,
}) async {
  final aujourdhui = jourDe(DateTime.now());
  final choisi = await showDialog<(DateTime, MomentRepas)>(
    context: context,
    builder: (_) => _ChoixMoment(jourInitial: jour ?? aujourdhui),
  );
  if (choisi == null) {
    return;
  }
  await cuisine.repas.prevoir(choisi.$1, choisi.$2, recette: recette);
  if (context.mounted) {
    await informer(
      context,
      '« ${recette.nom} » prévu ${jourEnLettres(choisi.$1)}, '
      '${choisi.$2.libelle.toLowerCase()}.',
    );
  }
}

class _ChoixMoment extends StatefulWidget {
  const _ChoixMoment({required this.jourInitial});

  final DateTime jourInitial;

  @override
  State<_ChoixMoment> createState() => _ChoixMomentState();
}

class _ChoixMomentState extends State<_ChoixMoment> {
  late DateTime _jour = widget.jourInitial;
  MomentRepas _moment = MomentRepas.soir;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Prévoir dans l\'agenda'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            key: const Key('choix-jour'),
            icon: const Icon(Icons.event_outlined),
            label: Text(jourEnLettres(_jour)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _jour,
                firstDate: DateTime(_jour.year - 1),
                lastDate: DateTime(_jour.year + 2),
              );
              if (d != null) {
                setState(() => _jour = d);
              }
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<MomentRepas>(
            segments: [
              for (final m in MomentRepas.values)
                ButtonSegment(value: m, label: Text(m.libelle)),
            ],
            selected: {_moment},
            onSelectionChanged: (s) => setState(() => _moment = s.first),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('valider-moment'),
          onPressed: () => Navigator.pop(context, (_jour, _moment)),
          child: const Text('Prévoir'),
        ),
      ],
    );
  }
}
