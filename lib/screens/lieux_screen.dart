import 'package:flutter/material.dart';

import '../state/lieux_controller.dart';
import '../widgets/communs.dart';
import '../widgets/lieux.dart';
import '../widgets/page.dart';

/// Gestion des emplacements personnalisés (lieux emboîtés).
class LieuxScreen extends StatelessWidget {
  const LieuxScreen({
    super.key,
    required this.lieux,
    required this.titre,
    required this.contenu,
    this.elements = 'éléments',
  });

  final LieuxController lieux;
  final String titre;

  /// Ce qui est rangé directement dans un lieu (« 3 livres »), ou null.
  final String? Function(String lieuId) contenu;

  /// « livres » / « bouteilles », pour le message de suppression.
  final String elements;

  Future<void> _supprimer(BuildContext context, String id) async {
    final nom = lieux.parId(id)?.nom ?? '';
    final ok = await confirmer(
      context,
      'Supprimer « $nom » ?\n\nCe qu\'il contient remonte d\'un niveau, et '
      'les $elements rangés ici n\'auront plus d\'emplacement.',
    );
    if (ok) {
      await lieux.supprimer(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: titre,
      sousTitre: 'Pièces, meubles, étagères… rangés les uns dans les autres',
      bouton: BoutonAjout(
        libelle: 'Ajouter un emplacement',
        onPressed: () => editerLieu(context, lieux),
      ),
      corps: ListenableBuilder(
        listenable: lieux,
        builder: (context, _) {
          final noeuds = lieux.arbre();
          if (noeuds.isEmpty) {
            return const ListeVide(
              icone: Icons.place_outlined,
              message:
                  'Aucun emplacement pour l\'instant.\n'
                  'Touchez + pour créer une pièce, un meuble, une étagère…\n'
                  'Les emplacements peuvent se ranger les uns dans les autres.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            itemCount: noeuds.length,
            itemBuilder: (context, i) {
              final n = noeuds[i];
              final resume = contenu(n.lieu.id);
              // Décalage selon la profondeur : on voit ce qui est dans quoi.
              return Padding(
                key: Key('lieu-${n.lieu.id}'),
                padding: EdgeInsets.only(left: 28.0 * n.profondeur),
                child: CarteLigne(
                  leading: IconeCarree(
                    n.profondeur == 0
                        ? Icons.place_outlined
                        : Icons.subdirectory_arrow_right,
                  ),
                  title: Text(
                    n.lieu.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: resume == null ? null : Text(resume),
                  onTap: () => editerLieu(context, lieux, lieu: n.lieu),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Ajouter dedans',
                        icon: const Icon(Icons.add),
                        onPressed: () =>
                            editerLieu(context, lieux, parentId: n.lieu.id),
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _supprimer(context, n.lieu.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
