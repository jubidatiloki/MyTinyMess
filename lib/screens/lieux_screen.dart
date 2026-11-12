import 'package:flutter/material.dart';

import '../models/section.dart';
import '../state/bibliotheque_controller.dart';
import '../state/cave_controller.dart';
import '../state/lieux_controller.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/lieux.dart';
import '../widgets/page.dart';

/// « 3 livres · 12 bouteilles » (null si l'emplacement est vide).
String? resumeContenu(int livres, int bouteilles) {
  final morceaux = [
    if (livres > 0) '$livres livre${livres > 1 ? 's' : ''}',
    if (bouteilles > 0) '$bouteilles bouteille${bouteilles > 1 ? 's' : ''}',
  ];
  return morceaux.isEmpty ? null : morceaux.join(' · ');
}

/// Écran « Emplacements » : créer, modifier et supprimer les lieux de
/// rangement (communs aux livres et à la cave), emboîtés les uns dans les
/// autres.
class LieuxScreen extends StatelessWidget {
  const LieuxScreen({
    super.key,
    required this.lieux,
    required this.bibliotheque,
    required this.cave,
    this.menu,
  });

  final LieuxController lieux;
  final BibliothequeController bibliotheque;
  final CaveController cave;
  final Widget? menu;

  Future<void> _supprimer(BuildContext context, String id) async {
    final nom = lieux.parId(id)?.nom ?? '';
    final ok = await confirmer(
      context,
      'Supprimer « $nom » ?\n\nCe qu\'il contient remonte d\'un niveau, et '
      'les livres et bouteilles rangés directement ici n\'auront plus '
      'd\'emplacement.',
    );
    if (ok) {
      await lieux.supprimer(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    return PageOdv(
      titre: Section.emplacements.libelle,
      sousTitre: 'Pièces, meubles, étagères… pour les livres et la cave',
      menu: menu,
      bouton: BoutonAjout(
        libelle: 'Ajouter un emplacement',
        onPressed: () => editerLieu(context, lieux),
      ),
      corps: ListenableBuilder(
        listenable: Listenable.merge([lieux, bibliotheque, cave]),
        builder: (context, _) {
          final noeuds = lieux.arbre();
          if (noeuds.isEmpty) {
            return const ListeVide(
              icone: Icons.shelves,
              message:
                  'Aucun emplacement pour l\'instant.\n'
                  'Touchez « Ajouter un emplacement » pour créer une pièce, '
                  'un meuble, une étagère…\n'
                  'Les emplacements peuvent se ranger les uns dans les autres.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            itemCount: noeuds.length,
            itemBuilder: (context, i) {
              final n = noeuds[i];
              final resume = resumeContenu(
                bibliotheque.nombreDans(n.lieu.id),
                cave.nombreDans(n.lieu.id),
              );
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
                  subtitle: Text(
                    resume ?? 'Vide',
                    style: resume == null
                        ? TextStyle(color: p.texteSecondaire)
                        : null,
                  ),
                  onTap: () => editerLieu(context, lieux, lieu: n.lieu),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Modifier',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            editerLieu(context, lieux, lieu: n.lieu),
                      ),
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
