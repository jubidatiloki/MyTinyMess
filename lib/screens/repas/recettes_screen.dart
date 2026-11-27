import 'package:flutter/material.dart';

import '../../models/recette.dart';
import '../../state/cuisine.dart';
import '../../theme.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';
import 'formulaire_recette_screen.dart';
import 'recette_detail_screen.dart';

/// « 1 recette », « 12 recettes ».
String _nombre(int n, String mot) => '$n $mot${n > 1 ? 's' : ''}';

/// Rubrique « Repas & recettes » : propositions selon le frigo, carnet de
/// recettes (intégrées + personnelles) et recherche en ligne. L'en-tête
/// donne le nombre de recettes de l'onglet affiché, selon ses filtres.
class RecettesScreen extends StatefulWidget {
  const RecettesScreen({super.key, required this.cuisine, this.menu});

  final Cuisine cuisine;
  final Widget? menu;

  @override
  State<RecettesScreen> createState() => _RecettesScreenState();
}

class _RecettesScreenState extends State<RecettesScreen>
    with SingleTickerProviderStateMixin {
  late final _onglets = TabController(
    length: widget.cuisine.enLigne == null ? 2 : 3,
    vsync: this,
  );
  StyleRecette? _stylePropositions;
  StyleRecette? _styleCarnet;
  String _texteCarnet = '';

  /// Nombre de résultats de la recherche en ligne (null = pas de recherche).
  final _resultatsEnLigne = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _onglets.dispose();
    _resultatsEnLigne.dispose();
    super.dispose();
  }

  String _sousTitre() {
    final c = widget.cuisine;
    switch (_onglets.index) {
      case 0:
        return [
          _nombre(
            c.recettes
                .suggestions(c.frigo.elements, style: _stylePropositions)
                .length,
            'proposition',
          ),
          ?_stylePropositions?.libelle,
        ].join(' · ');
      case 1:
        final texte = _texteCarnet.trim();
        return [
          _nombre(
            c.recettes.rechercher(texte: texte, style: _styleCarnet).length,
            'recette',
          ),
          ?_styleCarnet?.libelle,
          if (texte.isNotEmpty) '« $texte »',
        ].join(' · ');
      default:
        final n = _resultatsEnLigne.value;
        return n == null
            ? 'Recherche en ligne (en anglais)'
            : _nombre(n, 'résultat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuisine = widget.cuisine;
    return PageOdv(
      titre: 'Repas & recettes',
      titreWidget: ListenableBuilder(
        listenable: Listenable.merge([
          cuisine.tout,
          _onglets,
          _resultatsEnLigne,
        ]),
        builder: (context, _) => TitrePage(
          key: const Key('entete-recettes'),
          titre: 'Repas & recettes',
          sousTitre: _sousTitre(),
        ),
      ),
      menu: widget.menu,
      bouton: BoutonAjout(
        libelle: 'Ajouter une recette',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => FormulaireRecetteScreen(recettes: cuisine.recettes),
          ),
        ),
      ),
      corps: Column(
        children: [
          TabBar(
            controller: _onglets,
            tabs: [
              const Tab(text: 'Propositions'),
              const Tab(text: 'Carnet'),
              if (cuisine.enLigne != null) const Tab(text: 'En ligne'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _onglets,
              children: [
                _Propositions(
                  cuisine: cuisine,
                  style: _stylePropositions,
                  onStyle: (s) => setState(() => _stylePropositions = s),
                ),
                _Carnet(
                  cuisine: cuisine,
                  style: _styleCarnet,
                  texte: _texteCarnet,
                  onStyle: (s) => setState(() => _styleCarnet = s),
                  onTexte: (t) => setState(() => _texteCarnet = t),
                ),
                if (cuisine.enLigne != null)
                  _EnLigne(
                    cuisine: cuisine,
                    onResultats: (n) => _resultatsEnLigne.value = n,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void ouvrirRecette(BuildContext context, Cuisine cuisine, Recette r) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RecetteDetailScreen(cuisine: cuisine, recette: r),
      ),
    );

/// Puces de style (« Tous », « Gourmand », « Light »…).
class _ChoixStyle extends StatelessWidget {
  const _ChoixStyle({required this.style, required this.onChanged});

  final StyleRecette? style;
  final ValueChanged<StyleRecette?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: const Text('Tous les styles'),
            selected: style == null,
            onSelected: (_) => onChanged(null),
          ),
        ),
        for (final s in StyleRecette.values)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              key: Key('style-${s.name}'),
              label: Text(s.libelle),
              selected: style == s,
              onSelected: (_) => onChanged(s),
            ),
          ),
      ],
    ),
  );
}

class _Propositions extends StatelessWidget {
  const _Propositions({
    required this.cuisine,
    required this.style,
    required this.onStyle,
  });

  final Cuisine cuisine;
  final StyleRecette? style;
  final ValueChanged<StyleRecette?> onStyle;

