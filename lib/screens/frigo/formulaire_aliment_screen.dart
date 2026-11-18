import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/aliment.dart';
import '../../models/lieu.dart';
import '../../state/frigo_controller.dart';
import '../../state/lieux_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/lieux.dart';
import '../../widgets/page.dart';

/// Ajout (aliment == null) ou modification d'un aliment du frigo.
class FormulaireAlimentScreen extends StatefulWidget {
  const FormulaireAlimentScreen({
    super.key,
    required this.controller,
    required this.lieux,
    this.aliment,
    this.lieuParDefaut,
  });

  final FrigoController controller;
  final LieuxController lieux;
  final Aliment? aliment;

  /// Emplacement proposé pour un nouvel aliment (filtre de la liste).
  final String? lieuParDefaut;

  @override
  State<FormulaireAlimentScreen> createState() =>
      _FormulaireAlimentScreenState();
}

class _FormulaireAlimentScreenState extends State<FormulaireAlimentScreen> {
  final _form = GlobalKey<FormState>();
  late final Aliment? _a = widget.aliment;
  late final _nom = TextEditingController(text: _a?.nom);
  late final _categorie = TextEditingController(text: _a?.categorie);
  late final _quantite = TextEditingController(text: '${_a?.quantite ?? 1}');
  late final _contenance = TextEditingController(text: _a?.contenance);
  late final _notes = TextEditingController(text: _a?.notes);
  late DateTime? _peremption = _a?.datePeremption;
  late String? _lieu = _a != null ? _a.lieuId : widget.lieuParDefaut;

  bool get _modification => _a != null;

  @override
  void dispose() {
    for (final c in [_nom, _categorie, _quantite, _contenance, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final aujourdhui = widget.controller.aujourdhui;
    final choisie = await showDatePicker(
      context: context,
      initialDate: _peremption ?? aujourdhui,
      firstDate: DateTime(aujourdhui.year - 2),
      lastDate: DateTime(aujourdhui.year + 10),
      helpText: 'Date de péremption',
    );
    if (choisie != null) {
      setState(() => _peremption = choisie);
    }
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    await widget.controller.enregistrer(
      Aliment(
        id: _a?.id ?? const Uuid().v4(),
        nom: _nom.text.trim(),
        categorie: texteOuNull(_categorie.text),
        quantite: entierOuNull(_quantite.text) ?? 1,
        contenance: texteOuNull(_contenance.text),
        datePeremption: _peremption,
        dateAjout: _a?.dateAjout ?? widget.controller.aujourdhui,
        lieuId: _lieu,
        notes: _notes.text.trim(),
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _supprimer() async {
    if (!await confirmer(context, 'Supprimer « ${_a!.nom} » du frigo ?')) {
      return;
    }
    await widget.controller.supprimer(_a.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const espace = SizedBox(height: 18);
    const ecart = SizedBox(width: 12);
    final date = _peremption;
    return Scaffold(
      appBar: AppBar(
        title: Text(_modification ? 'Modifier l\'aliment' : 'Nouvel aliment'),
        actions: [
          if (_modification)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: _supprimer,
            ),
        ],
      ),
      bottomNavigationBar: BarreEnregistrer(
        libelle: 'Enregistrer l\'aliment',
        onPressed: _enregistrer,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: margesCentrees(context),
          children: [
            TextFormField(
              key: const Key('champ-nom-aliment'),
              controller: _nom,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nom *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Le nom est obligatoire'
                  : null,
            ),
            espace,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('champ-quantite-aliment'),
                    controller: _quantite,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantité'),
                    validator: (v) {
                      final n = entierOuNull(v ?? '');
                      return (n == null || n < 0)
                          ? 'Nombre positif attendu'
                          : null;
                    },
                  ),
                ),
                ecart,
                Expanded(
                  child: TextFormField(
                    key: const Key('champ-contenance'),
                    controller: _contenance,
                    decoration: const InputDecoration(
                      labelText: 'Contenance',
                      hintText: '500 g, 1 L…',
                    ),
                  ),
                ),
              ],
            ),
            espace,
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date de péremption',
                prefixIcon: const Icon(Icons.event_outlined),
                suffixIcon: date == null
                    ? null
                    : IconButton(
                        tooltip: 'Enlever la date',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _peremption = null),
                      ),
              ),
              child: InkWell(
                key: const Key('champ-peremption'),
                onTap: _choisirDate,
                child: Text(
                  date == null ? 'Choisir une date' : formaterDate(date),
                ),
              ),
            ),
            espace,
            TextFormField(
              controller: _categorie,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                hintText: 'Laitage, viande, légumes…',
              ),
            ),
            espace,
            ChampLieu(
              key: const Key('champ-lieu'),
              type: TypeLieu.frigo,
              lieux: widget.lieux,
              valeur: _lieu,
              libelle: 'Rangé où ?',
              onChanged: (v) => setState(() => _lieu = v),
            ),
            espace,
            TextFormField(
              controller: _notes,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
