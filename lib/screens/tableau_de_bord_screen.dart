import 'package:flutter/material.dart';

import '../models/section.dart';
import '../state/bibliotheque_controller.dart';
import '../state/cave_controller.dart';
import '../widgets/page.dart';

/// « Vue d'ensemble » : une tuile par collection avec son compteur.
class TableauDeBordScreen extends StatelessWidget {
  const TableauDeBordScreen({
    super.key,
    required this.bibliotheque,
    required this.cave,
    required this.onOuvrir,
    this.menu,
  });

  final BibliothequeController bibliotheque;
  final CaveController cave;
  final ValueChanged<Section> onOuvrir;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: Section.accueil.libelle,
      sousTitre: 'Vos collections en un coup d\'œil',
      menu: menu,
      corps: ListenableBuilder(
        listenable: Listenable.merge([bibliotheque, cave]),
        builder: (context, _) {
          final livres = bibliotheque.elements.length;
          final bouteilles = cave.totalBouteilles;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Wrap(
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
            ),
          );
        },
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
