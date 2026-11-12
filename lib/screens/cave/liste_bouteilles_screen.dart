import 'package:flutter/material.dart';

import '../../models/bouteille.dart';
import '../../state/cave_controller.dart';
import '../../state/lieux_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/lieux.dart';
import '../../widgets/page.dart';
import '../lieux_screen.dart';
import 'formulaire_bouteille_screen.dart';

class ListeBouteillesScreen extends StatefulWidget {
  const ListeBouteillesScreen({
    super.key,
    required this.controller,
    required this.lieux,
    this.menu,
  });

  final CaveController controller;

  /// Emplacements personnalisés de la cave.
  final LieuxController lieux;

  /// Menu latéral (tiroir) affiché par le bouton ☰.
  final Widget? menu;

  @override
  State<ListeBouteillesScreen> createState() => _ListeBouteillesScreenState();
}

class _ListeBouteillesScreenState extends State<ListeBouteillesScreen> {
  String _recherche = '';
  TypeVin? _type;
  bool _seulementEnStock = false;
  String? _lieu;

  Future<void> _ouvrir([Bouteille? bouteille]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FormulaireBouteilleScreen(
          controller: widget.controller,
          lieux: widget.lieux,
          bouteille: bouteille,
          lieuParDefaut: _lieu,
        ),
      ),
    );
  }

  void _gererLieux() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LieuxScreen(
          lieux: widget.lieux,
          titre: 'Emplacements de la cave',
          elements: 'bouteilles',
          contenu: (id) {
            final n = widget.controller.nombreDans(id);
            return n == 0 ? null : '$n bouteille${n > 1 ? 's' : ''}';
          },
        ),
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
          tooltip: 'Emplacements',
          icon: const Icon(Icons.shelves),
          onPressed: _gererLieux,
        ),
      ],
      bouton: BoutonAjout(libelle: 'Ajouter un vin', onPressed: _ouvrir),
      corps: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, widget.lieux]),
        builder: (context, _) {
          if (!widget.controller.charge) {
            return const Center(child: CircularProgressIndicator());
          }
          // Lieu filtré supprimé entre-temps : on revient à « tous ».
          final lieu = widget.lieux.parId(_lieu ?? '') == null ? null : _lieu;
          final bouteilles = widget.controller.rechercher(
            texte: _recherche,
            type: _type,
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
                    if (widget.lieux.elements.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FiltreLieu(
                          lieux: widget.lieux,
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
                    for (final t in TypeVin.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(t.libelle),
                          selected: _type == t,
                          onSelected: (sel) =>
                              setState(() => _type = sel ? t : null),
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
                            ? 'La cave est vide.\nTouchez + pour ajouter un vin.'
                            : 'Aucun vin ne correspond.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: bouteilles.length,
                        itemBuilder: (context, i) => _LigneBouteille(
                          bouteille: bouteilles[i],
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

Color couleurVin(TypeVin type) => switch (type) {
  TypeVin.rouge => const Color(0xFF7B1E3A),
  TypeVin.blanc => const Color(0xFFE3C565),
  TypeVin.rose => const Color(0xFFF2A0A8),
  TypeVin.effervescent => const Color(0xFFD9CF9A),
  TypeVin.liquoreux => const Color(0xFFC98A2B),
  TypeVin.autre => Colors.grey,
};

class _LigneBouteille extends StatelessWidget {
  const _LigneBouteille({
    required this.bouteille,
    required this.emplacement,
    required this.onTap,
    required this.onAjouter,
    required this.onRetirer,
  });

  final Bouteille bouteille;
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
        leading: IconeCarree(Icons.wine_bar, couleur: couleurVin(b.type)),
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
              tooltip: 'Retirer une bouteille',
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
              tooltip: 'Ajouter une bouteille',
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
