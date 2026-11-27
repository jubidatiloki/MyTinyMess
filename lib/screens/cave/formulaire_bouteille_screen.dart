import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/lieu.dart';
import '../../data/liens.dart';
import '../../data/partage_adresse.dart';
import '../../models/bouteille.dart';
import '../../state/annuaire_controller.dart';
import '../../state/cave_controller.dart';
import '../../state/lieux_controller.dart';
import '../../state/types_bouteille_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/lieux.dart';
import '../../widgets/page.dart';
import '../annuaire/choix_adresse.dart';
import '../frigo/quantite.dart';

/// Ajout (bouteille == null) ou modification d'une bouteille de la cave.
class FormulaireBouteilleScreen extends StatefulWidget {
  const FormulaireBouteilleScreen({
    super.key,
    required this.controller,
    required this.lieux,
    required this.types,
    this.bouteille,
    this.lieuParDefaut,
    this.annuaire,
    this.ouvrirLien,
    this.partager,
  });

  final CaveController controller;
  final LieuxController lieux;
  final TypesBouteilleController types;
  final Bouteille? bouteille;

  /// Annuaire, pour dire d'où vient la bouteille (sinon, pas de champ).
  final AnnuaireController? annuaire;
  final OuvrirLien? ouvrirLien;
  final Partager? partager;

  /// Emplacement proposé pour une nouvelle bouteille (filtre de la liste).
  final String? lieuParDefaut;

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
  late String? _lieu = _b != null
      ? _b.emplacement.lieuId
      : widget.lieuParDefaut ?? widget.lieux.seulLieu(TypeLieu.cave);
  late final _rangee = TextEditingController(text: _b?.emplacement.rangee);
  late final _colonne = TextEditingController(text: _b?.emplacement.colonne);
  late final _notes = TextEditingController(text: _b?.notes);
  late int? _niveau = _b?.niveau;
  late String? _adresse = _b?.adresseId;
  late String? _typeId =
      _b?.typeId ??
      (widget.types.elements.isEmpty ? null : widget.types.elements.first.id);

  bool get _modification => _b != null;

  List<TextEditingController> get _champs => [
    _nom,
    _producteur,
    _appellation,
    _region,
    _millesime,
    _aBoireAvant,
    _quantite,
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
      typeId: _typeId ?? 'autre',
      producteur: texteOuNull(_producteur.text),
      appellation: texteOuNull(_appellation.text),
      region: texteOuNull(_region.text),
      millesime: entierOuNull(_millesime.text),
      aBoireAvant: entierOuNull(_aBoireAvant.text),
      emplacement: Emplacement(
        lieuId: _lieu,
        rangee: texteOuNull(_rangee.text),
        colonne: texteOuNull(_colonne.text),
      ),
      notes: _notes.text.trim(),
      niveau: _niveau,
      adresseId: _adresse,
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
    const espace = SizedBox(height: 18);
    const ecart = SizedBox(width: 12);
    final titres = Theme.of(context).textTheme.titleSmall;
    final b = _b;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _modification ? 'Modifier la bouteille' : 'Nouvelle bouteille',
        ),
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
        libelle: 'Enregistrer la bouteille',
        onPressed: _enregistrer,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: margesCentrees(context),
          children: [
            TextFormField(
              key: const Key('champ-nom'),
              controller: _nom,
              decoration: const InputDecoration(labelText: 'Nom *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Le nom est obligatoire'
                  : null,
            ),
            espace,
            DropdownButtonFormField<String>(
              key: const Key('champ-type'),
              isExpanded: true,
              // Type supprimé entre-temps : on laisse choisir.
              initialValue: widget.types.parId(_typeId ?? '') == null
                  ? null
                  : _typeId,
              decoration: const InputDecoration(labelText: 'Type'),
              hint: const Text('Choisir un type'),
              items: [
                for (final t in widget.types.elements)
                  DropdownMenuItem(
                    value: t.id,
                    child: Row(
                      children: [
                        Icon(Icons.wine_bar, size: 18, color: t.color),
                        const SizedBox(width: 8),
                        Flexible(child: TexteAjuste(t.nom)),
                      ],
                    ),
                  ),
              ],
              onChanged: (t) => setState(() => _typeId = t),
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
            if (_modification && b!.enStock) ...[
              espace,
              CurseurNiveau(
                niveau: _niveau,
                onChanged: (v) => setState(() => _niveau = v),
              ),
            ],
            if (widget.annuaire != null) ...[
              espace,
              ChampAdresse(
                annuaire: widget.annuaire!,
                valeur: _adresse,
                ouvrirLien: widget.ouvrirLien,
                partager: widget.partager,
                onChanged: (v) => setState(() => _adresse = v),
              ),
            ],
            const SizedBox(height: 24),
            Text('Emplacement', style: titres),
            espace,
            ChampLieu(
              key: const Key('champ-lieu'),
              type: TypeLieu.cave,
              lieux: widget.lieux,
              valeur: _lieu,
              libelle: 'Lieu',
              onChanged: (v) => setState(() => _lieu = v),
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
