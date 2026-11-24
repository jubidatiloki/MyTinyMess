import 'package:flutter/material.dart';

import '../../state/categories_controller.dart';
import '../../state/frigo_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';
import '../repas/actions_repas.dart';

/// Écran « Catégories d'aliments » (ouvert depuis les préférences).
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({
    super.key,
    required this.categories,
    required this.frigo,
  });

  final CategoriesController categories;
  final FrigoController frigo;

  Future<void> _editer(BuildContext context, [CategorieAliment? c]) =>
      showDialog<void>(
        context: context,
        builder: (_) => _DialogueCategorie(
          categories: categories,
          frigo: frigo,
          categorie: c,
        ),
      );

  Future<void> _supprimer(BuildContext context, CategorieAliment c) async {
    final n = frigo.dansCategorie(c.nom).length;
    if (categories.elements.length <= 1) {
      await informer(context, 'Il faut garder au moins une catégorie.');
    } else if (n > 0) {
      await informer(
        context,
        'Des aliments utilisent encore la catégorie « ${c.nom} ». '
        'Changez leur catégorie avant de la supprimer.',
      );
    } else if (await confirmer(
      context,
      'Supprimer la catégorie « ${c.nom} » ?',
    )) {
      await categories.supprimer(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: 'Catégories d\'aliments',
      sousTitre: 'Pour classer et filtrer le contenu du frigo',
      bouton: BoutonAjout(
        libelle: 'Ajouter une catégorie',
        onPressed: () => _editer(context),
      ),
      corps: ListenableBuilder(
        listenable: Listenable.merge([categories, frigo]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            for (final c in categories.elements)
              CarteLigne(
                key: Key('categorie-${c.nom}'),
                leading: const IconeCarree(Icons.label_outline),
                title: Text(c.nom),
                subtitle: Text(_resume(frigo.dansCategorie(c.nom).length)),
                onTap: () => _editer(context, c),
                trailing: IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _supprimer(context, c),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _resume(int n) =>
      n == 0 ? 'Aucun aliment' : '$n aliment${n > 1 ? 's' : ''}';
}

class _DialogueCategorie extends StatefulWidget {
  const _DialogueCategorie({
    required this.categories,
    required this.frigo,
    this.categorie,
  });

  final CategoriesController categories;
  final FrigoController frigo;
  final CategorieAliment? categorie;

  @override
  State<_DialogueCategorie> createState() => _DialogueCategorieState();
}

class _DialogueCategorieState extends State<_DialogueCategorie> {
  late final _nom = TextEditingController(text: widget.categorie?.nom);
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final nom = _nom.text.trim();
    final ancienne = widget.categorie;
    if (nom.isEmpty) {
      setState(() => _erreur = 'Donnez un nom');
      return;
    }
    final meme = widget.categories.parNom(nom);
    if (meme != null && meme.id != ancienne?.id) {
      setState(() => _erreur = 'Cette catégorie existe déjà');
      return;
    }
    if (ancienne == null) {
      await widget.categories.creer(nom);
    } else {
      // Les aliments suivent le nouveau nom.
      await widget.frigo.renommerCategorie(ancienne.nom, nom);
      await widget.categories.enregistrer(
        CategorieAliment(id: ancienne.id, nom: nom),
      );
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.categorie == null ? 'Nouvelle catégorie' : 'Renommer la catégorie',
    ),
    content: TextField(
      key: const Key('champ-nom-categorie'),
      controller: _nom,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: 'Nom', errorText: _erreur),
      onSubmitted: (_) => _valider(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        key: const Key('valider-categorie'),
        onPressed: _valider,
        child: const Text('Enregistrer'),
      ),
    ],
  );
}
