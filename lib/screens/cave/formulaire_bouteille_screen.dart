import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/bouteille.dart';
import '../../state/cave_controller.dart';
import '../../widgets/communs.dart';

/// Ajout (bouteille == null) ou modification d'un vin de la cave.
class FormulaireBouteilleScreen extends StatefulWidget {
  const FormulaireBouteilleScreen({
    super.key,
    required this.controller,
    this.bouteille,
  });

  final CaveController controller;
  final Bouteille? bouteille;

  @override
  State<FormulaireBouteilleScreen> createState() =>
      _FormulaireBouteilleScreenState();
}

class _FormulaireBouteilleScreenState extends State<FormulaireBouteilleScreen> {
  final _form = GlobalKey<FormState>();
  late final Bouteille? _b = widget.bouteille;
  late final _nom = TextEditingController(text: _b?.nom);
  late final _producteur = TextEditingController(text: _b?.producteur);
  late final _appellation = TextEditingController(text: _b?.appellation);
  late final _region = TextEditingController(text: _b?.region);
  late final _millesime = TextEditingController(
    text: _b?.millesime?.toString(),
  );
  late final _aBoireAvant = TextEditingController(
    text: _b?.aBoireAvant?.toString(),
  );
  late final _quantite = TextEditingController(text: '1');
  late final _zone = TextEditingController(text: _b?.emplacement.zone);
  late final _rangee = TextEditingController(text: _b?.emplacement.rangee);
  late final _colonne = TextEditingController(text: _b?.emplacement.colonne);
  late final _notes = TextEditingController(text: _b?.notes);
  late TypeVin _type = _b?.type ?? TypeVin.rouge;

  bool get _modification => _b != null;

  List<TextEditingController> get _champs => [
    _nom,
    _producteur,
    _appellation,
    _region,
    _millesime,
    _aBoireAvant,
    _quantite,
    _zone,
    _rangee,
    _colonne,
    _notes,
  ];

  @override
  void dispose() {
    for (final c in _champs) {
      c.dispose();
    }
    super.dispose();
  }

  String? _annee(String? v) =>
      (v != null && v.trim().isNotEmpty && entierOuNull(v) == null)
      ? 'Année attendue'
      : null;

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    var bouteille = Bouteille(
      id: _b?.id ?? const Uuid().v4(),
      nom: _nom.text.trim(),
      type: _type,
      producteur: texteOuNull(_producteur.text),
      appellation: texteOuNull(_appellation.text),
      region: texteOuNull(_region.text),
      millesime: entierOuNull(_millesime.text),
      aBoireAvant: entierOuNull(_aBoireAvant.text),
      emplacement: Emplacement(
        zone: _zone.text.trim(),
        rangee: texteOuNull(_rangee.text),
        colonne: texteOuNull(_colonne.text),
      ),
      notes: _notes.text.trim(),
      // En modification, le stock ne change que par les boutons + / -.
      quantite: _b?.quantite ?? 0,
      mouvements: _b?.mouvements ?? const [],
    );
    final initiale = entierOuNull(_quantite.text) ?? 0;
    if (!_modification && initiale > 0) {
      bouteille = bouteille.ajouter(initiale, commentaire: 'Entrée en cave');
    }
    await widget.controller.enregistrer(bouteille);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _supprimer() async {
    if (!await confirmer(context, 'Supprimer « ${_b!.nom} » de la cave ?')) {
      return;
    }
    await widget.controller.supprimer(_b.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const espace = SizedBox(height: 12);
    const ecart = SizedBox(width: 12);
    final titres = Theme.of(context).textTheme.titleSmall;
    final b = _b;
    return Scaffold(
      appBar: AppBar(
        title: Text(_modification ? 'Modifier le vin' : 'Nouveau vin'),
        actions: [
          if (_modification)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: _supprimer,
            ),
          IconButton(
            tooltip: 'Enregistrer',
            icon: const Icon(Icons.check),
            onPressed: _enregistrer,
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('champ-nom'),
              controller: _nom,
              decoration: const InputDecoration(labelText: 'Nom du vin *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Le nom est obligatoire'
                  : null,
            ),
            espace,
            DropdownButtonFormField<TypeVin>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final t in TypeVin.values)
                  DropdownMenuItem(value: t, child: Text(t.libelle)),
              ],
              onChanged: (t) => setState(() => _type = t!),
            ),
            espace,
            TextFormField(
              controller: _producteur,
              decoration: const InputDecoration(
                labelText: 'Producteur / domaine',
              ),
            ),
            espace,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _appellation,
                    decoration: const InputDecoration(labelText: 'Appellation'),
                  ),
                ),
                ecart,
                Expanded(
                  child: TextFormField(
                    controller: _region,
                    decoration: const InputDecoration(labelText: 'Région'),
                  ),
                ),
              ],
            ),
            espace,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('champ-millesime'),
                    controller: _millesime,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Millésime'),
                    validator: _annee,
                  ),
                ),
                ecart,
                Expanded(
                  child: TextFormField(
                    controller: _aBoireAvant,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'À boire avant',
                    ),
                    validator: _annee,
                  ),
                ),
              ],
            ),
            if (!_modification) ...[
              espace,
              TextFormField(
                key: const Key('champ-quantite'),
                controller: _quantite,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre de bouteilles',
                ),
                validator: (v) {
                  final n = entierOuNull(v ?? '');
                  return (n == null || n < 0) ? 'Nombre positif attendu' : null;
                },
              ),
            ],
            const SizedBox(height: 24),
            Text('Emplacement', style: titres),
            espace,
            TextFormField(
              key: const Key('champ-zone'),
              controller: _zone,
              decoration: const InputDecoration(
                labelText: 'Zone *',
                hintText: 'Cave, casier du fond, armoire…',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Indiquez où est rangé le vin'
                  : null,
            ),
            espace,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('champ-rangee'),
                    controller: _rangee,
                    decoration: const InputDecoration(labelText: 'Rangée'),
                  ),
                ),
                ecart,
                Expanded(
                  child: TextFormField(
                    key: const Key('champ-colonne'),
                    controller: _colonne,
                    decoration: const InputDecoration(labelText: 'Colonne'),
                  ),
                ),
              ],
            ),
            espace,
            TextFormField(
              controller: _notes,
              minLines: 3,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Notes de dégustation',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (b != null && b.mouvements.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Historique (${b.quantite} en stock)', style: titres),
              for (final m in b.mouvements.reversed)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    m.quantite > 0 ? Icons.call_received : Icons.call_made,
                  ),
                  title: Text(
                    '${m.quantite > 0 ? '+' : ''}${m.quantite} · '
                    '${formaterDate(m.date)}',
                  ),
                  subtitle: m.commentaire == null ? null : Text(m.commentaire!),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
