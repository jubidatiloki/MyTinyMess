import 'package:flutter/material.dart';

import '../models/lieu.dart';
import '../models/section.dart';
import '../state/bibliotheque_controller.dart';
import '../state/cave_controller.dart';
import '../state/lieux_controller.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/lieux.dart';
import '../widgets/page.dart';

/// « 3 livres », « 1 bouteille »… (null si zéro).
String? resumeContenu(int nombre, TypeLieu type) {
  if (nombre == 0) {
    return null;
  }
  final mot = type == TypeLieu.livres ? 'livre' : 'bouteille';
  return '$nombre $mot${nombre > 1 ? 's' : ''}';
}

/// Écran « Emplacements » : créer, modifier et supprimer les lieux de
/// rangement, en deux groupes — ceux de la bibliothèque (livres) et ceux de
/// la cave (bouteilles). Un emplacement n'est jamais pour les deux.
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

  int _nombreDans(Lieu l, TypeLieu type) => type == TypeLieu.livres
      ? bibliotheque.nombreDans(l.id)
      : cave.nombreDans(l.id);

  Future<void> _supprimer(BuildContext context, Lieu lieu) async {
    final contenu = lieux.typeDe(lieu).contenu;
    final ok = await confirmer(
      context,
      'Supprimer « ${lieu.nom} » ?\n\nCe qu\'il contient remonte d\'un niveau, '
      'et les $contenu rangés directement ici n\'auront plus d\'emplacement.',
    );
    if (ok) {
      await lieux.supprimer(lieu.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: Section.emplacements.libelle,
      sousTitre: 'Pièces, meubles, étagères… pour les livres ou pour la cave',
      menu: menu,
      bouton: BoutonAjout(
        libelle: 'Ajouter un emplacement',
        onPressed: () => editerLieu(context, lieux),
      ),
      corps: ListenableBuilder(
        listenable: Listenable.merge([lieux, bibliotheque, cave]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            for (final type in TypeLieu.values) ..._groupe(context, type),
          ],
        ),
      ),
    );
  }

  List<Widget> _groupe(BuildContext context, TypeLieu type) {
    final p = PaletteOdv.de(context);
    final noeuds = lieux.arbre(type: type);
    return [
      Row(
        children: [
          Expanded(child: TitreSection(type.libelle)),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              key: Key('ajouter-lieu-${type.name}'),
              onPressed: () => editerLieu(context, lieux, type: type),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ),
        ],
      ),
      if (noeuds.isEmpty)
        Card(
          child: ListTile(
            leading: IconeCarree(iconeTypeLieu(type)),
            title: Text('Aucun emplacement pour les ${type.contenu}'),
            subtitle: Text(
              type == TypeLieu.livres
                  ? 'Une pièce, une bibliothèque, une étagère…'
                  : 'Une cave, un casier, une armoire…',
            ),
          ),
        ),
      for (final n in noeuds)
        Padding(
          key: Key('lieu-${n.lieu.id}'),
          // Décalage selon la profondeur : on voit ce qui est dans quoi.
          padding: EdgeInsets.only(left: 28.0 * n.profondeur),
          child: Builder(
            builder: (context) {
              final resume = resumeContenu(_nombreDans(n.lieu, type), type);
              return CarteLigne(
                leading: IconeCarree(
                  n.profondeur == 0
                      ? iconeTypeLieu(type)
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
                      onPressed: () => editerLieu(context, lieux, lieu: n.lieu),
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
                      onPressed: () => _supprimer(context, n.lieu),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    ];
  }
}
