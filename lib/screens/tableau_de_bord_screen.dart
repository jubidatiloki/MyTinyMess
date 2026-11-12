import 'package:flutter/material.dart';

import '../models/lieu.dart';
import '../models/section.dart';
import '../state/bibliotheque_controller.dart';
import '../state/cave_controller.dart';
import '../state/lieux_controller.dart';
import '../theme.dart';
import '../widgets/lieux.dart';
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
                if (lieux.elements.isEmpty) ...[
                  const TitreSection('Emplacements'),
                  _aucunEmplacement(),
                ] else
                  for (final type in TypeLieu.values) ...[
                    TitreSection('Emplacements · ${type.libelle}'),
                    _emplacements(type),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _aucunEmplacement() => Card(
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

  /// Les emplacements d'un type avec ce qu'ils contiennent (sous-emplacements
  /// compris), puis ce qui n'est rangé nulle part.
  Widget _emplacements(TypeLieu type) {
    final livres = type == TypeLieu.livres;
    final noeuds = lieux.arbre(type: type);
    final sansLieu = livres
        ? bibliotheque.elements
              .where(
                (l) => !l.estSouhait && lieux.parId(l.lieuId ?? '') == null,
              )
              .length
        : cave.elements
              .where((b) => lieux.parId(b.emplacement.lieuId ?? '') == null)
              .fold(0, (s, b) => s + b.quantite);
    return CarteGroupe(
      enfants: [
        if (noeuds.isEmpty)
          ListTile(
            leading: IconeCarree(iconeTypeLieu(type)),
            title: Text('Aucun emplacement pour les ${type.contenu}'),
            trailing: TextButton(
              onPressed: () => onOuvrir(Section.emplacements),
              child: const Text('Créer'),
            ),
          ),
        for (final n in noeuds)
          _LigneEmplacement(
            key: Key('resume-lieu-${n.lieu.id}'),
            nom: n.lieu.nom,
            profondeur: n.profondeur,
            type: type,
            nombre: livres
                ? bibliotheque.nombreDans(n.lieu.id)
                : cave.nombreDans(n.lieu.id),
            onTap: () => onOuvrir(Section.emplacements),
          ),
        if (sansLieu > 0)
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
  });

  final String nom;
  final int profondeur;
  final TypeLieu type;

  /// Livres ou bouteilles (selon [type]) rangés dans cet emplacement.
  final int nombre;
  final VoidCallback? onTap;

  /// Ligne « Sans emplacement » : en italique.
  final bool discret;

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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
