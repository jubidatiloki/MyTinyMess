import 'package:flutter/material.dart';

import '../../models/agenda.dart';
import '../../state/cuisine.dart';
import '../../theme.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';
import '../repas/actions_repas.dart';

/// Rubrique « Liste de courses ».
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key, required this.cuisine, this.menu});

  final Cuisine cuisine;
  final Widget? menu;

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _nouvel = TextEditingController();

  @override
  void dispose() {
    _nouvel.dispose();
    super.dispose();
  }

  Future<void> _ajouter() async {
    final t = _nouvel.text.trim();
    if (t.isEmpty) {
      return;
    }
    final ajoute = await widget.cuisine.courses.ajouter(t);
    _nouvel.clear();
    if (!ajoute && mounted) {
      await informer(context, '« $t » est déjà dans la liste.');
    }
  }

  Future<void> _ranger() async {
    final n = await widget.cuisine.courses.rangerDansFrigo(
      widget.cuisine.frigo,
    );
    if (mounted) {
      await informer(
        context,
        '$n article${n > 1 ? 's' : ''} rangé${n > 1 ? 's' : ''} dans le frigo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = widget.cuisine.courses;
    return PageOdv(
      titre: 'Liste de courses',
      titreWidget: ListenableBuilder(
        listenable: courses,
        builder: (context, _) {
          final n = courses.nombreAAcheter;
          return TitrePage(
            titre: 'Liste de courses',
            sousTitre: n == 0
                ? 'Rien à acheter'
                : '$n article${n > 1 ? 's' : ''} à acheter',
          );
        },
      ),
      menu: widget.menu,
      corps: ListenableBuilder(
        listenable: courses,
        builder: (context, _) {
          final aAcheter = courses.elements.where((a) => !a.coche).toList();
          final achetes = courses.elements.where((a) => a.coche).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextField(
                key: const Key('champ-article'),
                controller: _nouvel,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _ajouter(),
                decoration: InputDecoration(
                  hintText: 'Ajouter un article (lait, pain…)',
                  prefixIcon: const Icon(Icons.add_shopping_cart),
                  suffixIcon: IconButton(
                    tooltip: 'Ajouter à la liste',
                    icon: const Icon(Icons.add),
                    onPressed: _ajouter,
                  ),
                ),
              ),
              if (aAcheter.isEmpty && achetes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: ListeVide(
                    icone: Icons.shopping_cart_outlined,
                    message:
                        'La liste est vide.\nAjoutez des articles ici, '
                        'depuis le frigo ou depuis une recette.',
                  ),
                ),
              if (aAcheter.isNotEmpty) ...[
                const TitreSection('À acheter'),
                for (final a in aAcheter)
                  _Article(article: a, cuisine: widget.cuisine),
              ],
              if (achetes.isNotEmpty) ...[
                const TitreSection('Dans le panier'),
                for (final a in achetes)
                  _Article(article: a, cuisine: widget.cuisine),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const Key('ranger-frigo'),
                      icon: const Icon(Icons.kitchen_outlined),
                      label: const Text('Ranger les achats dans le frigo'),
                      onPressed: _ranger,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Retirer les articles cochés'),
                      onPressed: courses.supprimerCoches,
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Article extends StatelessWidget {
  const _Article({required this.article, required this.cuisine});

  final ArticleCourses article;
  final Cuisine cuisine;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    final a = article;
    final details = [?a.quantite, ?a.origine].join(' · ');
    return Padding(
      key: Key('article-${a.id}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: CheckboxListTile(
          value: a.coche,
          onChanged: (_) => cuisine.courses.basculer(a.id),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: vertOdv,
          title: Text(
            a.nom,
            style: a.coche
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: p.texteSecondaire,
                  )
                : null,
          ),
          subtitle: details.isEmpty ? null : Text(details),
          secondary: IconButton(
            tooltip: 'Retirer de la liste',
            icon: const Icon(Icons.close),
            onPressed: () => cuisine.courses.supprimer(a.id),
          ),
        ),
      ),
    );
  }
}
