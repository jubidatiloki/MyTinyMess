import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/recette.dart';
import '../../state/recettes_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';

/// Ajout ([recette] == null) ou modification d'une recette personnelle.
class FormulaireRecetteScreen extends StatefulWidget {
  const FormulaireRecetteScreen({
    super.key,
    required this.recettes,
    this.recette,
  });

  final RecettesController recettes;
  final Recette? recette;

  @override
  State<FormulaireRecetteScreen> createState() =>
      _FormulaireRecetteScreenState();
}

class _FormulaireRecetteScreenState extends State<FormulaireRecetteScreen> {
  final _form = GlobalKey<FormState>();
  late final Recette? _r = widget.recette;
  late final _nom = TextEditingController(text: _r?.nom);
  late final _minutes = TextEditingController(text: _r?.minutes?.toString());
  late final _personnes = TextEditingController(
    text: _r?.personnes?.toString(),
  );
  late final _ingredients = TextEditingController(
    text: _r?.ingredients.map((i) => i.libelle).join('\n'),
  );
  late final _etapes = TextEditingController(text: _r?.etapes);
  late final Set<StyleRecette> _styles = {...?_r?.styles};

  @override
  void dispose() {
    for (final c in [_nom, _minutes, _personnes, _ingredients, _etapes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    await widget.recettes.enregistrer(
      Recette(
        id: _r?.id ?? const Uuid().v4(),
        nom: _nom.text.trim(),
        styles: _styles,
        ingredients: [
          for (final ligne in _ingredients.text.split('\n'))
            if (ligne.trim().isNotEmpty) Ingredient.depuisLigne(ligne),
        ],
        etapes: _etapes.text.trim(),
        minutes: entierOuNull(_minutes.text),
        personnes: entierOuNull(_personnes.text),
        source: SourceRecette.perso,
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const espace = SizedBox(height: 18);
    return Scaffold(
      appBar: AppBar(
        title: Text(_r == null ? 'Nouvelle recette' : 'Modifier la recette'),
      ),
      bottomNavigationBar: BarreEnregistrer(
        libelle: 'Enregistrer la recette',
        onPressed: _enregistrer,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: margesCentrees(context),
          children: [
            TextFormField(
              key: const Key('champ-nom-recette'),
              controller: _nom,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nom *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Le nom est obligatoire'
                  : null,
            ),
            espace,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in StyleRecette.values)
                  FilterChip(
                    label: Text(s.libelle),
                    selected: _styles.contains(s),
                    onSelected: (v) =>
                        setState(() => v ? _styles.add(s) : _styles.remove(s)),
                  ),
              ],
            ),
            espace,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minutes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Minutes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _personnes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Personnes'),
                  ),
                ),
              ],
            ),
            espace,
            TextFormField(
              key: const Key('champ-ingredients'),
              controller: _ingredients,
              minLines: 4,
              maxLines: 15,
              decoration: const InputDecoration(
                labelText: 'Ingrédients (un par ligne)',
                hintText: '200 g de farine\n3 œufs\n25 cl de lait',
                alignLabelWithHint: true,
              ),
            ),
            espace,
            TextFormField(
              controller: _etapes,
              minLines: 4,
              maxLines: 20,
              decoration: const InputDecoration(
                labelText: 'Préparation (une étape par ligne)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
