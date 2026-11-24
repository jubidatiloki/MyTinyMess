import 'package:flutter/material.dart';

import '../../models/type_bouteille.dart';
import '../../state/cave_controller.dart';
import '../../state/types_bouteille_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';

/// Écran « Types de bouteille » : la liste des types proposés dans la cave
/// (rouge, blanc, bière, spiritueux…), à créer, renommer, colorer, supprimer.
class TypesBouteilleScreen extends StatelessWidget {
  const TypesBouteilleScreen({
    super.key,
    required this.types,
    required this.cave,
  });

  final TypesBouteilleController types;
  final CaveController cave;

  Future<void> _supprimer(BuildContext context, TypeBouteille t) async {
    // Toute bouteille de ce type, même épuisée, empêche la suppression.
    final n = cave.elements.where((b) => b.typeId == t.id).length;
    String? refus;
    if (types.elements.length <= 1) {
      refus = 'Il faut garder au moins un type.';
    } else if (n > 0) {
      refus =
          'Des bouteilles utilisent encore le type « ${t.nom} ». '
          'Changez leur type avant de le supprimer.';
    }
    if (refus != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(refus!),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
      return;
    }
    if (context.mounted &&
        await confirmer(context, 'Supprimer le type « ${t.nom} » ?')) {
      await types.supprimer(t.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageOdv(
      titre: 'Types de bouteille',
      sousTitre: 'Rouge, blanc, bière, spiritueux… à votre façon',
      bouton: BoutonAjout(
        libelle: 'Ajouter un type',
        onPressed: () => editerTypeBouteille(context, types),
      ),
      corps: ListenableBuilder(
        listenable: Listenable.merge([types, cave]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            for (final t in types.elements)
              CarteLigne(
                key: Key('type-${t.id}'),
                leading: _Pastille(couleur: t.color),
                title: Text(t.nom),
                subtitle: Text(_resume(cave.nombreDeType(t.id))),
                onTap: () => editerTypeBouteille(context, types, type: t),
                actions: [
                  IconButton(
                    tooltip: 'Modifier',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        editerTypeBouteille(context, types, type: t),
                  ),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _supprimer(context, t),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _resume(int n) =>
      n == 0 ? 'Aucune bouteille' : '$n bouteille${n > 1 ? 's' : ''}';
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.couleur, this.taille = 28});

  final Color couleur;
  final double taille;

  @override
  Widget build(BuildContext context) => Container(
    width: taille,
    height: taille,
    decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
    child: Icon(Icons.wine_bar, size: taille * 0.6, color: Colors.white),
  );
}

/// Fenêtre de création ([type] == null) ou de modification d'un type.
Future<void> editerTypeBouteille(
  BuildContext context,
  TypesBouteilleController types, {
  TypeBouteille? type,
}) => showDialog<void>(
  context: context,
  builder: (_) => _DialogueType(types: types, type: type),
);

class _DialogueType extends StatefulWidget {
  const _DialogueType({required this.types, this.type});

  final TypesBouteilleController types;
  final TypeBouteille? type;

  @override
  State<_DialogueType> createState() => _DialogueTypeState();
}

class _DialogueTypeState extends State<_DialogueType> {
  late final _nom = TextEditingController(text: widget.type?.nom);
  late int _couleur = widget.type?.couleur ?? TypeBouteille.palette.first;
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final nom = _nom.text.trim();
    if (nom.isEmpty) {
      setState(() => _erreur = 'Donnez un nom');
      return;
    }
    final existant = widget.type;
    if (existant == null) {
      await widget.types.creer(nom, _couleur);
    } else {
      await widget.types.enregistrer(
        TypeBouteille(id: existant.id, nom: nom, couleur: _couleur),
      );
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.type == null ? 'Nouveau type' : 'Modifier le type'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('champ-nom-type'),
              controller: _nom,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nom',
                hintText: 'Bière, whisky, cidre…',
                errorText: _erreur,
              ),
              onSubmitted: (_) => _valider(),
            ),
            const SizedBox(height: 16),
            const Text('Couleur'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in TypeBouteille.palette)
                  InkWell(
                    key: Key('couleur-$c'),
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _couleur = c),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == _couleur
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _Pastille(couleur: Color(c), taille: 30),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('valider-type'),
          onPressed: _valider,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
