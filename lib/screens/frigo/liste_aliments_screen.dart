import 'package:flutter/material.dart';

import '../../models/aliment.dart';
import '../../models/lieu.dart';
import '../../state/agenda_controller.dart';
import '../../state/frigo_controller.dart';
import '../../state/lieux_controller.dart';
import '../../theme.dart';
import '../../widgets/communs.dart';
import '../../widgets/lieux.dart';
import '../../widgets/page.dart';
import 'formulaire_aliment_screen.dart';

/// Couleur d'alerte selon la péremption (null = rien à signaler).
Color? couleurPeremption(EtatPeremption e) => switch (e) {
  EtatPeremption.perime => const Color(0xFFE05A4F),
  EtatPeremption.bientot => const Color(0xFFE5A23A),
  _ => null,
};

/// « Périmé depuis 2 jours », « À consommer aujourd'hui », « Avant le 20/11
/// (dans 5 jours) », ou null sans date.
String? textePeremption(Aliment a, DateTime aujourdhui) {
  final j = a.joursRestants(aujourdhui);
  if (j == null) {
    return null;
  }
  String jours(int n) => '$n jour${n > 1 ? 's' : ''}';
  if (j < 0) {
    return 'Périmé depuis ${jours(-j)}';
  }
  if (j == 0) {
    return 'À consommer aujourd\'hui';
  }
  if (j == 1) {
    return 'À consommer demain';
  }
  return 'Avant le ${formaterDate(a.datePeremption!)} (dans ${jours(j)})';
}

/// Rubrique « Mon frigo » : les aliments, du plus urgent au moins urgent.
class ListeAlimentsScreen extends StatefulWidget {
  const ListeAlimentsScreen({
    super.key,
    required this.controller,
    required this.lieux,
    this.menu,
    this.onGererLieux,
    this.courses,
  });

  final FrigoController controller;

  /// Liste de courses (bouton « Ajouter à la liste de courses »).
  final CoursesController? courses;
  final LieuxController lieux;
  final Widget? menu;
  final VoidCallback? onGererLieux;

  @override
  State<ListeAlimentsScreen> createState() => _ListeAlimentsScreenState();
}

class _ListeAlimentsScreenState extends State<ListeAlimentsScreen> {
  String _recherche = '';
  FiltreAliments _filtre = FiltreAliments.tous;
  String? _lieu;
  String? _categorie;

