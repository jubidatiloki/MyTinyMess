import 'package:flutter/material.dart';

import '../../models/lieu.dart';
import '../../models/bouteille.dart';
import '../../state/cave_controller.dart';
import '../../state/lieux_controller.dart';
import '../../state/types_bouteille_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/lieux.dart';
import '../../widgets/page.dart';
import 'formulaire_bouteille_screen.dart';
import 'types_bouteille_screen.dart';

class ListeBouteillesScreen extends StatefulWidget {
  const ListeBouteillesScreen({
    super.key,
    required this.controller,
    required this.lieux,
    required this.types,
    this.menu,
    this.onGererLieux,
  });

  final CaveController controller;

  /// Emplacements personnalisés (communs avec la bibliothèque).
  final LieuxController lieux;

  /// Types de bouteille (liste paramétrable).
  final TypesBouteilleController types;

  /// Ouvre l'écran « Emplacements » (bouton de la barre de titre).
  final VoidCallback? onGererLieux;

  /// Menu latéral (tiroir) affiché par le bouton ☰.
  final Widget? menu;

  @override
  State<ListeBouteillesScreen> createState() => _ListeBouteillesScreenState();
}

class _ListeBouteillesScreenState extends State<ListeBouteillesScreen> {
  String _recherche = '';
  String? _typeId;
  bool _seulementEnStock = false;
  String? _lieu;

  Future<void> _ouvrir([Bouteille? bouteille]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FormulaireBouteilleScreen(
          controller: widget.controller,
          lieux: widget.lieux,
          types: widget.types,
          bouteille: bouteille,
          lieuParDefaut: _lieu,
        ),
      ),
    );
  }

  void _gererTypes() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            TypesBouteilleScreen(types: widget.types, cave: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: 'Ma cave',
      titreWidget: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final n = widget.controller.totalBouteilles;
          return TitrePage(
            titre: 'Ma cave',
            sousTitre: '$n bouteille${n > 1 ? 's' : ''}',
          );
        },
      ),
      menu: widget.menu,
      actions: [
        IconButton(
          tooltip: 'Types de bouteille',
          icon: const Icon(Icons.category_outlined),
          onPressed: _gererTypes,
        ),
        if (widget.onGererLieux != null)
          IconButton(
            tooltip: 'Emplacements',
            icon: const Icon(Icons.shelves),
            onPressed: widget.onGererLieux,
          ),
      ],
      bouton: BoutonAjout(libelle: 'Ajouter une bouteille', onPressed: _ouvrir),
      corps: ListenableBuilder(
        listenable: Listenable.merge([
          widget.controller,
          widget.lieux,
          widget.types,
        ]),
        builder: (context, _) {
          if (!widget.controller.charge) {
            return const Center(child: CircularProgressIndicator());
          }
          // Lieu filtré supprimé entre-temps : on revient à « tous ».
          final lieu = widget.lieux.parId(_lieu ?? '') == null ? null : _lieu;
          final bouteilles = widget.controller.rechercher(
            texte: _recherche,
            typeId: widget.types.parId(_typeId ?? '') == null ? null : _typeId,
            seulementEnStock: _seulementEnStock,
            lieuId: lieu,
          );
          return Column(
            children: [
              ChampRecherche(
                indice: 'Nom, appellation, emplacement…',
                onChanged: (t) => setState(() => _recherche = t),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (widget.lieux.arbre(type: TypeLieu.cave).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FiltreLieu(
                          lieux: widget.lieux,
                          type: TypeLieu.cave,
                          valeur: lieu,
                          onChanged: (v) => setState(() => _lieu = v),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: const Text('En stock'),
                        selected: _seulementEnStock,
                        onSelected: (v) =>
                            setState(() => _seulementEnStock = v),
                      ),
                    ),
                    for (final t in widget.types.elements)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(t.nom),
                          selected: _typeId == t.id,
                          onSelected: (sel) =>
                              setState(() => _typeId = sel ? t.id : null),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: bouteilles.isEmpty
                    ? ListeVide(
                        icone: Icons.wine_bar_outlined,
                        message: widget.controller.elements.isEmpty
                            ? 'La cave est vide.\nTouchez « Ajouter une bouteille ».'
                            : 'Aucune bouteille ne correspond.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: bouteilles.length,
                        itemBuilder: (context, i) => _LigneBouteille(
                          bouteille: bouteilles[i],
                          couleur: widget.types.couleurDe(bouteilles[i].typeId),
                          emplacement: widget.controller.emplacementDe(
                            bouteilles[i],
                          ),
                          onTap: () => _ouvrir(bouteilles[i]),
                          onAjouter: () => widget.controller.ajouterBouteilles(
                            bouteilles[i].id,
                            1,
                          ),
                          onRetirer: () => widget.controller.retirerBouteilles(
                            bouteilles[i].id,
                            1,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LigneBouteille extends StatelessWidget {
  const _LigneBouteille({
    required this.bouteille,
    required this.couleur,
    required this.emplacement,
    required this.onTap,
    required this.onAjouter,
    required this.onRetirer,
  });

  final Bouteille bouteille;
  final Color couleur;
  final String emplacement;
  final VoidCallback onTap;
  final VoidCallback onAjouter;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final b = bouteille;
    final titre = [b.nom, if (b.millesime != null) '${b.millesime}'].join(' ');
    return Opacity(
      opacity: b.enStock ? 1 : 0.5,
      child: CarteLigne(
        leading: IconeCarree(Icons.wine_bar, couleur: couleur),
        title: Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            const Icon(Icons.place_outlined, size: 14),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                emplacement.isEmpty ? 'Emplacement non précisé' : emplacement,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Retirer 1 du stock',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: b.enStock ? onRetirer : null,
            ),
            SizedBox(
              width: 28,
              child: FittedBox(
                child: Text(
                  '${b.quantite}',
                  key: Key('quantite-${b.id}'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Ajouter 1 au stock',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAjouter,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
