import 'package:flutter/material.dart';

import '../../models/lieu.dart';
import '../../models/livre.dart';
import '../../state/bibliotheque_controller.dart';
import '../../state/lieux_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/lieux.dart';
import '../../widgets/page.dart';
import 'formulaire_livre_screen.dart';

class ListeLivresScreen extends StatefulWidget {
  const ListeLivresScreen({
    super.key,
    required this.controller,
    required this.lieux,
    this.menu,
    this.onGererLieux,
  });

  final BibliothequeController controller;

  /// Emplacements personnalisés (communs avec la cave).
  final LieuxController lieux;

  /// Ouvre l'écran « Emplacements » (bouton de la barre de titre).
  final VoidCallback? onGererLieux;

  /// Menu latéral (tiroir) affiché par le bouton ☰.
  final Widget? menu;

  @override
  State<ListeLivresScreen> createState() => _ListeLivresScreenState();
}

class _ListeLivresScreenState extends State<ListeLivresScreen> {
  String _recherche = '';
  FiltreLivres _filtre = FiltreLivres.tous;
  String? _lieu;

  Future<void> _ouvrir([Livre? livre]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FormulaireLivreScreen(
          controller: widget.controller,
          lieux: widget.lieux,
          livre: livre,
          lieuParDefaut: _lieu,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: 'Ma bibliothèque',
      titreWidget: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final n = widget.controller.nombreLivres;
          final s = widget.controller.nombreSouhaits;
          return TitrePage(
            titre: 'Ma bibliothèque',
            sousTitre: [
              '$n livre${n > 1 ? 's' : ''}',
              if (s > 0) '$s en liste de souhaits',
            ].join(' · '),
          );
        },
      ),
      menu: widget.menu,
      actions: [
        if (widget.onGererLieux != null)
          IconButton(
            tooltip: 'Emplacements',
            icon: const Icon(Icons.shelves),
            onPressed: widget.onGererLieux,
          ),
      ],
      bouton: BoutonAjout(libelle: 'Ajouter un livre', onPressed: _ouvrir),
      corps: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, widget.lieux]),
        builder: (context, _) {
          if (!widget.controller.charge) {
            return const Center(child: CircularProgressIndicator());
          }
          // Lieu filtré supprimé entre-temps : on revient à « tous ».
          final lieu = widget.lieux.parId(_lieu ?? '') == null ? null : _lieu;
          final livres = widget.controller.rechercher(
            texte: _recherche,
            filtre: _filtre,
            lieuId: lieu,
          );
          return Column(
            children: [
              ChampRecherche(
                indice: 'Titre, auteur, genre, emplacement…',
                onChanged: (t) => setState(() => _recherche = t),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (widget.lieux.arbre(type: TypeLieu.livres).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FiltreLieu(
                          lieux: widget.lieux,
                          type: TypeLieu.livres,
                          valeur: lieu,
                          onChanged: (v) => setState(() => _lieu = v),
                        ),
                      ),
                    for (final f in FiltreLivres.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(f.libelle),
                          selected: _filtre == f,
                          onSelected: (_) => setState(() => _filtre = f),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: livres.isEmpty
                    ? ListeVide(
                        icone: Icons.menu_book_outlined,
                        message: widget.controller.elements.isEmpty
                            ? 'Aucun livre pour l\'instant.\n'
                                  'Touchez + pour en ajouter un.'
                            : 'Aucun livre ne correspond.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: livres.length,
                        itemBuilder: (context, i) => _LigneLivre(
                          livre: livres[i],
                          emplacement: widget.controller.emplacementDe(
                            livres[i],
                          ),
                          onTap: () => _ouvrir(livres[i]),
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

class _LigneLivre extends StatelessWidget {
  const _LigneLivre({
    required this.livre,
    required this.emplacement,
    required this.onTap,
  });

  final Livre livre;
  final String? emplacement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (livre.auteur.isNotEmpty) livre.auteur,
      livre.statut.libelle,
    ].join(' · ');
    return CarteLigne(
      onTap: onTap,
      leading: IconeCarree(switch (livre.statut) {
        StatutLecture.aLire => Icons.bookmark_border,
        StatutLecture.enCours => Icons.auto_stories,
        StatutLecture.lu => Icons.check_circle_outline,
        StatutLecture.souhait => Icons.favorite_border,
      }),
      title: Text(livre.titre, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (emplacement != null)
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    emplacement!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: livre.estChezMoi
          ? null
          : Chip(
              label: Text(
                livre.possession == Possession.prete
                    ? 'Prêté à ${livre.personne ?? '?'}'
                    : 'Emprunté à ${livre.personne ?? '?'}',
                overflow: TextOverflow.ellipsis,
              ),
              visualDensity: VisualDensity.compact,
            ),
    );
  }
}