  Future<void> _choisirCategorie() async {
    final choix = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filtrer par catégorie'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Toutes les catégories'),
          ),
          for (final c in widget.controller.categories!.elements)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, c.nom),
              child: Text(c.nom),
            ),
        ],
      ),
    );
    if (choix != null) {
      setState(() => _categorie = choix.isEmpty ? null : choix);
    }
  }

  Future<void> _ouvrir([Aliment? aliment]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FormulaireAlimentScreen(
          controller: widget.controller,
          lieux: widget.lieux,
          aliment: aliment,
          lieuParDefaut: _lieu,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return PageOdv(
      titre: 'Mon frigo',
      titreWidget: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final n = c.nombreArticles;
          final s = c.nombreASurveiller;
          return TitrePage(
            titre: 'Mon frigo',
            sousTitre: [
              '$n article${n > 1 ? 's' : ''}',
              if (s > 0) '$s à consommer vite',
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
      bouton: BoutonAjout(libelle: 'Ajouter un aliment', onPressed: _ouvrir),
      corps: ListenableBuilder(
        listenable: Listenable.merge([
          c,
          widget.lieux,
          ?widget.courses,
          ?c.categories,
        ]),
        builder: (context, _) {
          if (!c.charge) {
            return const Center(child: CircularProgressIndicator());
          }
          final lieu = widget.lieux.parId(_lieu ?? '') == null ? null : _lieu;
          // Catégorie supprimée ou renommée entre-temps : on revient à toutes.
          final categorie = c.categories?.parNom(_categorie)?.nom;
          final aliments = c.rechercher(
            categorie: categorie,
            texte: _recherche,
            filtre: _filtre,
            lieuId: lieu,
          );
          return Column(
            children: [
              ChampRecherche(
                indice: 'Nom, catégorie, emplacement…',
                onChanged: (t) => setState(() => _recherche = t),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (widget.lieux.arbre(type: TypeLieu.frigo).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FiltreLieu(
                          lieux: widget.lieux,
                          type: TypeLieu.frigo,
                          valeur: lieu,
                          onChanged: (v) => setState(() => _lieu = v),
                        ),
                      ),
                    if (c.categories != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InputChip(
                          key: const Key('filtre-categorie'),
                          avatar: const Icon(Icons.label_outline, size: 18),
                          label: Text(categorie ?? 'Catégories'),
                          selected: categorie != null,
                          showCheckmark: false,
                          onPressed: _choisirCategorie,
                          onDeleted: categorie == null
                              ? null
                              : () => setState(() => _categorie = null),
                        ),
                      ),
                    for (final f in FiltreAliments.values)
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
                child: aliments.isEmpty
                    ? ListeVide(
                        icone: Icons.kitchen_outlined,
                        message: c.elements.isEmpty
                            ? 'Le frigo est vide.\n'
                                  'Touchez « Ajouter un aliment ».'
                            : 'Aucun aliment ne correspond.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: aliments.length,
                        itemBuilder: (context, i) => _LigneAliment(
                          aliment: aliments[i],
                          etat: c.etatDe(aliments[i]),
                          peremption: textePeremption(
                            aliments[i],
                            c.aujourdhui,
                          ),
                          emplacement: c.emplacementDe(aliments[i]),
                          onTap: () => _ouvrir(aliments[i]),
                          onAjouter: () => c.ajouterUn(aliments[i].id),
                          onRetirer: () => c.retirerUn(aliments[i].id),
                          dansLesCourses:
                              widget.courses?.contient(aliments[i].nom) ??
                              false,
                          onCourses: widget.courses == null
                              ? null
                              : () => widget.courses!.ajouter(
                                  aliments[i].nom,
                                  origine: 'Frigo',
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

class _LigneAliment extends StatelessWidget {
  const _LigneAliment({
    required this.aliment,
    required this.etat,
    required this.peremption,
    required this.emplacement,
    required this.onTap,
    required this.onAjouter,
    required this.onRetirer,
    this.dansLesCourses = false,
    this.onCourses,
  });

  final Aliment aliment;
  final bool dansLesCourses;
  final VoidCallback? onCourses;
  final EtatPeremption etat;
  final String? peremption;
  final String? emplacement;
  final VoidCallback onTap;
  final VoidCallback onAjouter;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final a = aliment;
    final p = PaletteOdv.de(context);
    final alerte = a.enStock ? couleurPeremption(etat) : null;
    final titre = [
      a.nom,
      if (a.contenance != null) '(${a.contenance})',
    ].join(' ');
    return Opacity(
      opacity: a.enStock ? 1 : 0.5,
      child: CarteLigne(
        leading: IconeCarree(Icons.kitchen_outlined, couleur: alerte),
        title: Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                a.enStock ? (peremption ?? 'Pas de date') : 'Épuisé',
                ?a.categorie,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: alerte ?? p.texteSecondaire,
                fontWeight: alerte != null ? FontWeight.w600 : null,
              ),
            ),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onCourses != null)
              IconButton(
                tooltip: dansLesCourses
                    ? 'Déjà dans la liste de courses'
                    : 'Ajouter à la liste de courses',
                icon: Icon(
                  dansLesCourses
                      ? Icons.shopping_cart
                      : Icons.add_shopping_cart,
                  color: dansLesCourses ? vertOdv : null,
                ),
                onPressed: dansLesCourses ? null : onCourses,
              ),
            IconButton(
              tooltip: 'Retirer 1 du stock',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: a.enStock ? onRetirer : null,
            ),
            SizedBox(
              width: 28,
              child: FittedBox(
                child: Text(
                  '${a.quantite}',
                  key: Key('quantite-${a.id}'),
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
