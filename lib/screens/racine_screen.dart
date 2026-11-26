import 'package:flutter/material.dart';

import '../data/liens.dart';
import '../data/partage_adresse.dart';
import '../data/recherche_isbn.dart';
import '../models/section.dart';
import '../state/annuaire_controller.dart';
import '../state/bibliotheque_controller.dart';
import '../state/categories_controller.dart';
import '../state/cave_controller.dart';
import '../state/cuisine.dart';
import '../state/frigo_controller.dart';
import '../state/lieux_controller.dart';
import '../state/preferences_controller.dart';
import '../state/types_bouteille_controller.dart';
import '../widgets/menu_lateral.dart';
import 'agenda/agenda_screen.dart';
import 'annuaire/annuaire_screen.dart';
import 'bibliotheque/liste_livres_screen.dart';
import 'bibliotheque/scanner_isbn_screen.dart';
import 'cave/liste_bouteilles_screen.dart';
import 'courses/courses_screen.dart';
import 'frigo/liste_aliments_screen.dart';
import 'lieux_screen.dart';
import 'pages_simples.dart';
import 'nouveautes_screen.dart';
import 'preferences_screen.dart';
import 'repas/recettes_screen.dart';
import 'tableau_de_bord_screen.dart';

/// Affiche la rubrique choisie dans le menu latéral.
class RacineScreen extends StatefulWidget {
  const RacineScreen({
    super.key,
    required this.bibliotheque,
    required this.cave,
    required this.types,
    required this.categories,
    required this.frigo,
    required this.lieux,
    required this.preferences,
    required this.cuisine,
    required this.annuaire,
    required this.ouvrirLien,
    required this.partager,
    this.rechercheIsbn,
    this.scannerIsbn,
  });

  /// Largeur d'écran à partir de laquelle le menu peut rester ouvert.
  static const largeurMenuFixe = 720.0;

  final BibliothequeController bibliotheque;
  final CaveController cave;
  final TypesBouteilleController types;
  final CategoriesController categories;
  final FrigoController frigo;

  /// Emplacements (livres, cave et frigo).
  final LieuxController lieux;
  final PreferencesController preferences;

  /// Recettes, frigo, courses et agenda (rubriques Repas, Courses, Agenda).
  final Cuisine cuisine;

  /// Bonnes adresses, et ouverture de leurs liens.
  final AnnuaireController annuaire;
  final OuvrirLien ouvrirLien;
  final Partager partager;

  /// Recherche des livres par ISBN et scanner de code-barres.
  final RechercheIsbn? rechercheIsbn;
  final ScannerIsbn? scannerIsbn;

  @override
  State<RacineScreen> createState() => _RacineScreenState();
}

class _RacineScreenState extends State<RacineScreen> {
  late Section _section = widget.preferences.ecranDemarrage;

  void _ouvrir(Section s) => setState(() => _section = s);

  void _gererLieux() => _ouvrir(Section.emplacements);

  Widget _ecran(Widget? menu) => switch (_section) {
    Section.accueil => TableauDeBordScreen(
      preferences: widget.preferences,
      cuisine: widget.cuisine,
      annuaire: widget.annuaire,
      bibliotheque: widget.bibliotheque,
      cave: widget.cave,
      frigo: widget.frigo,
      lieux: widget.lieux,
      onOuvrir: _ouvrir,
      menu: menu,
    ),
    Section.bibliotheque => ListeLivresScreen(
      controller: widget.bibliotheque,
      lieux: widget.lieux,
      menu: menu,
      onGererLieux: _gererLieux,
      recherche: widget.rechercheIsbn,
      scanner: widget.scannerIsbn,
    ),
    Section.cave => ListeBouteillesScreen(
      controller: widget.cave,
      lieux: widget.lieux,
      types: widget.types,
      menu: menu,
      onGererLieux: _gererLieux,
    ),
    Section.frigo => ListeAlimentsScreen(
      preferences: widget.preferences,
      controller: widget.frigo,
      lieux: widget.lieux,
      menu: menu,
      onGererLieux: _gererLieux,
      courses: widget.cuisine.courses,
    ),
    Section.recettes => RecettesScreen(cuisine: widget.cuisine, menu: menu),
    Section.courses => CoursesScreen(cuisine: widget.cuisine, menu: menu),
    Section.agenda => AgendaScreen(
      cuisine: widget.cuisine,
      preferences: widget.preferences,
      menu: menu,
    ),
    Section.annuaire => AnnuaireScreen(
      annuaire: widget.annuaire,
      ouvrirLien: widget.ouvrirLien,
      partager: widget.partager,
      menu: menu,
    ),
    Section.emplacements => LieuxScreen(
      lieux: widget.lieux,
      bibliotheque: widget.bibliotheque,
      cave: widget.cave,
      frigo: widget.frigo,
      menu: menu,
    ),
    Section.bazar => EcranAVenir(
      section: Section.bazar,
      icone: Icons.inventory_2_outlined,
      menu: menu,
    ),
    Section.preferences => PreferencesScreen(
      controller: widget.preferences,
      types: widget.types,
      cave: widget.cave,
      categories: widget.categories,
      frigo: widget.frigo,
      menu: menu,
    ),
    Section.nouveautes => NouveautesScreen(menu: menu),
    Section.aPropos => AProposScreen(menu: menu),
  };

  @override
  Widget build(BuildContext context) {
    // Bouton « précédent » (téléphone, navigateur) : depuis une rubrique, on
    // revient à la vue d'ensemble au lieu de quitter l'application.
    return PopScope(
      canPop: _section == Section.accueil,
      onPopInvokedWithResult: (aQuitte, _) {
        if (!aQuitte) {
          _ouvrir(Section.accueil);
        }
      },
      child: ListenableBuilder(
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
            // Menu toujours visible à gauche, écran à droite (sans ☰).
            return Row(
              children: [
                SizedBox(width: MenuLateral.largeurFixe, child: menu),
                Expanded(child: _ecran(null)),
              ],
            );
          },
        ),
      ),
    );
  }
}
