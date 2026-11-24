import 'package:flutter/material.dart';

import '../../data/liens.dart';
import '../../data/partage_adresse.dart';
import '../../models/adresse.dart';
import '../../state/annuaire_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';
import 'adresse_detail_screen.dart';
import 'formulaire_adresse_screen.dart';

IconData iconeTypeAdresse(TypeAdresse t) => switch (t) {
  TypeAdresse.personne => Icons.person_outline,
  TypeAdresse.commerce => Icons.storefront_outlined,
  TypeAdresse.restaurant => Icons.restaurant_outlined,
  TypeAdresse.artisan => Icons.handyman_outlined,
  TypeAdresse.sante => Icons.spa_outlined,
  TypeAdresse.site => Icons.public,
  TypeAdresse.festival => Icons.celebration_outlined,
  TypeAdresse.sortie => Icons.place_outlined,
  TypeAdresse.autre => Icons.bookmark_border,
};

const couleurFavori = Color(0xFFE5A23A);

/// « Annuaire » : les bonnes adresses, regroupées par type.
class AnnuaireScreen extends StatefulWidget {
  const AnnuaireScreen({
    super.key,
    required this.annuaire,
    required this.ouvrirLien,
    required this.partager,
    this.menu,
  });

  final AnnuaireController annuaire;
  final OuvrirLien ouvrirLien;
  final Partager partager;
  final Widget? menu;

  @override
  State<AnnuaireScreen> createState() => _AnnuaireScreenState();
}

class _AnnuaireScreenState extends State<AnnuaireScreen> {
  String _recherche = '';
  TypeAdresse? _type;
  String? _etiquette;
  bool _favoris = false;

  void _ajouter() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => FormulaireAdresseScreen(
        annuaire: widget.annuaire,
        typeParDefaut: _type,
      ),
    ),
  );

  void _ouvrir(Adresse a) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => AdresseDetailScreen(
        annuaire: widget.annuaire,
        id: a.id,
        ouvrirLien: widget.ouvrirLien,
        partager: widget.partager,
      ),
    ),
  );

  Widget _puce(
    String libelle,
    bool choisie,
    VoidCallback onTap, {
    Key? key,
    IconData? icone,
  }) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      key: key,
      avatar: icone == null || choisie ? null : Icon(icone, size: 18),
      label: Text(libelle),
      selected: choisie,
      onSelected: (_) => setState(onTap),
    ),
  );

  Widget _rangee(List<Widget> puces) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: puces,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.annuaire;
    return PageOdv(
      titre: 'Annuaire',
      titreWidget: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final n = c.elements.length;
          return TitrePage(
            titre: 'Annuaire',
            sousTitre: n == 0
                ? 'Mes bonnes adresses'
                : '$n bonne${n > 1 ? 's' : ''} adresse${n > 1 ? 's' : ''}',
          );
        },
      ),
      menu: widget.menu,
      bouton: BoutonAjout(libelle: 'Ajouter une adresse', onPressed: _ajouter),
      corps: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          if (!c.charge) {
            return const Center(child: CircularProgressIndicator());
          }
          final types = c.types;
          final etiquettes = c.etiquettes;
          // Filtre devenu sans objet (dernière adresse supprimée) : ignoré.
          final type = types.contains(_type) ? _type : null;
          final etiquette = etiquettes.contains(_etiquette) ? _etiquette : null;
          final favoris = _favoris && c.elements.any((a) => a.favori);
          final liste = c.rechercher(
            texte: _recherche,
            type: type,
            etiquette: etiquette,
            favoris: favoris,
          );
          // Un titre devant chaque type, puis ses adresses.
          final lignes = <Object>[];
          for (final a in liste) {
            if (lignes.isEmpty || (lignes.last as Adresse).type != a.type) {
              lignes.add(a.type);
            }
            lignes.add(a);
          }
          return Column(
            children: [
              ChampRecherche(
                indice: 'Nom, ville, mot-clé…',
                onChanged: (t) => setState(() => _recherche = t),
              ),
              if (c.elements.isNotEmpty)
                _rangee([
                  _puce('Toutes', type == null && !favoris, () {
                    _type = null;
                    _favoris = false;
                  }),
                  _puce(
                    'Favoris',
                    favoris,
                    () => _favoris = !favoris,
                    key: const Key('filtre-favoris'),
                    icone: Icons.star_border,
                  ),
                  for (final t in types)
                    _puce(
                      t.pluriel,
                      type == t,
                      () => _type = type == t ? null : t,
                      key: Key('filtre-type-${t.name}'),
                      icone: iconeTypeAdresse(t),
                    ),
                ]),
              if (etiquettes.isNotEmpty)
                _rangee([
                  for (final e in etiquettes)
                    _puce(
                      '#$e',
                      etiquette == e,
                      () => _etiquette = etiquette == e ? null : e,
                      key: Key('filtre-etiquette-$e'),
                    ),
                ]),
              Expanded(
                child: liste.isEmpty
                    ? ListeVide(
                        icone: Icons.contacts_outlined,
                        message: c.elements.isEmpty
                            ? 'L\'annuaire est vide.\n'
                                  'Notez ici vos bonnes adresses : personnes, '
                                  'commerçants, sites, festivals…'
                            : 'Aucune adresse ne correspond.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: lignes.length,
                        itemBuilder: (context, i) => switch (lignes[i]) {
                          final TypeAdresse t => TitreSection(t.pluriel),
                          final Adresse a => _ligne(a),
                          _ => const SizedBox.shrink(),
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ligne(Adresse a) {
    final details = [
      [?a.description, ?a.lieu].join(' · '),
      a.etiquettes.map((e) => '#$e').join(' '),
    ].where((t) => t.isNotEmpty).join('\n');
    return CarteLigne(
      key: Key('adresse-${a.id}'),
      leading: IconeCarree(iconeTypeAdresse(a.type)),
      title: Text(a.nom),
      subtitle: details.isEmpty ? null : Text(details),
      trailing: IconButton(
        tooltip: a.favori ? 'Retirer des favoris' : 'Mettre en favori',
        icon: Icon(
          a.favori ? Icons.star : Icons.star_border,
          color: a.favori ? couleurFavori : null,
        ),
        onPressed: () => widget.annuaire.basculerFavori(a.id),
      ),
      onTap: () => _ouvrir(a),
    );
  }
}
