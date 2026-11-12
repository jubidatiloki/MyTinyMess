import 'package:flutter/material.dart';

import '../state/bibliotheque_controller.dart';
import '../state/cave_controller.dart';
import 'bibliotheque/liste_livres_screen.dart';
import 'cave/liste_bouteilles_screen.dart';

/// Écran principal : onglets « Bibliothèque » et « Cave ».
class AccueilScreen extends StatefulWidget {
  const AccueilScreen({
    super.key,
    required this.bibliotheque,
    required this.cave,
  });

  final BibliothequeController bibliotheque;
  final CaveController cave;

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  int _onglet = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _onglet,
        children: [
          ListeLivresScreen(controller: widget.bibliotheque),
          ListeBouteillesScreen(controller: widget.cave),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() => _onglet = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Bibliothèque',
          ),
          NavigationDestination(
            icon: Icon(Icons.wine_bar_outlined),
            selectedIcon: Icon(Icons.wine_bar),
            label: 'Cave',
          ),
        ],
      ),
    );
  }
}
