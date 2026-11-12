import 'package:flutter/material.dart';

import '../models/section.dart';
import '../state/bibliotheque_controller.dart';
import '../state/cave_controller.dart';
import '../state/lieux_controller.dart';
import '../state/preferences_controller.dart';
import '../widgets/menu_lateral.dart';
import 'bibliotheque/liste_livres_screen.dart';
import 'cave/liste_bouteilles_screen.dart';
import 'lieux_screen.dart';
import 'pages_simples.dart';
import 'preferences_screen.dart';
import 'tableau_de_bord_screen.dart';

/// Affiche la rubrique choisie dans le menu latéral.
class RacineScreen extends StatefulWidget {
  const RacineScreen({
    super.key,
    required this.bibliotheque,
    required this.cave,
    required this.lieux,
    required this.preferences,
  });

  /// Largeur d'écran à partir de laquelle le menu peut rester ouvert.
  static const largeurMenuFixe = 720.0;

  final BibliothequeController bibliotheque;
  final CaveController cave;

  /// Emplacements communs aux livres et à la cave.
  final LieuxController lieux;
  final PreferencesController preferences;

  @override
  State<RacineScreen> createState() => _RacineScreenState();
}

class _RacineScreenState extends State<RacineScreen> {
  late Section _section = widget.preferences.ecranDemarrage;

  void _ouvrir(Section s) => setState(() => _section = s);

  Widget _ecran(Widget? menu) => switch (_section) {
    Section.accueil => TableauDeBordScreen(
      bibliotheque: widget.bibliotheque,
      cave: widget.cave,
      lieux: widget.lieux,
      onOuvrir: _ouvrir,
      menu: menu,
    ),
    Section.bibliotheque => ListeLivresScreen(
      controller: widget.bibliotheque,
      lieux: widget.lieux,
      menu: menu,
      onGererLieux: () => _ouvrir(Section.emplacements),
    ),
    Section.cave => ListeBouteillesScreen(
      controller: widget.cave,
      lieux: widget.lieux,
      menu: menu,
      onGererLieux: () => _ouvrir(Section.emplacements),
    ),
    Section.emplacements => LieuxScreen(
      lieux: widget.lieux,
      bibliotheque: widget.bibliotheque,
      cave: widget.cave,
      menu: menu,
    ),
    Section.bazar => EcranAVenir(
      section: Section.bazar,
      icone: Icons.inventory_2_outlined,
      menu: menu,
    ),
    Section.preferences => PreferencesScreen(
      controller: widget.preferences,
      menu: menu,
    ),
    Section.aPropos => AProposScreen(menu: menu),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.preferences,
      builder: (context, _) => LayoutBuilder(
        builder: (context, contraintes) {
          final fixe =
              widget.preferences.menuFixe &&
              contraintes.maxWidth >= RacineScreen.largeurMenuFixe;
          final menu = MenuLateral(
            courante: _section,
            onChoisir: _ouvrir,
            fixe: fixe,
          );
          if (!fixe) {
            return _ecran(menu);
          }
          // Menu toujours visible à gauche, écran à droite (sans bouton ☰).
          return Row(
            children: [
              SizedBox(width: MenuLateral.largeurFixe, child: menu),
              Expanded(child: _ecran(null)),
            ],
          );
        },
      ),
    );
  }
}