  @override
  Widget build(BuildContext context) {
    final c = cuisine;
    final p = PaletteOdv.de(context);
    return ListenableBuilder(
      listenable: c.tout,
      builder: (context, _) {
        final liste = c.recettes.suggestions(c.frigo.elements, style: style);
        return Column(
          children: [
            const SizedBox(height: 8),
            _ChoixStyle(style: style, onChanged: onStyle),
            Expanded(
              child: liste.isEmpty
                  ? ListeVide(
                      icone: Icons.restaurant_menu,
                      message: c.frigo.elements.isEmpty
                          ? 'Le frigo est vide : ajoutez des aliments pour '
                                'recevoir des idées de repas.'
                          : 'Aucune recette ne correspond au contenu du '
                                'frigo pour ce style.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: liste.length,
                      itemBuilder: (context, i) {
                        final s = liste[i];
                        return CarteLigne(
                          key: Key('suggestion-${s.recette.id}'),
                          leading: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              value: s.score,
                              strokeWidth: 4,
                              color: s.complete
                                  ? vertOdv
                                  : const Color(0xFFE5A23A),
                              backgroundColor: p.champ,
                            ),
                          ),
                          title: Text(s.recette.nom),
                          subtitle: Text(
                            resumeSuggestion(s),
                            style: TextStyle(
                              color: s.complete ? p.accentDoux : null,
                            ),
                          ),
                          trailing: s.recette.minutes == null
                              ? null
                              : Text('${s.recette.minutes} min'),
                          onTap: () => ouvrirRecette(context, c, s.recette),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Carnet extends StatelessWidget {
  const _Carnet({
    required this.cuisine,
    required this.style,
    required this.texte,
    required this.onStyle,
    required this.onTexte,
  });

  final Cuisine cuisine;
  final String texte;
  final StyleRecette? style;
  final ValueChanged<StyleRecette?> onStyle;
  final ValueChanged<String> onTexte;

  @override
  Widget build(BuildContext context) {
    final c = cuisine;
    return Column(
      children: [
        const SizedBox(height: 8),
        // Hors du ListenableBuilder : le champ garde le texte saisi.
        ChampRecherche(indice: 'Nom ou ingrédient…', onChanged: onTexte),
        _ChoixStyle(style: style, onChanged: onStyle),
        Expanded(
          child: ListenableBuilder(
            listenable: c.recettes,
            builder: (context, _) {
              final liste = c.recettes.rechercher(texte: texte, style: style);
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                itemCount: liste.length,
                itemBuilder: (context, i) {
                  final r = liste[i];
                  return CarteLigne(
                    key: Key('recette-${r.id}'),
                    leading: IconeCarree(
                      r.modifiable ? Icons.edit_note : Icons.menu_book_outlined,
                    ),
                    title: Text(r.nom),
                    subtitle: Text(
                      [
                        if (r.modifiable) 'Ma recette',
                        ...r.styles.map((s) => s.libelle),
                        if (r.minutes != null) '${r.minutes} min',
                      ].join(' · '),
                    ),
                    onTap: () => ouvrirRecette(context, c, r),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EnLigne extends StatefulWidget {
  const _EnLigne({required this.cuisine, required this.onResultats});

  final Cuisine cuisine;
  final ValueChanged<int?> onResultats;

  @override
  State<_EnLigne> createState() => _EnLigneState();
}

class _EnLigneState extends State<_EnLigne> with AutomaticKeepAliveClientMixin {
  final _texte = TextEditingController();
  List<Recette>? _resultats;
  String? _erreur;
  bool _enCours = false;

  // Les résultats restent quand on change d'onglet (et l'en-tête aussi).
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _chercher() async {
    final t = _texte.text.trim();
    if (t.isEmpty) {
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final r = await widget.cuisine.enLigne!.chercher(t);
      if (mounted) {
        setState(() => _resultats = r);
        widget.onResultats(r.length);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Recherche impossible (pas de connexion ?).');
        widget.onResultats(null);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final r = _resultats;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            key: const Key('champ-recherche-en-ligne'),
            controller: _texte,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _chercher(),
            decoration: InputDecoration(
              hintText: 'chicken, pasta, soup… (en anglais)',
              prefixIcon: const Icon(Icons.public),
              suffixIcon: IconButton(
                tooltip: 'Chercher en ligne',
                icon: const Icon(Icons.search),
                onPressed: _chercher,
              ),
              helperText:
                  'Recettes de TheMealDB, en anglais. Ajoutez celles qui vous '
                  'plaisent à votre carnet.',
              helperMaxLines: 2,
            ),
          ),
        ),
        Expanded(
          child: _enCours
              ? const Center(child: CircularProgressIndicator())
              : _erreur != null
              ? ListeVide(icone: Icons.cloud_off, message: _erreur!)
              : r == null
              ? const ListeVide(
                  icone: Icons.travel_explore,
                  message: 'Cherchez un plat ou un ingrédient en anglais.',
                )
              : r.isEmpty
              ? const ListeVide(
                  icone: Icons.search_off,
                  message: 'Aucune recette trouvée.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: r.length,
                  itemBuilder: (context, i) => CarteLigne(
                    leading: const IconeCarree(Icons.public),
                    title: Text(r[i].nom),
                    subtitle: Text('${r[i].ingredients.length} ingrédients'),
                    onTap: () => ouvrirRecette(context, widget.cuisine, r[i]),
                  ),
                ),
        ),
      ],
    );
  }
}
