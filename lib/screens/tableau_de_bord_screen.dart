import 'package:flutter/material.dart';

import '../models/agenda.dart';
import '../models/lieu.dart';
import '../models/section.dart';
import '../state/annuaire_controller.dart';
import '../state/bibliotheque_controller.dart';
import '../state/cave_controller.dart';
import '../state/cuisine.dart';
import '../state/frigo_controller.dart';
import '../state/lieux_controller.dart';
import '../state/preferences_controller.dart';
import '../theme.dart';
import '../widgets/communs.dart';
import '../widgets/lieux.dart';
import '../widgets/page.dart';

/// « Vue d'ensemble » : une tuile par collection avec son compteur, une
/// alerte pour les aliments à consommer vite, puis tous les emplacements
/// avec ce qu'ils contiennent.
class TableauDeBordScreen extends StatelessWidget {
  const TableauDeBordScreen({
    super.key,
    required this.bibliotheque,
    required this.cave,
    required this.frigo,
    required this.cuisine,
    required this.annuaire,
    required this.preferences,
    required this.lieux,
    required this.onOuvrir,
    this.menu,
  });

  final BibliothequeController bibliotheque;
  final CaveController cave;
  final FrigoController frigo;

  /// Agenda, repas et courses (carte « Aujourd'hui »).
  final Cuisine cuisine;
  final AnnuaireController annuaire;
  final LieuxController lieux;

