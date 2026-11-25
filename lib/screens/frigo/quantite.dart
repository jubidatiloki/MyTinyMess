import 'package:flutter/material.dart';

import '../../models/aliment.dart';
import '../../models/unite.dart';
import '../../widgets/communs.dart';

/// Demande la nouvelle quantité d'un aliment (null = annulé).
Future<int?> demanderQuantite(BuildContext context, Aliment aliment) =>
    showDialog<int>(
      context: context,
      builder: (_) => _FenetreQuantite(aliment: aliment),
    );

class _FenetreQuantite extends StatefulWidget {
  const _FenetreQuantite({required this.aliment});

  final Aliment aliment;

  @override
  State<_FenetreQuantite> createState() => _FenetreQuantiteState();
}

class _FenetreQuantiteState extends State<_FenetreQuantite> {
  late final _champ = TextEditingController(text: '${widget.aliment.quantite}');
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  void _decaler(int delta) {
    final n = (entierOuNull(_champ.text) ?? 0) + delta;
    setState(() => _champ.text = '${n < 0 ? 0 : n}');
  }

  void _valider() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, entierOuNull(_champ.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unite = widget.aliment.unite;
    final n = entierOuNull(_champ.text) ?? 0;
    return AlertDialog(
      title: Text(widget.aliment.nom),
      content: Form(
        key: _form,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Un de moins',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: n > 0 ? () => _decaler(-1) : null,
            ),
            Expanded(
              child: TextFormField(
                key: const Key('champ-nouvelle-quantite'),
                controller: _champ,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Il en reste',
                  helperText: unite == null ? null : accorderUnite(unite, n),
                  helperMaxLines: 3,
                  errorMaxLines: 3,
                ),
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _valider(),
                validator: (v) {
                  final n = entierOuNull(v ?? '');
                  return n == null || n < 0 ? 'Nombre positif attendu' : null;
                },
              ),
            ),
            IconButton(
              tooltip: 'Un de plus',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _decaler(1),
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
          key: const Key('valider-quantite'),
          onPressed: _valider,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
