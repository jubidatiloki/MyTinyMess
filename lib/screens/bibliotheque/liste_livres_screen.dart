import 'package:flutter/material.dart';

import '../../models/livre.dart';
import '../../state/bibliotheque_controller.dart';
import '../../widgets/communs.dart';
import 'formulaire_livre_screen.dart';

class ListeLivresScreen extends StatefulWidget {
  const ListeLivresScreen({super.key, required this.controller});

  final BibliothequeController controller;

  @override
  State<ListeLivresScreen> createState() => _ListeLivresScreenState();
}

class _ListeLivresScreenState extends State<ListeLivresScreen> {
  String _recherche = '';
  FiltreLivres _filtre = FiltreLivres.tous;

  Future<void> _ouvrir([Livre? livre]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            FormulaireLivreScreen(controller: widget.controller, livre: livre),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ma bibliothèque')),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: 'Ajouter un livre',
        onPressed: _ouvrir,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (!widget.controller.charge) {
            return const Center(child: CircularProgressIndicator());
          }
          final livres = widget.controller.rechercher(
            texte: _recherche,
            filtre: _filtre,
          );
          return Column(
            children: [
              ChampRecherche(
                indice: 'Titre, auteur, genre…',
                onChanged: (t) => setState(() => _recherche = t),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
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
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: livres.length,
                        itemBuilder: (context, i) => _LigneLivre(
                          livre: livres[i],
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
  const _LigneLivre({required this.livre, required this.onTap});

  final Livre livre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (livre.auteur.isNotEmpty) livre.auteur,
      livre.statut.libelle,
    ].join(' · ');
    return ListTile(
      leading: Icon(switch (livre.statut) {
        StatutLecture.aLire => Icons.bookmark_border,
        StatutLecture.enCours => Icons.auto_stories,
        StatutLecture.lu => Icons.check_circle_outline,
      }),
      title: Text(livre.titre, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      onTap: onTap,
    );
  }
}
