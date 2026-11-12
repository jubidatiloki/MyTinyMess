import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/livre.dart';
import '../../state/bibliotheque_controller.dart';
import '../../widgets/communs.dart';

/// Ajout (livre == null) ou modification d'un livre.
class FormulaireLivreScreen extends StatefulWidget {
  const FormulaireLivreScreen({
    super.key,
    required this.controller,
    this.livre,
  });

  final BibliothequeController controller;
  final Livre? livre;

  @override
  State<FormulaireLivreScreen> createState() => _FormulaireLivreScreenState();
}

class _FormulaireLivreScreenState extends State<FormulaireLivreScreen> {
  final _form = GlobalKey<FormState>();
  late final _titre = TextEditingController(text: widget.livre?.titre);
  late final _auteur = TextEditingController(text: widget.livre?.auteur);
  late final _annee = TextEditingController(
    text: widget.livre?.annee?.toString(),
  );
  late final _isbn = TextEditingController(text: widget.livre?.isbn);
  late final _genre = TextEditingController(text: widget.livre?.genre);
  late final _personne = TextEditingController(text: widget.livre?.personne);
  late final _notes = TextEditingController(text: widget.livre?.notes);
  late StatutLecture _statut = widget.livre?.statut ?? StatutLecture.aLire;
  late Possession _possession = widget.livre?.possession ?? Possession.possede;
  late int? _note = widget.livre?.note;

  bool get _modification => widget.livre != null;

  @override
  void dispose() {
    for (final c in [
      _titre,
      _auteur,
      _annee,
      _isbn,
      _genre,
      _personne,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final ancien = widget.livre;
    final chezMoi = _possession == Possession.possede;
    // On garde la date du prêt si le prêt ne change pas.
    final memePret =
        ancien != null &&
        ancien.possession == _possession &&
        ancien.personne == texteOuNull(_personne.text);
    final livre = Livre(
      id: ancien?.id ?? const Uuid().v4(),
      titre: _titre.text.trim(),
      auteur: _auteur.text.trim(),
      annee: entierOuNull(_annee.text),
      isbn: texteOuNull(_isbn.text),
      genre: texteOuNull(_genre.text),
      statut: _statut,
      note: _note,
      notes: _notes.text.trim(),
      possession: _possession,
      personne: chezMoi ? null : texteOuNull(_personne.text),
      datePret: chezMoi
          ? null
          : (memePret ? ancien.datePret : null) ?? DateTime.now(),
    );
    await widget.controller.enregistrer(livre);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _supprimer() async {
    if (!await confirmer(context, 'Supprimer « ${widget.livre!.titre} » ?')) {
      return;
    }
    await widget.controller.supprimer(widget.livre!.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const espace = SizedBox(height: 12);
    final datePret = widget.livre?.datePret;
    return Scaffold(
      appBar: AppBar(
        title: Text(_modification ? 'Modifier le livre' : 'Nouveau livre'),
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
              key: const Key('champ-titre'),
              controller: _titre,
              decoration: const InputDecoration(labelText: 'Titre *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Le titre est obligatoire'
                  : null,
            ),
            espace,
            TextFormField(
              key: const Key('champ-auteur'),
              controller: _auteur,
              decoration: const InputDecoration(labelText: 'Auteur'),
            ),
            espace,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _annee,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Année'),
                    validator: (v) =>
                        (v != null &&
                            v.trim().isNotEmpty &&
                            entierOuNull(v) == null)
                        ? 'Nombre attendu'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _genre,
                    decoration: const InputDecoration(labelText: 'Genre'),
                  ),
                ),
              ],
            ),
            espace,
            TextFormField(
              controller: _isbn,
              decoration: const InputDecoration(labelText: 'ISBN'),
            ),
            espace,
            DropdownButtonFormField<StatutLecture>(
              initialValue: _statut,
              decoration: const InputDecoration(labelText: 'Lecture'),
              items: [
                for (final s in StatutLecture.values)
                  DropdownMenuItem(value: s, child: Text(s.libelle)),
              ],
              onChanged: (s) => setState(() => _statut = s!),
            ),
            espace,
            Text('Ma note', style: Theme.of(context).textTheme.labelLarge),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i sur 5',
                    icon: Icon(
                      (_note ?? 0) >= i ? Icons.star : Icons.star_border,
                    ),
                    // Retoucher la même étoile enlève la note.
                    onPressed: () =>
                        setState(() => _note = _note == i ? null : i),
                  ),
              ],
            ),
            espace,
            DropdownButtonFormField<Possession>(
              key: const Key('champ-possession'),
              initialValue: _possession,
              decoration: const InputDecoration(labelText: 'Où est le livre ?'),
              items: [
                for (final p in Possession.values)
                  DropdownMenuItem(value: p, child: Text(p.libelle)),
              ],
              onChanged: (p) => setState(() => _possession = p!),
            ),
            if (_possession != Possession.possede) ...[
              espace,
              TextFormField(
                key: const Key('champ-personne'),
                controller: _personne,
                decoration: InputDecoration(
                  labelText: _possession == Possession.prete
                      ? 'Prêté à *'
                      : 'Emprunté à *',
                  helperText:
                      datePret != null &&
                          _possession == widget.livre?.possession
                      ? 'Depuis le ${formaterDate(datePret)}'
                      : null,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Indiquez la personne'
                    : null,
              ),
            ],
            espace,
            TextFormField(
              key: const Key('champ-notes'),
              controller: _notes,
              minLines: 3,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
