import 'package:flutter/material.dart';

import '../models/section.dart';
import '../state/bibliotheque_controller.dart';
import '../state/cave_controller.dart';
import '../state/lieux_controller.dart';
import '../theme.dart';
import '../widgets/page.dart';

/// « Vue d'ensemble » : une tuile par collection avec son compteur, puis
/// tous les emplacements avec ce qu'ils contiennent.
class TableauDeBordScreen extends StatelessWidget {
  const TableauDeBordScreen({
    super.key,
    required this.bibliotheque,
    required this.cave,
    required this.lieux,
    required this.onOuvrir,
    this.menu,
  });

  final BibliothequeController bibliotheque;
  final CaveController cave;
  final LieuxController lieux;
  final ValueChanged<Section> onOuvrir;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: Section.accueil.libelle,
      sousTitre: 'Vos collections en un coup d\'œil',
      menu: menu,
      corps: ListenableBuilder(
        listenable: Listenable.merge([bibliotheque, cave, lieux]),
        builder: (context, _) {
          final livres = bibliotheque.nombreLivres;
          final bouteilles = cave.totalBouteilles;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tuiles(livres, bouteilles),
                const TitreSection('Emplacements'),
                _emplacements(context),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Liste de tous les emplacements avec le nombre de livres et de
  /// bouteilles dans chacun (sous-emplacements compris).
  Widget _emplacements(BuildContext context) {
    final noeuds = lieux.arbre();
    if (noeuds.isEmpty) {
      return Card(
        child: ListTile(
          leading: const IconeCarree(Icons.shelves),
          title: const Text('Aucun emplacement'),
          subtitle: const Text(
            'Créez vos pièces, meubles et étagères pour savoir où est rangé '
            'chaque livre et chaque bouteille.',
          ),
          trailing: TextButton(
            onPressed: () => onOuvrir(Section.emplacements),
            child: const Text('Créer'),
          ),
        ),
      );
    }
    final livresSansLieu = bibliotheque.elements
        .where((l) => !l.estSouhait && lieux.parId(l.lieuId ?? '') == null)
        .length;
    final bouteillesSansLieu = cave.elements
        .where((b) => lieux.parId(b.emplacement.lieuId ?? '') == null)
        .fold(0, (s, b) => s + b.quantite);
    return CarteGroupe(
      enfants: [
        for (final n in noeuds)
          _LigneEmplacement(
            key: Key('resume-lieu-${n.lieu.id}'),
            nom: n.lieu.nom,
            profondeur: n.profondeur,
            livres: bibliotheque.nombreDans(n.lieu.id),
            bouteilles: cave.nombreDans(n.lieu.id),
            onTap: () => onOuvrir(Section.emplacements),
          ),
        if (livresSansLieu > 0 || bouteillesSansLieu > 0)
          _LigneEmplacement(
            key: const Key('resume-lieu-aucun'),
            nom: 'Sans emplacement',
            profondeur: 0,
            livres: livresSansLieu,
            bouteilles: bouteillesSansLieu,
            discret: true,
          ),
      ],
    );
  }

  Widget _tuiles(int livres, int bouteilles) => Wrap(
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
    ],
  );
}

/// Ligne « Salon ……… 📖 12  🍷 6 » de la vue d'ensemble.
class _LigneEmplacement extends StatelessWidget {
  const _LigneEmplacement({
    super.key,
    required this.nom,
    required this.profondeur,
    required this.livres,
    required this.bouteilles,
    this.onTap,
    this.discret = false,
  });

  final String nom;
  final int profondeur;
  final int livres;
  final int bouteilles;
  final VoidCallback? onTap;

  /// Ligne « Sans emplacement » : en italique.
  final bool discret;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    Widget compteur(IconData icone, int n, String unite) => Tooltip(
      message: '$n $unite',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: n == 0 ? p.separateur : p.accentDoux),
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            child: Text(
              '$n',
              style: TextStyle(
                color: n == 0 ? p.texteSecondaire : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.only(left: 16 + 24.0 * profondeur, right: 12),
      leading: IconeCarree(
        discret
            ? Icons.help_outline
            : (profondeur == 0
                  ? Icons.place_outlined
                  : Icons.subdirectory_arrow_right),
      ),
      title: Text(
        nom,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: discret
            ? TextStyle(fontStyle: FontStyle.italic, color: p.texteSecondaire)
            : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          compteur(Icons.menu_book_outlined, livres, 'livres'),
          const SizedBox(width: 12),
          compteur(Icons.wine_bar_outlined, bouteilles, 'bouteilles'),
        ],
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
