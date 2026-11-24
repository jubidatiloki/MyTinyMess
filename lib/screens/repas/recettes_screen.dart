import 'package:flutter/material.dart';

import '../../models/recette.dart';
import '../../state/cuisine.dart';
import '../../theme.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';
import 'formulaire_recette_screen.dart';
import 'recette_detail_screen.dart';

/// Rubrique « Repas & recettes » : propositions selon le frigo, carnet de
/// recettes (intégrées + personnelles) et recherche en ligne.
class RecettesScreen extends StatelessWidget {
  const RecettesScreen({super.key, required this.cuisine, this.menu});

  final Cuisine cuisine;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: cuisine.enLigne == null ? 2 : 3,
      child: PageOdv(
        titre: 'Repas & recettes',
        sousTitre: 'Idées selon le frigo, carnet et recherche en ligne',
        menu: menu,
        bouton: BoutonAjout(
          libelle: 'Ajouter une recette',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  FormulaireRecetteScreen(recettes: cuisine.recettes),
            ),
          ),
        ),
        corps: Column(
          children: [
            TabBar(
              tabs: [
                const Tab(text: 'Propositions'),
                const Tab(text: 'Carnet'),
                if (cuisine.enLigne != null) const Tab(text: 'En ligne'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _Propositions(cuisine: cuisine),
                  _Carnet(cuisine: cuisine),
                  if (cuisine.enLigne != null) _EnLigne(cuisine: cuisine),
                ],
              ),
            ),
          ],
        ),
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
              label: Text(s.libelle),
              selected: style == s,
              onSelected: (_) => onChanged(s),
            ),
          ),
      ],
    ),
  );
}

class _Propositions extends StatefulWidget {
  const _Propositions({required this.cuisine});

  final Cuisine cuisine;

  @override
  State<_Propositions> createState() => _PropositionsState();
}

class _PropositionsState extends State<_Propositions> {
  StyleRecette? _style;

  @override
  Widget build(BuildContext context) {
    final c = widget.cuisine;
    final p = PaletteOdv.de(context);
    return ListenableBuilder(
      listenable: c.tout,
      builder: (context, _) {
        final liste = c.recettes.suggestions(c.frigo.elements, style: _style);
        return Column(
          children: [
            const SizedBox(height: 8),
            _ChoixStyle(
              style: _style,
              onChanged: (s) => setState(() => _style = s),
            ),
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

class _Carnet extends StatefulWidget {
  const _Carnet({required this.cuisine});

  final Cuisine cuisine;

  @override
  State<_Carnet> createState() => _CarnetState();
}

class _CarnetState extends State<_Carnet> {
  String _texte = '';
  StyleRecette? _style;

  @override
  Widget build(BuildContext context) {
    final c = widget.cuisine;
    return ListenableBuilder(
      listenable: c.recettes,
      builder: (context, _) {
        final liste = c.recettes.rechercher(texte: _texte, style: _style);
        return Column(
          children: [
            const SizedBox(height: 8),
            ChampRecherche(
              indice: 'Nom ou ingrédient…',
              onChanged: (t) => setState(() => _texte = t),
            ),
            _ChoixStyle(
              style: _style,
              onChanged: (s) => setState(() => _style = s),
            ),
            Expanded(
              child: ListView.builder(
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
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EnLigne extends StatefulWidget {
  const _EnLigne({required this.cuisine});

  final Cuisine cuisine;

  @override
  State<_EnLigne> createState() => _EnLigneState();
}

class _EnLigneState extends State<_EnLigne> {
  final _texte = TextEditingController();
  List<Recette>? _resultats;
  String? _erreur;
  bool _enCours = false;

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
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Recherche impossible (pas de connexion ?).');
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
