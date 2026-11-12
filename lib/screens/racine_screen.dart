import 'package:flutter/material.dart';

import '../models/section.dart';
import '../state/bibliotheque_controller.dart';
import '../state/cave_controller.dart';
import '../state/preferences_controller.dart';
import '../widgets/menu_lateral.dart';
import 'bibliotheque/liste_livres_screen.dart';
import 'cave/liste_bouteilles_screen.dart';
import 'pages_simples.dart';
import 'preferences_screen.dart';
import 'tableau_de_bord_screen.dart';

/// Affiche la rubrique choisie dans le menu latéral.
class RacineScreen extends StatefulWidget {
  const RacineScreen({
    super.key,
    required this.bibliotheque,
    required this.cave,
    required this.preferences,
  });

  final BibliothequeController bibliotheque;
  final CaveController cave;
  final PreferencesController preferences;

  @override
  State<RacineScreen> createState() => _RacineScreenState();
}

class _RacineScreenState extends State<RacineScreen> {
  late Section _section = widget.preferences.ecranDemarrage;

  void _ouvrir(Section s) => setState(() => _section = s);

  @override
  Widget build(BuildContext context) {
    final menu = MenuLateral(courante: _section, onChoisir: _ouvrir);
    return switch (_section) {
      Section.accueil => TableauDeBordScreen(
        bibliotheque: widget.bibliotheque,
        cave: widget.cave,
        onOuvrir: _ouvrir,
        menu: menu,
      ),
      Section.bibliotheque => ListeLivresScreen(
        controller: widget.bibliotheque,
        menu: menu,
      ),
      Section.cave => ListeBouteillesScreen(
        controller: widget.cave,
        menu: menu,
      ),
      Section.bazar => EcranAVenir(
        section: Section.bazar,
        icone: Icons.inventory_2_outlined,
        menu: menu,
      ),
      Section.contact => EcranAVenir(
        section: Section.contact,
        icone: Icons.mail_outline,
        menu: menu,
      ),
      Section.preferences => PreferencesScreen(
        controller: widget.preferences,
        menu: menu,
      ),
      Section.aPropos => AProposScreen(menu: menu),
    };
  }
}