  /// Mémorise les groupes d'emplacements repliés.
  final PreferencesController preferences;
  final ValueChanged<Section> onOuvrir;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: Section.accueil.libelle,
      sousTitre: 'Vos collections en un coup d\'œil',
      menu: menu,
      corps: ListenableBuilder(
        listenable: Listenable.merge([
          bibliotheque,
          cave,
          annuaire,
          lieux,
          preferences,
          cuisine.tout,
        ]),
        builder: (context, _) {
          final aSurveiller = frigo.nombreASurveiller;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tuiles(),
                if (aSurveiller > 0) ...[
                  const SizedBox(height: 16),
                  Card(
                    key: const Key('alerte-frigo'),
                    child: ListTile(
                      leading: const IconeCarree(
                        Icons.warning_amber_rounded,
                        couleur: Color(0xFFE5A23A),
                      ),
                      title: Text(
                        '$aSurveiller aliment${aSurveiller > 1 ? 's' : ''} '
                        'à consommer vite',
                      ),
                      subtitle: const Text('Périmés ou bientôt périmés'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onOuvrir(Section.frigo),
                    ),
                  ),
                ],
                const TitreSection('Aujourd\'hui'),
                _aujourdhui(context),
                if (lieux.elements.isEmpty) ...[
                  const TitreSection('Emplacements'),
                  _aucunEmplacement(),
                ] else ...[
                  _titreEmplacements(),
                  for (final type in TypeLieu.values) _emplacements(type),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Événements et repas du jour, articles à acheter.
  Widget _aujourdhui(BuildContext context) {
    final p = PaletteOdv.de(context);
    final jour = DateTime.now();
    final evenements = cuisine.evenements.du(jour);
    String? repas(MomentRepas m) {
      final r = cuisine.repas.du(jour, m);
      return cuisine.recettes.recette(r?.recetteId)?.nom ?? r?.libelle;
    }

    final aAcheter = cuisine.courses.nombreAAcheter;
    return CarteGroupe(
      key: const Key('carte-aujourdhui'),
      enfants: [
        ListTile(
          leading: const IconeCarree(Icons.calendar_month_outlined),
          title: Text(
            evenements.isEmpty
                ? 'Aucun événement'
                : evenements
                      .map((e) => [?e.heure, e.titre].join(' · '))
                      .join('\n'),
          ),
          subtitle: Text(jourEnLettres(jour)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onOuvrir(Section.agenda),
        ),
        for (final m in MomentRepas.values)
          ListTile(
            leading: IconeCarree(
              m == MomentRepas.midi
                  ? Icons.wb_sunny_outlined
                  : Icons.nightlight_outlined,
            ),
            title: Text(
              repas(m) ?? 'Rien de prévu',
              style: repas(m) == null
                  ? TextStyle(color: p.texteSecondaire)
                  : null,
            ),
            subtitle: Text(m.libelle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                onOuvrir(repas(m) == null ? Section.recettes : Section.agenda),
          ),
        ListTile(
          leading: const IconeCarree(Icons.shopping_cart_outlined),
          title: Text(
            aAcheter == 0
                ? 'Liste de courses vide'
                : '$aAcheter article${aAcheter > 1 ? 's' : ''} à acheter',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onOuvrir(Section.courses),
        ),
      ],
    );
  }

  Widget _aucunEmplacement() => Card(
    child: ListTile(
      leading: const IconeCarree(Icons.shelves),
      title: const Text('Aucun emplacement'),
      subtitle: const Text(
        'Créez vos pièces, meubles et étagères pour savoir où est rangé '
        'chaque livre, chaque bouteille et chaque aliment.',
      ),
      trailing: TextButton(
        onPressed: () => onOuvrir(Section.emplacements),
        child: const Text('Créer'),
      ),
    ),
  );

  /// Ce qu'un emplacement contient (sous-emplacements compris).
  int _nombreDans(TypeLieu type, String lieuId) => switch (type) {
    TypeLieu.livres => bibliotheque.nombreDans(lieuId),
    TypeLieu.cave => cave.nombreDans(lieuId),
    TypeLieu.frigo => frigo.nombreDans(lieuId),
  };

  bool _sansLieu(String? lieuId) => lieux.parId(lieuId ?? '') == null;

  /// « Emplacements » et le bouton qui replie ou déplie tous les groupes.
  Widget _titreEmplacements() {
    final toutReplie = TypeLieu.values.every(
      (t) => preferences.replies.contains(t.name),
    );
    return Row(
      children: [
        const Expanded(child: TitreSection('Emplacements')),
        TextButton.icon(
          key: const Key('regrouper-emplacements'),
          icon: Icon(toutReplie ? Icons.unfold_more : Icons.unfold_less),
          label: Text(toutReplie ? 'Tout déplier' : 'Tout regrouper'),
          onPressed: () => preferences.changerReplies(
            toutReplie ? {} : {for (final t in TypeLieu.values) t.name},
          ),
        ),
      ],
    );
  }

  /// Emplacements visibles : sans le contenu de ceux qui sont repliés.
  List<NoeudLieu> _visibles(List<NoeudLieu> noeuds) {
    final resultat = <NoeudLieu>[];
    int? replie;
    for (final n in noeuds) {
      if (replie != null && n.profondeur > replie) {
        continue;
      }
      replie = preferences.replies.contains(n.lieu.id) ? n.profondeur : null;
      resultat.add(n);
    }
    return resultat;
  }

  /// Un groupe (repliable) par type : les emplacements avec ce qu'ils
  /// contiennent (sous-emplacements compris), puis ce qui n'est pas rangé.
  Widget _emplacements(TypeLieu type) {
    final noeuds = lieux.arbre(type: type);
    final replie = preferences.replies.contains(type.name);
    final sansLieu = switch (type) {
      TypeLieu.livres =>
        bibliotheque.elements
            .where((l) => !l.estSouhait && _sansLieu(l.lieuId))
            .length,
      TypeLieu.cave =>
        cave.elements
            .where((b) => _sansLieu(b.emplacement.lieuId))
            .fold(0, (s, b) => s + b.quantite),
      TypeLieu.frigo =>
        frigo.elements
            .where((a) => _sansLieu(a.lieuId))
            .fold(0, (s, a) => s + a.quantite),
    };
    final total = noeuds
        .where((n) => n.profondeur == 0)
        .fold(sansLieu, (s, n) => s + _nombreDans(type, n.lieu.id));
    final carte = CarteGroupe(
      enfants: [
        ListTile(
          key: Key('groupe-${type.name}'),
          leading: IconeCarree(iconeTypeLieu(type)),
          title: Text(
            type.libelle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '$total ${total > 1 ? type.contenu : type.unite} · '
            '${noeuds.length} emplacement${noeuds.length > 1 ? 's' : ''}',
          ),
          trailing: Icon(replie ? Icons.expand_more : Icons.expand_less),
          onTap: () => preferences.basculerRepli(type.name),
        ),
        if (!replie && noeuds.isEmpty)
          ListTile(
            leading: IconeCarree(iconeTypeLieu(type)),
            title: Text('Aucun emplacement pour les ${type.contenu}'),
            trailing: TextButton(
              onPressed: () => onOuvrir(Section.emplacements),
              child: const Text('Créer'),
            ),
          ),
        for (final n in replie ? const <NoeudLieu>[] : _visibles(noeuds))
          _LigneEmplacement(
            key: Key('resume-lieu-${n.lieu.id}'),
            nom: n.lieu.nom,
            profondeur: n.profondeur,
            type: type,
            nombre: _nombreDans(type, n.lieu.id),
            replie: lieux.enfants(n.lieu.id).isEmpty
                ? null
                : preferences.replies.contains(n.lieu.id),
            onReplier: () => preferences.basculerRepli(n.lieu.id),
            onTap: () => onOuvrir(Section.emplacements),
          ),
        if (!replie && sansLieu > 0)
          _LigneEmplacement(
            key: Key('resume-lieu-aucun-${type.name}'),
            nom: 'Sans emplacement',
            profondeur: 0,
            type: type,
            nombre: sansLieu,
            discret: true,
          ),
      ],
    );
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: carte);
  }

  Widget _tuiles() {
    final livres = bibliotheque.nombreLivres;
    final bouteilles = cave.totalBouteilles;
    final aliments = frigo.nombreArticles;
    final adresses = annuaire.elements.length;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        TuileCompteur(
          key: const Key('tuile-livres'),
          nombre: livres,
          libelle: livres > 1 ? 'livres' : 'livre',
          image: 'assets/images/bibliotheque.jpg',
          icone: Icons.menu_book,
          couleurs: const [Color(0xFF6B4A2B), Color(0xFF2E2016)],
          onTap: () => onOuvrir(Section.bibliotheque),
        ),
        TuileCompteur(
          key: const Key('tuile-bouteilles'),
          nombre: bouteilles,
          libelle: bouteilles > 1 ? 'bouteilles' : 'bouteille',
          image: 'assets/images/cave.jpg',
          icone: Icons.wine_bar,
          couleurs: const [Color(0xFF7B1E3A), Color(0xFF2A1218)],
          onTap: () => onOuvrir(Section.cave),
        ),
        TuileCompteur(
          key: const Key('tuile-aliments'),
          nombre: aliments,
          libelle: aliments > 1 ? 'aliments' : 'aliment',
          image: 'assets/images/frigo.jpg',
          icone: Icons.kitchen,
          couleurs: const [Color(0xFF2F6F7E), Color(0xFF143238)],
          onTap: () => onOuvrir(Section.frigo),
        ),
        TuileCompteur(
          key: const Key('tuile-adresses'),
          nombre: adresses,
          libelle: adresses > 1 ? 'adresses' : 'adresse',
          image: 'assets/images/annuaire.jpg',
          icone: Icons.contacts,
          couleurs: const [Color(0xFF4B4A86), Color(0xFF1D1C38)],
          onTap: () => onOuvrir(Section.annuaire),
        ),
      ],
    );
  }
}

/// Ligne « Salon ……… 📖 12 » de la vue d'ensemble.
class _LigneEmplacement extends StatelessWidget {
  const _LigneEmplacement({
    super.key,
    required this.nom,
    required this.profondeur,
    required this.type,
    required this.nombre,
    this.onTap,
    this.discret = false,
    this.replie,
    this.onReplier,
  });

  final String nom;
  final int profondeur;
  final TypeLieu type;

  /// Livres ou bouteilles (selon [type]) rangés dans cet emplacement.
  final int nombre;
  final VoidCallback? onTap;

  /// Ligne « Sans emplacement » : en italique.
  final bool discret;

  /// Contenu replié ou non (null = pas de sous-emplacement).
  final bool? replie;
  final VoidCallback? onReplier;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.only(left: 16 + 24.0 * profondeur, right: 16),
      leading: IconeCarree(
        discret
            ? Icons.help_outline
            : (profondeur == 0
                  ? iconeTypeLieu(type)
                  : Icons.subdirectory_arrow_right),
      ),
      title: Text(
        nom,
        style: discret
            ? TextStyle(fontStyle: FontStyle.italic, color: p.texteSecondaire)
            : null,
      ),
      trailing: Tooltip(
        message: '$nombre ${type.contenu}',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconeTypeLieu(type),
              size: 16,
              color: nombre == 0 ? p.separateur : p.accentDoux,
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 32,
              child: Text(
                '$nombre',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: nombre == 0 ? p.texteSecondaire : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (replie != null)
              IconButton(
                tooltip: replie! ? 'Déplier' : 'Regrouper',
                icon: Icon(replie! ? Icons.expand_more : Icons.expand_less),
                onPressed: onReplier,
              ),
          ],
        ),
      ),
    );
  }
}

/// Tuile carrée : photo en fond, gros chiffre en haut, libellé en bas.
/// Si la photo n'existe pas encore, un dégradé avec une icône la remplace.
class TuileCompteur extends StatelessWidget {
  const TuileCompteur({
    super.key,
    required this.nombre,
    required this.libelle,
    required this.image,
    required this.icone,
    required this.couleurs,
    required this.onTap,
  });

  static const taille = 156.0;

  final int nombre;
  final String libelle;
  final String image;
  final IconData icone;
  final List<Color> couleurs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const ombreTexte = [Shadow(blurRadius: 6, color: Colors.black87)];
    final remplacement = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: couleurs,
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Icon(icone, size: 90, color: Colors.white12),
      ),
    );
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => remplacement,
                ),
                // Voile sombre pour que le texte reste lisible sur la photo.
                const DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black26),
                ),
                Positioned(
                  left: 8,
                  top: 4,
                  right: 8,
                  height: 80,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$nombre',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        shadows: ombreTexte,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  height: 30,
                  child: FittedBox(
                    alignment: Alignment.centerRight,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      libelle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        shadows: ombreTexte,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
