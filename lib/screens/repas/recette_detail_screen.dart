import 'package:flutter/material.dart';

import '../../models/recette.dart';
import '../../state/cuisine.dart';
import '../../state/recettes_controller.dart';
import '../../theme.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';
import 'actions_repas.dart';
import 'formulaire_recette_screen.dart';

/// Fiche d'une recette : ingrédients (présents ou non dans le frigo),
/// préparation, et actions (prévoir, courses, ajouter au carnet).
class RecetteDetailScreen extends StatelessWidget {
  const RecetteDetailScreen({
    super.key,
    required this.cuisine,
    required this.recette,
  });

  final Cuisine cuisine;
  final Recette recette;

  Future<void> _ajouterAuCarnet(BuildContext context) async {
    await cuisine.recettes.ajouterAuCarnet(recette);
    if (context.mounted) {
      await informer(context, '« ${recette.nom} » ajoutée à votre carnet.');
    }
  }

  Future<void> _supprimer(BuildContext context) async {
    if (!await confirmer(
      context,
      'Supprimer la recette « ${recette.nom} » ?',
    )) {
      return;
    }
    await cuisine.recettes.supprimer(recette.id);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    return ListenableBuilder(
      listenable: cuisine.tout,
      builder: (context, _) {
        // Recette personnelle modifiée entre-temps : on affiche la nouvelle.
        final r = recette.modifiable
            ? (cuisine.recettes.recette(recette.id) ?? recette)
            : recette;
        final noms = [
          for (final a in cuisine.frigo.elements)
            if (a.enStock) a.nom,
        ];
        final s = cuisine.recettes.analyser(r, noms);
        final etapes = r.etapes
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        return Scaffold(
          appBar: AppBar(
            title: Text(r.nom, overflow: TextOverflow.ellipsis),
            actions: [
              if (r.modifiable) ...[
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => FormulaireRecetteScreen(
                        recettes: cuisine.recettes,
                        recette: r,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _supprimer(context),
                ),
              ],
            ],
          ),
          bottomNavigationBar: r.source == SourceRecette.enLigne
              ? BarreEnregistrer(
                  libelle: 'Ajouter à mon carnet',
                  onPressed: () => _ajouterAuCarnet(context),
                )
              : null,
          body: ListView(
            padding: margesCentrees(context),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final st in r.styles) Chip(label: Text(st.libelle)),
                  if (r.minutes != null)
                    Chip(
                      avatar: const Icon(Icons.timer_outlined, size: 18),
                      label: Text('${r.minutes} min'),
                    ),
                  if (r.personnes != null)
                    Chip(
                      avatar: const Icon(Icons.people_outline, size: 18),
                      label: Text('${r.personnes} pers.'),
                    ),
                  if (r.source == SourceRecette.enLigne)
                    const Chip(label: Text('En ligne (en anglais)')),
                ],
              ),
              const TitreSection('Ingrédients'),
              Card(
                child: Column(
                  children: [
                    for (final i in r.ingredients)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          i.placard
                              ? Icons.kitchen_outlined
                              : s.disponibles.contains(i)
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: i.placard
                              ? p.texteSecondaire
                              : s.disponibles.contains(i)
                              ? vertOdv
                              : const Color(0xFFE5A23A),
                        ),
                        title: Text(i.libelle),
                        subtitle: i.placard
                            ? const Text('Placard')
                            : s.disponibles.contains(i)
                            ? const Text('Dans le frigo')
                            : const Text('Manquant'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    key: const Key('prevoir-recette'),
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Prévoir dans l\'agenda'),
                    onPressed: () => prevoirRecette(context, cuisine, r),
                  ),
                  if (s.manquants.isNotEmpty)
                    FilledButton.tonalIcon(
                      key: const Key('manquants-courses'),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        'Ajouter les ${s.manquants.length} manquants aux courses',
                      ),
                      onPressed: () =>
                          ajouterManquantsAuxCourses(context, cuisine, r),
                    ),
                ],
              ),
              if (etapes.isNotEmpty) ...[
                const TitreSection('Préparation'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var n = 0; n < etapes.length; n++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${n + 1}. ${etapes[n]}',
                              style: const TextStyle(height: 1.4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// « 4/5 ingrédients · Manque : farine, crème » pour les listes.
String resumeSuggestion(Suggestion s) {
  final total = s.disponibles.length + s.manquants.length;
  if (s.complete) {
    return 'Tout est dans le frigo';
  }
  return '${s.disponibles.length}/$total ingrédients · Manque : '
      '${s.manquants.map((i) => i.nom).join(', ')}';
}
